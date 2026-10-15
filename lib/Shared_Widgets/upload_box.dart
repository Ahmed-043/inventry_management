import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';

import '../files.dart';

class UploadBox extends StatefulWidget {
  final void Function(Uint8List? file)? onFileSelected;
  final Uint8List? image;
  final String? heroTag;
  const UploadBox({super.key, this.onFileSelected, this.image, this.heroTag});

  @override
  State<UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<UploadBox> {
  late Uint8List? selectedFile = widget.image;
  bool isDragging = false;
  bool isLoading = false;
  bool isHovered = false;
  bool isCompressing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTap() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      isHovered = false;
    });
    Uint8List? file;
    try {
      file = await imagePicker(compress: false);
      setState(() {
        isCompressing = true;
      });
      if (file == null) {
        setState(() {
          isLoading = false;
          isCompressing = false;
        });
        return;
      }
      file = await compute(compressImage, file);

      setState(() => selectedFile = file);
      widget.onFileSelected?.call(file);
    } catch (e) {
      debugPrint("Upload Box Tap error: ${e.toString()}");
      setState(() {
        isLoading = false;
        isCompressing = false;
      });
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isCompressing = false;
    });
  }

  void _onDrop(List<XFile> files) async {
    setState(() {
      isLoading = true;
      isCompressing = true;
    });
    if (files.isNotEmpty) {
      final file = await handleDrop(files.first.path);
      if (file != null) {
        setState(() => selectedFile = file);
        widget.onFileSelected?.call(file);
      }
    }
    setState(() {
      isLoading = false;
      isHovered = false;
      isCompressing = false;
    });
  }

  Widget _buildImageWidget() {
    final imageChild = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Image.memory(selectedFile!, fit: BoxFit.fitHeight),
    );

    if (widget.heroTag != null && widget.heroTag!.isNotEmpty && widget.heroTag != "null") {
      return Hero(
        tag: widget.heroTag!,
        child: imageChild,
      );
    }
    return imageChild;
  }

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: DropTarget(
        onDragDone: (details) => _onDrop(details.files),
        onDragEntered: (_) => setState(() => isDragging = true),
        onDragExited: (_) => setState(() => isDragging = false),
        child: DottedBorder(
          options: const RoundedRectDottedBorderOptions(
            dashPattern: [6, 3],
            strokeWidth: 1,
            radius: Radius.circular(12),
            color: Colors.grey,
          ),
          child: selectedFile == null
              ? SizedBox(
                  height: selectedFile != null ? null : double.infinity,
                  width: selectedFile != null ? null : double.infinity,
                  child: InkWell(
                    onTap: _onTap,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 4,
                          left: 8,
                          child: SizedBox(
                            height: 18,
                            child: Text(
                              "Image",
                              style: MyFont.bold(12, color: MyColors.blue),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              isLoading
                                  ? const CircularProgressIndicator(color: MyColors.darkBlue)
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 28,
                                      color: Colors.grey,
                                    ),
                              const SizedBox(height: 4),
                              isCompressing
                                  ? Text(
                                      "Compressing Image",
                                      textAlign: TextAlign.center,
                                      style: MyFont.bold(11, color: MyColors.blue),
                                    )
                                  : Column(
                                      children: [
                                        Text(
                                          "Drag & Drop Image Here",
                                          textAlign: TextAlign.center,
                                          style: MyFont.normal(
                                            11,
                                            color: MyColors.grey,
                                          ),
                                        ),
                                        Text(
                                          " or Click to Upload",
                                          textAlign: TextAlign.center,
                                          style: MyFont.bold(11, color: MyColors.blue),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedFile = null;
                          widget.onFileSelected?.call(null);
                        });
                      },
                      child: MouseRegion(
                        onEnter: (_) => setState(() => isHovered = true),
                        onExit: (_) => setState(() => isHovered = false),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildImageWidget(),
                            if (isLoading) const CircularProgressIndicator(),
                            if (isHovered && !isLoading)
                              Container(
                                height: double.infinity,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: MyColors.light.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: MyColors.error,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

Future<Uint8List?> handleDrop(String path) async {
  if (path.isNotEmpty) {
    return convertImageToBytes(path);
  }
  return null;
}
