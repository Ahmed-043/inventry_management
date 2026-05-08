import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

 importDatabase(BuildContext context,{required VoidCallback callBack}) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['db'],
    dialogTitle: 'Select your database file',
  );
  String? filePath;
  if (result != null) {
    filePath = result.files.single.path;

    if (filePath != null) {
      debugPrint('Selected database file: $filePath');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> dbs = prefs.getStringList('db_paths') ?? [];
      if (!dbs.contains(filePath)) {
        dbs.add(filePath);
        await prefs.setStringList('db_paths', dbs);
        await prefs.setString('dbPath', filePath);
        debugPrint('Database path saved to preferences.');
        callBack.call();
      }
    } else {
      debugPrint('No file path selected.');
    }
  } else {
    debugPrint('User canceled the file picker.');
  }
}

Future<void> removeDbPath(String pathToRemove) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> paths = prefs.getStringList('db_paths') ?? [];

  paths.remove(pathToRemove); // remove matching string
  await prefs.setString('dbPath','');
  await prefs.setStringList('db_paths', paths); // save updated list
}
