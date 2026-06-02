import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:id_checker/core/utils/images_classifier.dart';
import 'package:id_checker/features/home/data/data_source/api_data_source.dart';
import 'package:id_checker/features/home/data/data_source/scanner_data_source.dart';
import 'package:id_checker/features/home/data/repositories/image_repo_imp.dart';
import 'package:id_checker/features/home/presentation/controller/picked_image/picked_image_cubit.dart';
import 'package:id_checker/features/home/presentation/view/home_view.dart';

void main() {
  final scannerDataSource = ScannerDataSource();
  final apiDataSource = ApiDataSource();

  final classifier = ImageClassifier();

  final repository = ImageRepositoryImpl(
    scanner: scannerDataSource,
    api: apiDataSource,
    classifier: classifier,
  );

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ImageRepositoryImpl repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PickedImageCubit(repository),

      child: MaterialApp(
        title: 'ID CHECKER',
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
