import 'dart:io';

enum ImageType { nationalId, driverLicense }

class ImageEntity {
  final String? name;
  final String? nid;
  final ImageType type;
  final File imageFile;

  ImageEntity({
    this.name,
    this.nid,
    required this.type,
    required this.imageFile,
  });

  ImageEntity copyWith({ImageType? type}) {
    return ImageEntity(
      name: name,
      nid: nid,
      type: type ?? this.type,
      imageFile: imageFile,
    );
  }
}
