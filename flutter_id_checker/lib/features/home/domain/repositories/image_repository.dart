import 'dart:io';
import 'package:id_checker/features/home/domain/entities/image_entity.dart';

abstract class ImageRepository {
  Future<File?> scanDocument({required bool fromGallery});

  Future<ImageEntity?> analyzeDocument(File file);
}
