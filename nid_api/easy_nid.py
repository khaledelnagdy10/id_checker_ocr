import re
import cv2
import numpy as np
import easyocr

DIGITS_AR = "٠١٢٣٤٥٦٧٨٩"
DIGITS_EN = "0123456789"
TRANS = str.maketrans(DIGITS_AR, DIGITS_EN)

_reader = None


def get_reader():
    global _reader
    if _reader is None:
        _reader = easyocr.Reader(["ar"], gpu=False)
    return _reader


def crop_nid_line(img):
    h, w = img.shape[:2]
    y1 = int(h * 0.72)
    y2 = int(h * 0.88)
    x1 = int(w * 0.30)
    x2 = int(w * 0.95)
    return img[y1:y2, x1:x2]


def preprocess_digits(roi):
    gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
    _, thr = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    if np.mean(thr) < 127:
        thr = cv2.bitwise_not(thr)
    return thr


def extract_14_digits(text):
    text = text.translate(TRANS)
    text = re.sub(r"[^0-9]", "", text)
    m = re.search(r"[23]\d{13}", text)
    return m.group(0) if m else None


def extract_nid_from_path(image_path: str):
    img = cv2.imread(image_path)
    if img is None:
        return None, ""
    roi = crop_nid_line(img)
    proc = preprocess_digits(roi)
    reader = get_reader()
    results = reader.readtext(proc, detail=0, allowlist="٠١٢٣٤٥٦٧٨٩0123456789")
    raw = " ".join(results)
    nid = extract_14_digits(raw)
    return nid, raw
