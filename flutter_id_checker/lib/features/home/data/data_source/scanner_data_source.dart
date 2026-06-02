import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class ScannerDataSource {
  Future<File?> scan({required bool fromGallery}) async {
    DocumentScanner? scanner;

    try {
      scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: {DocumentFormat.jpeg},
          mode: ScannerMode.base,
          pageLimit: 1,
          isGalleryImport: fromGallery,
        ),
      );

      final result = await scanner.scanDocument();

      if (result.images == null || result.images!.isEmpty) {
        return null;
      }

      return File(result.images!.first);
    } on PlatformException catch (e) {
      if (e.code == 'DocumentScanner') {
        print('⚠️ User cancelled scanning');
        return null;
      }

      print('❌ Scanner Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return null;
    } finally {
      scanner?.close();
    }
  }
}
