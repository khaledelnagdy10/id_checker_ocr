import 'dart:io';
import 'package:id_checker/features/home/domain/entities/image_entity.dart';

class ImageModel {
  final String? name;
  final String? nid;
  final String? rawName;
  final String? rawNid;

  ImageModel({this.name, this.nid, this.rawName, this.rawNid});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      name: json['name'],
      nid: json['nid'],
      rawName: json['raw_name'],
      rawNid: json['raw_nid'],
    );
  }

  ImageEntity toEntity({required File imageFile, required ImageType type}) {
    return ImageEntity(name: name, nid: nid, type: type, imageFile: imageFile);
  }
}
