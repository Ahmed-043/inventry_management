import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/upload_circle.dart';
import 'package:inventry_management/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/database.dart';
import '../Shared_Widgets/main_ui_helper.dart';


class CreateNewDatabase extends StatefulWidget {
  final VoidCallback callback;
   const CreateNewDatabase({super.key,required this.callback});

  @override
  State<CreateNewDatabase> createState() => _CreateNewDatabaseState();
}

class _CreateNewDatabaseState extends State<CreateNewDatabase> {
  TextEditingController locationController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  Uint8List? image;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    image = null;
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    locationController.dispose();
    nameController.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      width: 640,
      child: Column(
        children: [

          Center(
            child: Container(
              margin: EdgeInsets.only(top:5),
              color: MyColors.grey,
              height: 3,
              width: 150,
            )
          ),
         Expanded(child: SingleChildScrollView(
           scrollDirection: Axis.vertical,
           child: Column(
             children: [
               SizedBox(
                 height: 50,
                 width: double.infinity,
                 child: Center(
                   child: Text(
                     "Create new Database",
                     style: TextStyle(
                       color: Colors.blueGrey.shade700,
                       fontSize: 30,
                       fontWeight: FontWeight.w600,
                       fontFamily: 'Roboto',
                     ),
                   ),
                 ),
               ),
               Wrap(
                 crossAxisAlignment: WrapCrossAlignment.center,
                 runAlignment: WrapAlignment.center,
                 alignment: WrapAlignment.center,
                 children: [
                   Container(
                     // color: Colors.green,
                     padding: const EdgeInsets.all(10),
                     height: 240,
                     width: 240,
                     child: AspectRatio(
                       aspectRatio: 1,
                       child: UploadCircle(
                         onFileSelected: (file){
                           image = file;
                           debugPrint(image?.lengthInBytes.toString());
                         },
                       ),
                     ),
                   ),
                   SizedBox(
                     height: 250,
                     width: 400,
                     child: Container(
                       margin: const EdgeInsets.all(10),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           UiHelper.myTextField(
                             label: 'Database Name',
                             controller: nameController,
                           ),
                           const SizedBox(height: 10),
                           Row(
                             children: [
                               Expanded(
                                 flex: 4,
                                 child: SizedBox(
                                   height: 50,
                                   child: UiHelper.myTextField(
                                     label: 'Location',
                                     controller: locationController,
                                     hint: 'Default',
                                     readOnly: true,
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 10),
                               Expanded(
                                 flex: 1,
                                 child: SizedBox(
                                   height: 50,
                                   child: UiHelper.myFilePicker(callBack: () async {
                                     String? selectedDir =
                                     await FilePicker.platform
                                         .getDirectoryPath();
                                     if (selectedDir != null) {
                                       setState(() {
                                         locationController.text =
                                             selectedDir;
                                       });
                                     }
                                   }),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 20),
                           Row(
                             mainAxisAlignment:
                             MainAxisAlignment.spaceEvenly,
                             children: [
                               SizedBox(
                                 width: 150,
                                 height: 60,
                                 child: UiHelper.myButton(title: "Cancel", callback: () {
                                   nameController.clear();
                                   locationController.clear();
                                   Navigator.pop(context);
                                 }),
                               ),
                               SizedBox(
                                 width: 150,
                                 height: 60,
                                 child: UiHelper.myButton(
                                   title: "Create",
                                   filled: true,
                                   callback: () async {
                                     final dbName = nameController.text.trim().isEmpty
                                         ? 'default_db'
                                         : nameController.text.trim();
                                     final path = locationController.text
                                         .trim()
                                         .isEmpty
                                         ? null
                                         : Directory(locationController.text.trim());
                                     if (await createDatabase(
                                       dbName: dbName,
                                       path: path,
                                       image: image,

                                     )) {
                                       message("Database Created Successfully");

                                       close();
                                       widget.callback.call();
                                       // Navigator.pushReplacement(
                                       //   context,
                                       //   MaterialPageRoute(
                                       //     builder: (context) => SigninPage(),
                                       //   ),
                                       // );
                                     } else {
                                       message("Database already exists!");
                                     }
                                     debugPrint("${await getDbPaths()}");
                                   },
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
             ],
           ),
         ))
        ],
      ),
    );

  }
  message(String message){
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
          content: Text(message)),
    );
  }
  close(){
    Navigator.pop(context);
  }
}
