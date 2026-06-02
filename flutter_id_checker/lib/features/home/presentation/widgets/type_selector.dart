import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:id_checker/constants.dart';
import 'package:id_checker/features/home/domain/entities/image_entity.dart';
import 'package:id_checker/features/home/presentation/controller/picked_image/picked_image_cubit.dart';
import 'package:id_checker/features/home/presentation/widgets/type_button.dart';

class TypeSelector extends StatelessWidget {
  final ImageType currentType;

  const TypeSelector({super.key, required this.currentType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          TypeButton(
            label: '🪪 National ID',
            isSelected: currentType == ImageType.nationalId,
            color: kPrimaryColor,
            onTap: () {
              context.read<PickedImageCubit>().changeType(ImageType.nationalId);
            },
          ),

          Container(width: 1, height: 40, color: Colors.grey.shade300),

          TypeButton(
            label: '🚗 Driver license',
            isSelected: currentType == ImageType.driverLicense,
            color: kPrimaryColor,
            onTap: () {
              context.read<PickedImageCubit>().changeType(
                ImageType.driverLicense,
              );
            },
          ),
        ],
      ),
    );
  }
}
