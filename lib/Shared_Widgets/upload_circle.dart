import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';
import 'dart:typed_data';

import '../files.dart';
import 'crop_image.dart';

class UploadCircle extends StatefulWidget {
  final void Function(Uint8List? file)? onFileSelected;
  final Uint8List? image;
  const UploadCircle({super.key, this.onFileSelected, this.image});

  @override
  State<UploadCircle> createState() => _UploadCircleState();
}

class _UploadCircleState extends State<UploadCircle> {
  late Uint8List? selectedFile = widget.image;
  bool isDragging = false;
  bool isLoading = false;
  bool isHovered = false;
  bool isCompressing = false;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

  }
  void _onTap() async {
    setState(() {
      isLoading = true;
      isCompressing = false;
    });

    try {
      Uint8List? file = await imagePicker(compress: false);
      if (file == null)
        {
          setState(() {
            isLoading = false;
            isCompressing = false;
          });
          return;
        }

      final adjusted = await showManualCropDialog(context, file);
      if (adjusted == null)
      {
        setState(() {
          isLoading = false;
          isCompressing = false;
        });
        return;
      }

      setState(()  {isCompressing = true; isHovered = false;});
      final compressed = await compressImage(adjusted);

      setState(() {
        selectedFile = compressed;
        isLoading = false;
        isCompressing = false;
      });

      widget.onFileSelected?.call(compressed);
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
        isCompressing = false;
      });
    }
  }


  void _onDrop(List<XFile> files) async {
    setState(() {
      isLoading = true;
    });
    if (files.isNotEmpty) {

      final file = await File(files.first.path).readAsBytes();
      final adjusted = await showManualCropDialog(context, file);
      if (adjusted == null)
      {
        setState(() {
          isLoading = false;
          isCompressing = false;
        });
        return;
      }

      setState(()  {isCompressing = true; isHovered = false;});
      final compressed = await compressImage(adjusted);
        selectedFile = compressed;
      widget.onFileSelected?.call(compressed);
    }
    setState(() {
      isLoading = false;
      isHovered = false;
      isCompressing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) => _onDrop(details.files),
      onDragEntered: (_) => setState(() => isDragging = true),
      onDragExited: (_) => setState(() => isDragging = false),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          dashPattern: [6, 3],
          strokeWidth: 2,
          radius: Radius.circular(999),
          color: Colors.grey,
          padding: EdgeInsets.all(4),
        ),
        child: selectedFile == null
            ? SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: InkWell(
            borderRadius : BorderRadius.all(Radius.circular(999)),
             onTap: _onTap,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 20,
                    child: Text(
                      "Image",
                      style: MyFont.bold(15, color: MyColors.blue),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isLoading
                          ? CircularProgressIndicator()
                          : Icon(
                        Icons.camera_alt_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      isCompressing ?  Text(
                        "Compressing Image",
                        textAlign: TextAlign.center,
                        style: MyFont.bold(14, color: MyColors.blue),
                      )
                          :Column(
                        children: [
                          Text(
                            "Drag & Drop Image Here",
                            textAlign: TextAlign.center,
                            style: MyFont.normal(
                              14,
                              color: MyColors.grey,
                            ),
                          ),
                          Text(
                            " or Click to Upload",
                            textAlign: TextAlign.center,
                            style: MyFont.bold(14, color: MyColors.blue),
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
              borderRadius : BorderRadius.all(Radius.circular(999)),
              onTap: (){
                setState(() {selectedFile = null;
                widget.onFileSelected?.call(null);
                });
              },
              child: MouseRegion(
                onEnter: (_) => setState(() => isHovered = true),
                onExit: (_) => setState(() => isHovered = false),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                        borderRadius : BorderRadius.all(Radius.circular(999)),
                        child: Image.memory(selectedFile!, fit: BoxFit.cover)),
                    if(isLoading) CircularProgressIndicator(),
                    if (isHovered && !isLoading)
                      Container(
                        height: double.infinity,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: MyColors.light.withAlpha((255*0.3).toInt()),
                          borderRadius:BorderRadius.circular(12),
                        ),

                        child: Icon(
                          Icons.delete_outline,
                          color: MyColors.error,
                          size: 40,
                        ),
                      ),
                  ],
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
