import 'package:id_checker/features/home/domain/entities/image_entity.dart';

class ImageClassifier {
  ImageType classify({String? rawName, String? rawNid}) {
    String text = '${rawName ?? ''} ${rawNid ?? ''}'.toLowerCase();

    final driverKeywords = [
      'driving',
      'licence',
      'license',
      'رخصة',
      'قيادة',
      'سياقة',
      'مرور',
    ];

    final idKeywords = [
      'national id',
      'identity',
      'بطاقة تحقيق',
      'جمهورية مصر',
      'arab republic',
    ];

    int driverScore = driverKeywords
        .where((keyword) => text.contains(keyword))
        .length;

    int idScore = idKeywords.where((keyword) => text.contains(keyword)).length;

    print('🚗 Driver Score: $driverScore');
    print('🪪 ID Score: $idScore');

    if (driverScore > idScore && driverScore > 0) {
      return ImageType.driverLicense;
    }
    return ImageType.nationalId;
  }
}
