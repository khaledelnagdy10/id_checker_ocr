import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:id_checker/features/home/domain/entities/image_entity.dart';
import 'package:id_checker/features/home/domain/repositories/image_repository.dart';
import 'package:id_checker/features/home/presentation/controller/picked_image/picked_image_state.dart';

class PickedImageCubit extends Cubit<PickedImageState> {
  final ImageRepository repository;

  PickedImageCubit(this.repository) : super(PickedImageInitial());

  Future<void> scan({required bool fromGallery}) async {
    emit(PickedImageLoading());

    final file = await repository.scanDocument(fromGallery: fromGallery);

    if (file == null) {
      emit(PickedImageFailure('لم يتم اختيار صورة'));
      return;
    }

    final document = await repository.analyzeDocument(file);

    if (document == null) {
      emit(PickedImageFailure('فشل تحليل الوثيقة'));
      return;
    }

    emit(PickedImageSuccess(document));
  }

  void changeType(ImageType newType) {
    final current = state;

    if (current is PickedImageSuccess) {
      final updated = current.document.copyWith(type: newType);
      emit(PickedImageSuccess(updated));
    }
  }
}
