import 'package:flutter/foundation.dart';
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
  List<Color>? extractedColors;

  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (extractedColors == null) {
            extractedColors = [];
            compute(_extractColorsTask, bytes).then((colorInts) {
              if (context.mounted) {
                setState(() {
                  extractedColors = colorInts.map((e) => Color(e)).toList();
                });
              }
            });
          }
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: UiHelper.myBoxShadow(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Text('Adjust Image', style: MyFont.bold(24, color: MyColors.dark)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: cropMode
                                ? Crop(
                                    image: bytes,
                                    baseColor: Colors.transparent,
                                    maskColor: Colors.black.withAlpha(100),
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
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: padColor,
                                      image: DecorationImage(
                                        image: MemoryImage(bytes),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        UiHelper.switchTile(
                          title: 'Crop Image',
                          value: cropMode,
                          onChanged: (v) => setState(() => cropMode = v),
                        ),
                        if (!cropMode) ...[
                          const SizedBox(height: 15),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Padding Color',
                              style: MyFont.bold(16, color: MyColors.dark),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final c in {
                                Colors.white,
                                Colors.black,
                                Colors.grey,
                                ...?extractedColors,
                              })
                                GestureDetector(
                                  onTap: () => setState(() => padColor = c),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: c == padColor
                                            ? MyColors.primary
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                      ),

                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                    decoration: BoxDecoration(
                      color: MyColors.translucent.withAlpha(30),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    //  border: Border(top: BorderSide(color: MyColors.lightGrey, width: 2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: UiHelper.myButton(
                            callback: () => Navigator.pop(context),
                            title: 'Cancel',
                            textSize: 15,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!cropMode)
                          Expanded(
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
                          Expanded(
                            child: UiHelper.myButton(
                              callback: () => cropController.crop(),
                              title: 'Crop',
                              filled: true,
                              textSize: 15,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

List<int> _extractColorsTask(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return [];

  final List<int> uniqueColors = [];

  // Distance threshold for considering colors "similar" (Euclidean distance in RGB)
  const double threshold = 30.0;
  const double thresholdSq = threshold * threshold;

  bool isSimilar(int color1, int color2) {
    final r1 = (color1 >> 16) & 0xFF;
    final g1 = (color1 >> 8) & 0xFF;
    final b1 = color1 & 0xFF;

    final r2 = (color2 >> 16) & 0xFF;
    final g2 = (color2 >> 8) & 0xFF;
    final b2 = color2 & 0xFF;

    final distSq = (r1 - r2) * (r1 - r2) +
        (g1 - g2) * (g1 - g2) +
        (b1 - b2) * (b1 - b2);
    return distSq < thresholdSq;
  }

  void addIfDistinct(int x, int y) {
    final p = decoded.getPixel(
      x.clamp(0, decoded.width - 1),
      y.clamp(0, decoded.height - 1),
    );
    final r = p.r.toInt().clamp(0, 255);
    final g = p.g.toInt().clamp(0, 255);
    final b = p.b.toInt().clamp(0, 255);
    final newColor = 0xFF000000 | (r << 16) | (g << 8) | b;

    // Skip if it's too similar to our defaults to avoid redundancy
    // White, Black, Grey (~0xFF9E9E9E)
    if (isSimilar(newColor, 0xFFFFFFFF) ||
        isSimilar(newColor, 0xFF000000) ||
        isSimilar(newColor, 0xFF9E9E9E)) {
      return;
    }

    // Skip if it's too similar to colors we've already picked
    if (uniqueColors.any((c) => isSimilar(c, newColor))) {
      return;
    }

    uniqueColors.add(newColor);
  }

  // Sample a 5x5 grid across the image
  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 5; j++) {
      addIfDistinct(
        (i * (decoded.width - 1) ~/ 4),
        (j * (decoded.height - 1) ~/ 4),
      );
    }
  }

  return uniqueColors;
}
