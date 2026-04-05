import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../colors.dart';

Future<Uint8List?> showManualCropDialog(
  BuildContext context,
  Uint8List bytes,
) async {
  final cropController = CropController();
  bool cropMode = true;
  Color padColor = Colors.white;

  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            scrollable: true,
            contentPadding: const EdgeInsets.all(16),
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text('Adjust Image', style: MyFont.semiBold(20)),
            content: SizedBox(
              width: 350,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: cropMode
                        ? ClipRRect(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            child: Crop(
                              image: bytes,
                              baseColor: Colors.transparent,
                              maskColor: Colors.black.withAlpha(40),
                              controller: cropController,
                              aspectRatio: 1,
                              onCropped: (cropResult) {
                                if (cropResult is CropSuccess) {
                                  Navigator.pop(
                                    context,
                                    cropResult.croppedImage,
                                  );
                                }
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: padColor,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              image: DecorationImage(
                                image: MemoryImage(bytes),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Crop Image'),
                    hoverColor: Colors.transparent,
                    activeTrackColor: MyColors.primary,
                    value: cropMode,
                    onChanged: (v) => setState(() => cropMode = v),
                  ),
                  if (!cropMode)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final c in [
                          Colors.white,
                          Colors.black,
                          Colors.grey,
                        ])
                          GestureDetector(
                            onTap: () => setState(() => padColor = c),
                            child: CircleAvatar(
                              backgroundColor: c,
                              radius: 18,
                              child: c == padColor
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.blue,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: 100,
                height: 30,
                child: UiHelper.myButton(
                  callback: () => Navigator.pop(context),
                  title: 'Cancel',
                  textSize: 15,
                ),
              ),
              if (!cropMode)
                SizedBox(
                  width: 120,
                  height: 30,
                  child: UiHelper.myButton(
                    callback: () {
                      final image = img.decodeImage(bytes);
                      if (image == null) return;
                      final size = image.width > image.height
                          ? image.width
                          : image.height;
                      final padded = img.Image(width: size, height: size);
                      img.fill(
                        padded,
                        color: img.ColorRgb8(
                          (padColor.r * 255.0).round().clamp(0, 255),
                          (padColor.g * 255.0).round().clamp(0, 255),
                          (padColor.b * 255.0).round().clamp(0, 255),
                        ),
                      );
                      final x = ((size - image.width) / 2).round();
                      final y = ((size - image.height) / 2).round();
                      img.compositeImage(padded, image, dstX: x, dstY: y);
                      final result = Uint8List.fromList(
                        img.encodeJpg(padded, quality: 85),
                      );

                      // Return padded image
                      Navigator.pop(context, result);
                    },
                    title: 'Pad to Square',
                    filled: true,
                    textSize: 15,
                  ),
                ),

              if (cropMode)
                SizedBox(
                  width: 100,
                  height: 30,
                  child: UiHelper.myButton(
                    callback: () => cropController.crop(),
                    title: 'Save',
                    filled: true,
                    textSize: 15,
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}
