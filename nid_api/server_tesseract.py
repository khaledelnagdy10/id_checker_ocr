import os
import re
import shutil
import cv2
import numpy as np
import pytesseract

import easyocr
from fastapi import FastAPI, UploadFile, File

from PIL import Image, ImageOps

app = FastAPI()

pytesseract.pytesseract.tesseract_cmd = "/opt/homebrew/bin/tesseract"
os.environ["TESSDATA_PREFIX"] = "/opt/homebrew/share/tessdata"

DIGITS_AR = "٠١٢٣٤٥٦٧٨٩"
DIGITS_EN = "0123456789"
TRANS = str.maketrans(DIGITS_AR, DIGITS_EN)

_reader = None


def get_reader():
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(["ar"], gpu=False)
    return _reader


def order_points(pts):
    rect = np.zeros((4, 2), dtype="float32")
    s = pts.sum(axis=1)
    rect[0] = pts[np.argmin(s)]  # top-left
    rect[2] = pts[np.argmax(s)]  # bottom-right
    diff = np.diff(pts, axis=1)
    rect[1] = pts[np.argmin(diff)]  # top-right
    rect[3] = pts[np.argmax(diff)]  # bottom-left
    return rect


def four_point_transform(image, pts):
    rect = order_points(pts)
    tl, tr, br, bl = rect

    widthA = np.linalg.norm(br - bl)
    widthB = np.linalg.norm(tr - tl)
    maxWidth = int(max(widthA, widthB))

    heightA = np.linalg.norm(tr - br)
    heightB = np.linalg.norm(tl - bl)
    maxHeight = int(max(heightA, heightB))

    dst = np.array(
        [[0, 0], [maxWidth - 1, 0], [maxWidth - 1, maxHeight - 1], [0, maxHeight - 1]],
        dtype="float32",
    )

    M = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))
    return warped


def crop_id_card_opencv(img):
    h0, w0 = img.shape[:2]

    scale = 900 / max(h0, w0)
    small = cv2.resize(img, (int(w0 * scale), int(h0 * scale)))

    gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (5, 5), 0)

    edges = cv2.Canny(gray, 50, 150)
    edges = cv2.dilate(edges, np.ones((3, 3), np.uint8), iterations=1)

    cnts, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not cnts:
        return img

    cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:10]

    card = None
    for c in cnts:
        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)

        if len(approx) == 4:
            area = cv2.contourArea(approx)
            if area < 0.15 * (small.shape[0] * small.shape[1]):
                continue
            card = approx.reshape(4, 2)
            break

    if card is None:
        return img

    card = card / scale

    warped = four_point_transform(img, card.astype("float32"))

    # اجعل البطاقة في وضع عمودي
    if warped.shape[0] < warped.shape[1]:
        warped = cv2.rotate(warped, cv2.ROTATE_90_CLOCKWISE)

    return warped


def load_and_crop_id(path: str):
    im = Image.open(path)
    im = ImageOps.exif_transpose(im)
    img = cv2.cvtColor(np.array(im), cv2.COLOR_RGB2BGR)
    img = crop_id_card_opencv(img)
    return img


def crop_name_zone(img):
    h, w = img.shape[:2]
    y1 = int(h * 0.28)
    y2 = int(h * 0.50)
    x1 = int(w * 0.25)
    x2 = int(w * 0.98)
    return img[y1:y2, x1:x2]


def crop_nid_zone(img):
    h, w = img.shape[:2]
    y1 = int(h * 0.70)
    y2 = int(h * 0.92)
    x1 = int(w * 0.20)
    x2 = int(w * 0.98)
    return img[y1:y2, x1:x2]


def preprocess_digits(roi):
    gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)

    gray = cv2.GaussianBlur(gray, (3, 3), 0)

    thr = cv2.adaptiveThreshold(
        gray,
        255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        31,
        7,
    )

    if np.mean(thr) < 127:
        thr = cv2.bitwise_not(thr)

    thr = cv2.morphologyEx(thr, cv2.MORPH_OPEN, np.ones((2, 2), np.uint8), iterations=1)

    thr = cv2.resize(thr, None, fx=2.0, fy=2.0, interpolation=cv2.INTER_CUBIC)

    return thr


def extract_14_digits(text: str):
    text = text.translate(TRANS)
    text = re.sub(r"[^0-9]", "", text)

    m = re.search(r"[23]\d{13}", text)
    if m:
        return m.group(0)

    m = re.search(r"\d{14}", text)
    if m:
        return m.group(0)

    return None


def extract_nid(text: str):
    text = text.translate(TRANS)
    digits_only = re.sub(r"[^0-9]", "", text)

    m = re.search(r"[23]\d{13}", digits_only)
    if m:
        return m.group(0)

    m = re.search(r"\d{14}", digits_only)
    if m:
        return m.group(0)

    return None


def clean_name(text: str):
    blacklist = ["بطاقة", "تحقيق", "الشخصية", "جمهورية", "العربية"]
    lines = text.split("\n")
    filtered = []

    for line in lines:
        line = line.strip()
        if len(line) < 2:
            continue
        if any(word in line for word in blacklist):
            continue

        line = re.sub(r"[0-9٠-٩.<>،,\-_#]", "", line)
        line = line.replace("حل", "").replace("اليد", "السيد")
        line = re.sub(r"\s+", " ", line).strip()

        if len(line) > 2:
            filtered.append(line)

        if len(filtered) == 2:
            break

    return " ".join(filtered)


@app.post("/extract")
async def extract(file: UploadFile = File(...)):
    path = f"temp_{file.filename}"

    try:
        with open(path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        img = load_and_crop_id(path)
        if img is None:
            return {"error": "Cannot read image", "name": None, "nid": None}

        # Debug: البطاقة بعد القص
        cv2.imwrite("debug_card.jpg", img)

        # name by tesseract
        name_roi = crop_name_zone(img)
        cv2.imwrite("debug_name_crop.jpg", name_roi)

        name_config = r"--oem 3 --psm 6 -l ara"
        name_text = pytesseract.image_to_string(name_roi, config=name_config)
        name = clean_name(name_text)

        # nid zone
        nid_roi = crop_nid_zone(img)
        cv2.imwrite("debug_nid_crop.jpg", nid_roi)

        # easyocr first
        proc = preprocess_digits(nid_roi)
        cv2.imwrite("debug_nid_proc.jpg", proc)

        reader = get_reader()
        results = reader.readtext(proc, detail=0, allowlist="٠١٢٣٤٥٦٧٨٩0123456789")
        raw_easy = " ".join(results)
        nid = extract_14_digits(raw_easy)

        raw_nid_all = f"EASY: {raw_easy}"

        # fallback tesseract ara
        if not nid:
            nid_config_ara = r"--oem 3 --psm 7 -l ara"
            nid_text_ara = pytesseract.image_to_string(nid_roi, config=nid_config_ara)
            nid = extract_nid(nid_text_ara)
            raw_nid_all += f" | ARA: {nid_text_ara}"

        # fallback tesseract eng
        if not nid:
            nid_config_eng = r"--oem 3 --psm 7 -l eng"
            nid_text_eng = pytesseract.image_to_string(nid_roi, config=nid_config_eng)
            nid = extract_nid(nid_text_eng)
            raw_nid_all += f" | ENG: {nid_text_eng}"

        return {
            "name": name,
            "nid": nid,
            "raw_name": name_text,
            "raw_nid": raw_nid_all,
        }

    except Exception as e:
        return {"error": str(e), "name": None, "nid": None}

    finally:
        if os.path.exists(path):
            os.remove(path)


@app.get("/")
async def root():
    return {"message": "Egyptian ID OCR", "version": "6.0-auto-crop"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
