import 'package:id_checker/features/home/domain/entities/image_entity.dart';

abstract class PickedImageState {}

class PickedImageInitial extends PickedImageState {}

class PickedImageLoading extends PickedImageState {}

class PickedImageSuccess extends PickedImageState {
  final ImageEntity document;

  PickedImageSuccess(this.document);
}

class PickedImageFailure extends PickedImageState {
  final String message;

  PickedImageFailure(this.message);
}
