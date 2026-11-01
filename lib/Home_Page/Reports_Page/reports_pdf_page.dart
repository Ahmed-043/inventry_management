import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../../Database/category.dart';
import '../../Database/db_info.dart';
import '../../Database/retrieve_products.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';

class ReportsPdfPage extends StatefulWidget {
  final Database? db;
  final int? selectedCategoryId;
  final String searchString;

  const ReportsPdfPage({
    super.key,
    required this.db,
    this.selectedCategoryId,
    this.searchString = '',
  });

  @override
  State<ReportsPdfPage> createState() => _ReportsPdfPageState();
}

class _ReportsPdfPageState extends State<ReportsPdfPage> {
  String _sortOption = 'name_asc';
  String _categoryLayout = 'pages'; // 'pages' = Divide pages by category, 'list' = Divide list by categories
  double _zoomLevel = 0.7; // Default 70% zoom
  DBInfo? companyInfo;
  bool _isSharing = false;
  bool _isSaving = false;
  final Map<int, Uint8List?> _thumbnailCache = {};
  Uint8List? _compressedCompanyLogo;

  Uint8List? _getCompressedImage(Product p) {
    if (p.imageData == null || p.imageData!.isEmpty) return null;
    if (_thumbnailCache.containsKey(p.id)) {
      return _thumbnailCache[p.id];
    }
    try {
      final decoded = img.decodeImage(p.imageData!);
      if (decoded == null) {
        _thumbnailCache[p.id] = p.imageData;
        return p.imageData;
      }
      if (decoded.width <= 96 && decoded.height <= 96) {
        _thumbnailCache[p.id] = p.imageData;
        return p.imageData;
      }
      final resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 96 : null,
        height: decoded.height >= decoded.width ? 96 : null,
        interpolation: img.Interpolation.average,
      );
      final compressed = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
      _thumbnailCache[p.id] = compressed;
      return compressed;
    } catch (_) {
      _thumbnailCache[p.id] = p.imageData;
      return p.imageData;
    }
  }

  Uint8List? _getCompressedCompanyLogo() {
    if (companyInfo?.image == null || companyInfo!.image!.isEmpty) return null;
    if (_compressedCompanyLogo != null) return _compressedCompanyLogo;
    try {
      final decoded = img.decodeImage(companyInfo!.image!);
      if (decoded == null) {
        _compressedCompanyLogo = companyInfo!.image;
        return companyInfo!.image;
      }
      if (decoded.width <= 150 && decoded.height <= 150) {
        _compressedCompanyLogo = companyInfo!.image;
        return companyInfo!.image;
      }
      final resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 150 : null,
        height: decoded.height >= decoded.width ? 150 : null,
        interpolation: img.Interpolation.average,
      );
      _compressedCompanyLogo = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
      return _compressedCompanyLogo;
    } catch (_) {
      _compressedCompanyLogo = companyInfo!.image;
      return companyInfo!.image;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    if (widget.db != null) {
      final info = await getDBInfo(widget.db!);
      if (mounted) {
        setState(() {
          companyInfo = info;
        });
      }
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    if (widget.db == null) return Uint8List(0);

    // 1. Fetch products with images
    final products = await getProductsPage(
      widget.db!,
      0,
      100000,
      false, // load image data
      allProducts: true,
      search: widget.searchString,
    );

    if (widget.selectedCategoryId != null) {
      products.removeWhere((p) => p.category != widget.selectedCategoryId);
    }

    // 2. Fetch categories
    final categories = await getAllCategories(widget.db!);
    final Map<int, String> categoryMap = {
      for (var c in categories) c.id: c.name
    };

    for (var p in products) {
      if (p.category != null && p.category != 0) {
        p.categoryName = categoryMap[p.category];
      } else {
        p.categoryName = 'Uncategorized';
      }
    }

    // 3. Sort products according to selected sort option
    _sortProductList(products, _sortOption);

    // 4. Group products by category
    final Map<String, List<Product>> groupedProducts = {};
    for (var p in products) {
      final catName = p.categoryName ?? 'Uncategorized';
      groupedProducts.putIfAbsent(catName, () => []).add(p);
    }

    final pdf = pw.Document();
    final currentDateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    if (_categoryLayout == 'pages') {
      // MODE 1: Divide pages by category (Each category starts on a new A4 page)
      int globalSrNo = 1;
      groupedProducts.forEach((categoryName, catProducts) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            header: (context) => _buildPdfHeader(currentDateStr),
            footer: (context) => _buildPdfFooter(context),
            build: (context) => [
              pw.SizedBox(height: 10),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Text(
                  "Category: $categoryName",
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 8),
              _buildProductTable(catProducts, startSrNo: globalSrNo),
            ],
          ),
        );
        globalSrNo += catProducts.length;
      });

      if (groupedProducts.isEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            header: (context) => _buildPdfHeader(currentDateStr),
            footer: (context) => _buildPdfFooter(context),
            build: (context) => [
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Text("No products found.", style: const pw.TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
    } else {
      // MODE 2: Divide list by category (Continuous document with category divider rows)
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => _buildPdfHeader(currentDateStr),
          footer: (context) => _buildPdfFooter(context),
          build: (context) {
            final List<pw.Widget> widgets = [];
            widgets.add(pw.SizedBox(height: 10));

            int srNo = 1;
            groupedProducts.forEach((categoryName, catProducts) {
              widgets.add(
                pw.Container(
                  width: double.infinity,
                  margin: const pw.EdgeInsets.only(top: 10, bottom: 6),
                  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border.all(color: PdfColors.black, width: 0.5),
                  ),
                  child: pw.Text(
                    "Category: $categoryName",
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              );

              widgets.add(_buildProductTable(catProducts, startSrNo: srNo));
              srNo += catProducts.length;
              widgets.add(pw.SizedBox(height: 10));
            });

            if (groupedProducts.isEmpty) {
              widgets.add(
                pw.Center(
                  child: pw.Text("No products found.", style: const pw.TextStyle(fontSize: 16)),
                ),
              );
            }

            return widgets;
          },
        ),
      );
    }

    return await pdf.save();
  }

  void _sortProductList(List<Product> list, String option) {
    switch (option) {
      case 'name_asc':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'stock_asc':
        list.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'stock_desc':
        list.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case 'price_asc':
        list.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      case 'price_desc':
        list.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
    }
  }

  pw.Widget _buildPdfHeader(String currentDateStr) {
    final logoBytes = _getCompressedCompanyLogo();
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoBytes != null && logoBytes.isNotEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.only(right: 15),
              width: 55,
              height: 55,
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.cover),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyInfo?.dbName.toUpperCase() ?? "INVENTORY REPORT",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                if (companyInfo?.location.isNotEmpty ?? false)
                  pw.Text(companyInfo!.location, style: const pw.TextStyle(fontSize: 10)),
                if (companyInfo?.phone.isNotEmpty ?? false)
                  pw.Text("Phone: ${companyInfo!.phone}", style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 3),
                pw.Text(
                  "Date: $currentDateStr",
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              "STOCK REPORT",
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("ODVENTORY", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            "Page ${context.pageNumber} of ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProductTable(List<Product> products, {int startSrNo = 1}) {
    final priceFormat = NumberFormat('#,##0.00');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(32), // Sr no.
        1: pw.FixedColumnWidth(40), // Image
        2: pw.FlexColumnWidth(3),   // Name
        3: pw.FlexColumnWidth(1),   // SKU (halved width)
        4: pw.FixedColumnWidth(45), // Stock
        5: pw.FixedColumnWidth(75), // Unit Price (Rs.)
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _tableHeaderCell("Sr no."),
            _tableHeaderCell("Image"),
            _tableHeaderCell("Name", align: pw.Alignment.centerLeft),
            _tableHeaderCell("SKU", align: pw.Alignment.centerLeft),
            _tableHeaderCell("Stock", align: pw.Alignment.centerRight),
            _tableHeaderCell("Unit Price (Rs.)", align: pw.Alignment.centerRight),
          ],
        ),
        // Rows
        for (int i = 0; i < products.length; i++)
          _buildTableRow(products[i], startSrNo + i, priceFormat),
      ],
    );
  }

  pw.Widget _tableHeaderCell(String text, {pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.TableRow _buildTableRow(Product p, int srNo, NumberFormat priceFormat) {
    pw.Widget imageWidget;
    final compressedBytes = _getCompressedImage(p);
    if (compressedBytes != null && compressedBytes.isNotEmpty) {
      try {
        imageWidget = pw.Container(
          width: 24,
          height: 24,
          child: pw.Image(pw.MemoryImage(compressedBytes), fit: pw.BoxFit.contain),
        );
      } catch (_) {
        imageWidget = pw.SizedBox(width: 24, height: 24);
      }
    } else {
      imageWidget = pw.SizedBox(width: 24, height: 24);
    }

    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.Text("$srNo", style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(2),
          alignment: pw.Alignment.center,
          child: imageWidget,
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(p.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(p.sku ?? '-', style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerRight,
          child: pw.Text("${p.stock}", style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.centerRight,
          child: pw.Text(priceFormat.format(p.totalPrice), style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _generatePdf(PdfPageFormat.a4);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'Stock_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(bytes);

      if (Platform.isWindows) {
        final windowsPath = pdfFile.path.replaceAll('/', '\\');
        await Process.run('powershell', [
          '-Command',
          "Add-Type -AssemblyName System.Windows.Forms; \$col = New-Object System.Collections.Specialized.StringCollection; \$col.Add('$windowsPath'); [System.Windows.Forms.Clipboard]::SetFileDropList(\$col); Set-Clipboard -Path '$windowsPath'"
        ]);
        if (mounted) {
          UiHelper.showToast(context, 'PDF file copied to clipboard!', type: 1);
        }
      } else if (Platform.isLinux) {
        await Process.run('xclip', ['-selection', 'clipboard', '-t', 'application/pdf', '-i', pdfFile.path]);
        if (mounted) {
          UiHelper.showToast(context, 'PDF file copied to clipboard!', type: 1);
        }
      } else if (Platform.isMacOS) {
        await Process.run('osascript', ['-e', 'set the clipboard to (read (POSIX file "${pdfFile.path}") as PDF picture)']);
        if (mounted) {
          UiHelper.showToast(context, 'PDF file copied to clipboard!', type: 1);
        }
      } else {
        await Share.shareXFiles([XFile(pdfFile.path)], text: 'Stock Report PDF');
      }
    } catch (e) {
      if (mounted) UiHelper.showToast(context, "Error copying PDF: $e", type: 3);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _generatePdf(PdfPageFormat.a4);
      String? savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Stock Report PDF',
        fileName: 'Stock_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (savePath == null) return;
      if (!savePath.toLowerCase().endsWith('.pdf')) {
        savePath += '.pdf';
      }

      final file = File(savePath);
      await file.writeAsBytes(bytes);

      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', savePath]);
      }

      if (mounted) {
        UiHelper.showToast(context, "PDF saved successfully!", type: 1);
      }
    } catch (e) {
      if (mounted) UiHelper.showToast(context, "Error saving PDF: $e", type: 3);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildDropdownFilter({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: MyColors.textSecondary),
          style: MyFont.medium(14, color: MyColors.textMain),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildZoomSlider() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.zoom_out, size: 16, color: MyColors.textSecondary),
          SizedBox(
            width: 150,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: MyColors.sidebarSelected,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: MyColors.sidebarSelected,
              ),
              child: Slider(
                value: _zoomLevel,
                min: 0.4,
                max: 1.5,
                onChanged: (val) {
                  setState(() {
                    _zoomLevel = val;
                  });
                },
              ),
            ),
          ),
          const Icon(Icons.zoom_in, size: 16, color: MyColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            "${(_zoomLevel * 100).round()}%",
            style: MyFont.medium(12, color: MyColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: MyColors.mainBg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left: Back button + Title
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text("Stock Report", style: MyFont.bold(20, color: Colors.black)),
              ],
            ),
          ),

          // Center: Filter Dropdowns
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdownFilter(
                  value: _sortOption,
                  items: const [
                    DropdownMenuItem(value: 'name_asc', child: Text('Name (A - Z)')),
                    DropdownMenuItem(value: 'name_desc', child: Text('Name (Z - A)')),
                    DropdownMenuItem(value: 'stock_asc', child: Text('Stock (Low to High)')),
                    DropdownMenuItem(value: 'stock_desc', child: Text('Stock (High to Low)')),
                    DropdownMenuItem(value: 'price_asc', child: Text('Unit Price (Low to High)')),
                    DropdownMenuItem(value: 'price_desc', child: Text('Unit Price (High to Low)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortOption = val);
                  },
                ),
                const SizedBox(width: 10),
                _buildDropdownFilter(
                  value: _categoryLayout,
                  items: const [
                    DropdownMenuItem(value: 'pages', child: Text('Divide pages by category')),
                    DropdownMenuItem(value: 'list', child: Text('Divide list by categories')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _categoryLayout = val);
                  },
                ),
              ],
            ),
          ),

          // Right: Zoom Slider
          Align(
            alignment: Alignment.centerRight,
            child: _buildZoomSlider(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      margin: const EdgeInsets.all(15),
      height: 45,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UiHelper.myButton(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            callback: _handleShare,
            title: "Share Report",
            child: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: MyColors.info,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.share_rounded,
                    size: 20,
                    color: MyColors.info,
                  ),
            color: MyColors.info,
            borderRadius: 12,
            filled: false,
          ),
          const SizedBox(width: 8),
          UiHelper.myButton(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            callback: _handleSave,
            title: "Save PDF",
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: MyColors.translucent,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: MyColors.translucent,
                  ),
            color: MyColors.info,
            borderRadius: 12,
            filled: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.mainBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PdfPreview(
                      key: ValueKey('pdf_preview_${_sortOption}_$_categoryLayout'),
                      build: _generatePdf,
                      useActions: false,
                      shouldRepaint: true,
                      maxPageWidth: 800 * _zoomLevel,
                      scrollViewDecoration: const BoxDecoration(color: MyColors.mainBg),
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      loadingWidget: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildBottomActions(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
