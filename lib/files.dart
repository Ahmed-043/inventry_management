import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

import 'package:flutter/foundation.dart';


   Future<Uint8List?> imagePicker({bool compress = true}) async {
     try{
       FilePickerResult? result = await FilePicker.platform
           .pickFiles(type: FileType.image);
       Uint8List? image;
       if (result != null) {
         String imagePath = result.files.single.path!;
         //print("Picked image path: $imagePath");
         image = await convertImageToBytes(imagePath,compress: compress);
         return image;
       } else {
         debugPrint("No file selected");
         return null;
       }
     }
   catch(e){
       debugPrint(e.toString());
   }
     return null;
  }

   Future<Uint8List?> convertImageToBytes(String image,{bool compress = true}) async {
    try {
      Uint8List? imageBytes;
      imageBytes = await File(image).readAsBytes();
    if(!compress){

      return imageBytes;
    }
    else{
      debugPrint("Compressing image");
      imageBytes = await compressImage(imageBytes);
    }
      return imageBytes;
    } catch (e) {
      debugPrint("Error converting image to bytes: $e");
      return null;
    }
  }



Future<Uint8List?> compressImage(Uint8List imageBytes) async {
  try {
    // compress if > 500 KB
    if (imageBytes.lengthInBytes > 1200 * 1024) {
      final decoded = await compute(
        decodeImageBytes,
        imageBytes,
      ); // heavy work off main isolate
      if (decoded != null) {
        imageBytes = Uint8List.fromList(
          img.encodeJpg(decoded, quality: 40),
        );
      }
    } else if (imageBytes.lengthInBytes > 500 * 1024) {
      final decoded = await compute(
        decodeImageBytes,
        imageBytes,
      ); // heavy work off main isolate
      if (decoded != null) {
        imageBytes = Uint8List.fromList(
          img.encodeJpg(decoded, quality: 70),
        );
      }
    }

    return imageBytes;
  } catch (e) {
    debugPrint("Error converting image to bytes: $e");
    return null;
  }
}

img.Image? decodeImageBytes(Uint8List bytes) {
  return img.decodeImage(bytes);
}