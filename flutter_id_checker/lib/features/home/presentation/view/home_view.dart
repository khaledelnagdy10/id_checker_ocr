import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:id_checker/constants.dart';
import 'package:id_checker/core/data/send_data.dart';
import 'package:id_checker/features/home/domain/entities/image_entity.dart';
import 'package:id_checker/features/home/presentation/controller/picked_image/picked_image_cubit.dart';
import 'package:id_checker/features/home/presentation/controller/picked_image/picked_image_state.dart';
import 'package:id_checker/features/home/presentation/widgets/bottom_sheet.dart';
import 'package:id_checker/features/home/presentation/widgets/data_card.dart';
import 'package:id_checker/features/home/presentation/widgets/type_selector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          'ID checker',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: kPrimaryColor,
        centerTitle: true,
      ),
      body: BlocBuilder<PickedImageCubit, PickedImageState>(
        builder: (context, state) {
          if (state is PickedImageInitial) {
            return const Center(
              child: Text(
                'Please scan your ID',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          if (state is PickedImageLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            );
          }

          if (state is PickedImageFailure) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (state is PickedImageSuccess) {
            return _SuccessView(document: state.document);
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: BlocBuilder<PickedImageCubit, PickedImageState>(
        builder: (context, state) {
          if (state is PickedImageSuccess) {
            return const SizedBox();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: SizedBox(
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: () => showScanBottomSheet(context),
                backgroundColor: kPrimaryColor,
                label: const Text(
                  'Scan your ID',
                  style: TextStyle(color: Colors.white),
                ),
                icon: const Icon(Icons.document_scanner, color: Colors.white),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _SuccessView extends StatefulWidget {
  final ImageEntity document;

  const _SuccessView({super.key, required this.document});

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with TickerProviderStateMixin {
  bool isSaving = false;
  bool isSaved = false;
  bool isExiting = false;

  late AnimationController _entryController;
  late AnimationController _successController;
  late AnimationController _exitController;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _scaleSuccess;
  late Animation<double> _fadeOut;
  late Animation<Offset> _slideOut;

  @override
  void initState() {
    super.initState();

    // دخول الشاشة
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(_entryController);
    _slideIn = Tween(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_entryController);

    // نجاح الحفظ
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleSuccess = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    // خروج الشاشة
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(_exitController);
    _slideOut = Tween(
      begin: Offset.zero,
      end: const Offset(0, -0.2),
    ).animate(_exitController);

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _successController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> handleSave(ImageEntity document) async {
    setState(() => isSaving = true);

    try {
      await sendData(document);

      setState(() {
        isSaving = false;
        isSaved = true;
      });

      _successController.forward();

      await Future.delayed(const Duration(seconds: 2));

      // خروج أنيميشن
      setState(() => isExiting = true);
      await _exitController.forward();

      if (mounted) {
        context.read<PickedImageCubit>().emit(PickedImageInitial());
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error saving ❌")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;

    // شاشة النجاح
    if (isSaved) {
      return Center(
        child: ScaleTransition(
          scale: _scaleSuccess,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                "Saved Successfully",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // الحالة العادية + دخول + خروج
    return FadeTransition(
      opacity: isExiting ? _fadeOut : _fadeIn,
      child: SlideTransition(
        position: isExiting ? _slideOut : _slideIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TypeSelector(currentType: document.type),
              const SizedBox(height: 20),
              if (document.name != null)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: 1,
                  child: DataCard(image: document),
                ),
              const SizedBox(height: 20),
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0.9, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(document.imageFile, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              // زرار الحفظ
              GestureDetector(
                onTap: isSaving ? null : () => handleSave(document),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: isSaving ? 0.95 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Save to Google Sheet",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
