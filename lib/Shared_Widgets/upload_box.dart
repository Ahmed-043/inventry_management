import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
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
    // TODO: implement initState
    super.initState();
  }
@override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

  }
  void _onTap() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      isHovered = false;
    });
    Uint8List? file;
    try{
     file  = await imagePicker(compress: false);
     setState(() {
       isCompressing = true;
     });
     if(file == null ){
       setState(() {
         isLoading = false;
         isCompressing = false;
       });
       return;
     }
     file = await compute(compressImage,file);
     //file = await compressImage(file);
   //  if (!mounted) return; // page may have closed

     setState(() => selectedFile = file);
     widget.onFileSelected?.call(file);
       }catch(e){
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

    debugPrint("Tap");
  }


  void _onDrop(List<XFile> files) async {
    setState(() {
      isLoading = true;
      isCompressing = true;
    });
    if (files.isNotEmpty) {
      final file = await handleDrop(files.first.path); // from file_utils.dart
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

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: DropTarget(
        onDragDone: (details) => _onDrop(details.files),
        onDragEntered: (_) => setState(() => isDragging = true),
        onDragExited: (_) => setState(() => isDragging = false),
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            dashPattern: [6, 3],
            strokeWidth: 1,
            radius: Radius.circular(12),
            color: Colors.grey,
            //padding: EdgeInsets.all(4),
          ),
          child: selectedFile == null
              ? SizedBox(
                  height: selectedFile != null ? null : double.infinity,
                  width: selectedFile != null ? null : double.infinity ,
                  child: InkWell(
                    onTap: _onTap,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 5,
                          left:10,
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
                                  ? CircularProgressIndicator(color: MyColors.darkBlue,)
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
                            Hero(
                              tag: "${widget.heroTag}",
                              child: ClipRRect(
                                                      borderRadius : BorderRadius.all(Radius.circular(12)),
                                  child: Image.memory(selectedFile!, fit: BoxFit.fitHeight)),
                            ),
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
