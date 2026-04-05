import 'dart:io';
import 'dart:ui' as ui;
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../main.dart'; // import for navigatorKey
import 'package:process_run/shell.dart';

Future<void> saveAsPdf({required pw.Widget widget, String name = 'Receipt'}) async {
  try {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        // dynamic height
        build: (_) => widget,
      ),
    );
    String? savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF',
      fileName: '$name.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (savePath == null) return; // User cancelled
    if (!savePath.toLowerCase().endsWith('.pdf')) {
      savePath += '.pdf';
    }
    final file = File(savePath);
    await file.writeAsBytes(await pdf.save());
    await Process.run(
      'explorer',
      ['/select,', savePath],
    );
  }
  catch(e){
    debugPrint(e.toString());
  }
}

/// Converts a widget to an image and shares it via system share

Future<Uint8List?> captureWidget(GlobalKey key) async {
  try {
    RenderRepaintBoundary boundary =
    key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (e) {
    print(e);
    return null;
  }
}


Future<void> captureAndShareReceipt(GlobalKey key, String fileName) async {
  try {
    final boundary =
    key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      debugPrint('Boundary not found');
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName.png');
    await file.writeAsBytes(bytes);

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles([XFile(file.path)]);
    }
    else if (Platform.isWindows) {
      // Windows: Use PowerShell to trigger share
      final shell = Shell();
      await shell.run('''
        powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::SetImage([System.Drawing.Image]::FromFile('${file.path.replaceAll('/', '\\')}'))"
      ''');
      debugPrint('Image copied to clipboard! You can now paste it anywhere.');
    }
    else if (Platform.isLinux) {
      // Requires xclip (sudo apt install xclip)
      final shell = Shell();
      final path = file.path;
      await shell.run('''
    xclip -selection clipboard -t image/png -i "$path"
  ''');
      debugPrint('Image copied to clipboard (Linux)');
    }

    else if (Platform.isMacOS) {
      // Native macOS clipboard image copy
      final shell = Shell();
      final path = file.path;
      await shell.run('''
    osascript -e 'set the clipboard to (read (POSIX file "$path") as PNG picture)'
  ''');
      debugPrint('Image copied to clipboard (macOS)');
    }
    else {
      await Share.shareXFiles([XFile(file.path)]);
    }
  } catch (e) {
    debugPrint('Error capturing/sharing: $e');
  }
}

Future<void> captureAndSaveReceipt(GlobalKey key,{String name = 'receipt'}) async {
  try {
    final boundary =
    key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();

    // 🔹 Ask user where to save + file name
    String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Receipt',
      fileName: '$name.png',
      allowedExtensions: ['png'],
      type: FileType.custom,
    );

    if (path == null) return; // user cancelled

    // 🔹 Ensure .png extension
    if (!path.toLowerCase().endsWith('.png')) {
      path = '$path.png';
    }

    final file = File(path);
    await file.writeAsBytes(bytes);
    await Process.run(
      'explorer',
      ['/select,', path],
    );

    debugPrint('Receipt saved at: $path');
  } catch (e) {
    debugPrint('Error capturing/saving: $e');
  }
}