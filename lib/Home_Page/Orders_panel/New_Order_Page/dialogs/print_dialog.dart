import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> showCustomPdfPreview(BuildContext context, pw.Widget pdfWidget) async {
  const pageFormats = [
    'A4',
    'A3',
    'Letter',
    'Legal',
    'Executive',
    'A5',
    'B5',
    'Folio',
    'Ledger',
    'Tabloid',
  ];
  String selectedFormat = 'A4';
  double scale = 1.0;
  int pagesPerSheet = 1;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: 800,
            height: 600,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                const Text(
                  'Print Preview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildToolbar(
                  selectedFormat: selectedFormat,
                  pageFormats: pageFormats,
                  scale: scale,
                  pagesPerSheet: pagesPerSheet,
                  onFormatChanged: (v) => setState(() => selectedFormat = v),
                  onScaleChanged: (v) => setState(() => scale = v),
                  onPagesChanged: (v) => setState(() => pagesPerSheet = v),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildPreview(pdfWidget)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      final doc = pw.Document();
                      doc.addPage(pw.Page(build: (_) => pdfWidget));
                      await Printing.layoutPdf(
                        onLayout: (format) => doc.save(),
                        name: 'Document',
                      );
                    },
                    child: const Text('Print'),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

Widget _buildToolbar({
  required String selectedFormat,
  required List<String> pageFormats,
  required double scale,
  required int pagesPerSheet,
  required ValueChanged<String> onFormatChanged,
  required ValueChanged<double> onScaleChanged,
  required ValueChanged<int> onPagesChanged,
}) {
  return Row(
    children: [
      DropdownButton<String>(
        value: selectedFormat,
        items: pageFormats
            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
            .toList(),
        onChanged: (v) => onFormatChanged(v!),
      ),
      const SizedBox(width: 20),
      const Text('Scale:'),
      Slider(
        value: scale,
        min: 0.5,
        max: 2.0,
        divisions: 15,
        label: '${(scale * 100).round()}%',
        onChanged: onScaleChanged,
      ),
      const SizedBox(width: 20),
      const Text('Pages/Sheet:'),
      DropdownButton<int>(
        value: pagesPerSheet,
        items: [1, 2, 4, 6, 8]
            .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
            .toList(),
        onChanged: (v) => onPagesChanged(v!),
      ),
    ],
  );
}

Widget _buildPreview(pw.Widget pdfWidget) {
  return PdfPreview(
    allowPrinting: false,
    allowSharing: false,
    canChangeOrientation: false,
    canChangePageFormat: false,
    build: (format) async {
      final doc = pw.Document();
      doc.addPage(pw.Page(build: (_) => pdfWidget));
      return doc.save();
    },
    pdfPreviewPageDecoration: BoxDecoration(border: Border.all(color: Colors.grey)),
    actions: const [],
  );
}

