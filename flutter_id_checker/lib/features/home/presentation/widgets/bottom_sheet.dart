import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:id_checker/constants.dart';
import 'package:id_checker/features/home/presentation/controller/picked_image/picked_image_cubit.dart';
import 'custom_button.dart';

void showScanBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 15,
        children: [
          const Text(
            'Scan your Id',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          CustomButton(
            text: '📸 Open camera',
            color: Colors.black,
            textColor: Colors.white,
            onTap: () {
              Navigator.pop(context);
              context.read<PickedImageCubit>().scan(fromGallery: false);
            },
          ),

          CustomButton(
            text: '🖼️ Open gallery',
            color: kPrimaryColor,
            textColor: Colors.black,
            onTap: () {
              Navigator.pop(context);
              context.read<PickedImageCubit>().scan(fromGallery: true);
            },
          ),
        ],
      ),
    ),
  );
}
