import 'dart:io';

import 'package:id_checker/core/utils/images_classifier.dart';
import 'package:id_checker/features/home/data/data_source/api_data_source.dart';
import 'package:id_checker/features/home/data/data_source/scanner_data_source.dart';
import 'package:id_checker/features/home/data/models/image_model.dart';
import 'package:id_checker/features/home/domain/entities/image_entity.dart';
import 'package:id_checker/features/home/domain/repositories/image_repository.dart';

class ImageRepositoryImpl implements ImageRepository {
  final ScannerDataSource scanner;
  final ApiDataSource api;
  final ImageClassifier classifier;

  ImageRepositoryImpl({
    required this.scanner,
    required this.api,
    required this.classifier,
  });

  @override
  Future<File?> scanDocument({required bool fromGallery}) {
    return scanner.scan(fromGallery: fromGallery);
  }

  @override
  Future<ImageEntity?> analyzeDocument(File file) async {
    final ImageModel? model = await api.extractData(file);

    if (model == null) return null;

    final type = classifier.classify(
      rawName: model.rawName,
      rawNid: model.rawNid,
    );

    return model.toEntity(imageFile: file, type: type);
  }
}
