import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Shared_Widgets/app_cursor_overlay.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import '../../Database/Reports_Data/export_database.dart';
import '../../Database/Reports_Data/stock_snapshot_logic.dart';
import '../../Database/category.dart';
import '../../Database/database.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
import 'reports_table.dart';
import 'reports_utils.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<StockSnapshotRow>? _matrix;
  List<ProductStockValue>? _stockValues;
  List<DBCategory>? _categories;
  int? _selectedCategoryId; // null = "ALL" categories
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  DateTime _fromDate = DateTime(DateTime
      .now()
      .year, DateTime
      .now()
      .month, 1);
  DateTime _toDate = DateTime.now();

  // Scroll controllers to keep left (product) and right (data) lists vertically
  final ScrollController _leftController = ScrollController();
  final ScrollController _rightController = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    // Sync vertical scrolling between left and right lists so the product column stays aligned
    _leftController.addListener(() {
      if (_isSyncingScroll) return;
      _isSyncingScroll = true;
      if (_rightController.hasClients) {
        final offset = _leftController.offset.clamp(
          _rightController.position.minScrollExtent,
          _rightController.position.maxScrollExtent,
        );
        _rightController.jumpTo(offset);
      }
      _isSyncingScroll = false;
    });

    _rightController.addListener(() {
      if (_isSyncingScroll) return;
      _isSyncingScroll = true;
      if (_leftController.hasClients) {
        final offset = _rightController.offset.clamp(
          _leftController.position.minScrollExtent,
          _leftController.position.maxScrollExtent,
        );
        _leftController.jumpTo(offset);
      }
      _isSyncingScroll = false;
    });

    _loadCategories();
    _loadData();
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Load data from database
  Future<void> _loadData() async {
    if (currentDB == null) return;
    setState(() {
      _isLoading = true;
    });
    final data = await getStockSnapshotMatrix(
      currentDB!,
      startDate: _fromDate,
      endDate: _toDate,
      searchString: _searchController.text,
      categoryId: _selectedCategoryId,
    );
    final values = await getProductStockValues(
      currentDB!,
      searchString: _searchController.text,
    );
    if (mounted) {
      setState(() {
        _matrix = data;
        _stockValues = values;
        _isLoading = false;
      });
    }
  }

  /// Load categories from database
  Future<void> _loadCategories() async {
    if (currentDB == null) return;
    final categories = await getAllCategories(currentDB!);
    if (mounted) {
      setState(() {
        _categories = categories;
      });
    }
  }

  /// Show date picker for start date
  Future<void> _selectFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(ReportsConstants.minDateYear),
      lastDate: _toDate,
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
      _loadData();
    }
  }

  /// Show date picker for end date
  Future<void> _selectToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
      _loadData();
    }
  }

  /// Handle category selection
  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadData();
  }

  /// Handle search text changes with debounce
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: ReportsConstants.searchDebounceMsec),
          () {
        if (!mounted) return;
        _loadData();
        _debounce = null;
      },
    );
  }
  double padding = 10;

  @override
  Widget build(BuildContext context) {
    padding = 12.0;

    return Scaffold(
      backgroundColor: MyColors.mainBg,
      body: Padding(
        padding: EdgeInsets.only(top:padding,right: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _searchbar(),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _matrix == null || _matrix!.isEmpty
                  ? const Center(child: Text('No data available'))
                  : ReportsTable(
                    matrix: _matrix!,
                    stockValues: _stockValues ?? [],
                    leftController: _leftController,
                    rightController: _rightController,
                    db: currentDB,
                    onChange: () {
                      _loadData();
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the header with title and export button
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Reports",
          style: MyFont.bold(24, color: MyColors.textMain),
        ),
        Row(
          children: [
            UiHelper.myButton(
              callback: () {
                ReportsUtils.exportToCSV(context, _matrix, _stockValues);
              },
              child: const Icon(Icons.download, color: Colors.white, size: 18),
              title: "Export to Excel",
              textSize: 14,
              filled: true,
              color: MyColors.sidebarSelected,
              borderRadius: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications_none_rounded, color: MyColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _searchbar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: MouseRegion(
              onEnter: (_){
                isTextCursor = true;
              },
              onExit: (_){
                isTextCursor = false;
              },
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _onSearchChanged(),
                style: MyFont.medium(14, color: MyColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Search Product...',
                  hintStyle: MyFont.medium(14, color: MyColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: MyColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: _buildCategoryDropdown(),
        ),
        const SizedBox(width: 12),
        _DateButton(
          label: 'From: ${DateFormat('dd MMM yyyy').format(_fromDate)}',
          onTap: _selectFromDate,
        ),
        const SizedBox(width: 8),
        _DateButton(
          label: 'To: ${DateFormat('dd MMM yyyy').format(_toDate)}',
          onTap: _selectToDate,
        ),
        const SizedBox(width: 12),
        ScaledContainer(
          scale: 1.2,
          child: TextButton(
            onPressed: () {
              setState(() {
                _searchController.text = '';
                _selectedCategoryId = null;
                _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
                _toDate = DateTime.now();
              });
              _loadData();
            },
            child: Text(
              "Reset Filters",
              style: MyFont.bold(14, color: MyColors.sidebarSelected),
            ),
          ),
        ),
      ],
    );
  }

  /// Build category dropdown menu
  Widget _buildCategoryDropdown() {
    final categories = _categories ?? [];

    return ScaledContainer(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            dropdownColor: MyColors.translucent, // ✅ menu background color
            borderRadius: BorderRadius.circular(12), // ✅ rounded corners for menu
            value: _selectedCategoryId,
            hint: Text(
              'All Categories',
              style: MyFont.medium(14, color: MyColors.textSecondary),
            ),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: MyColors.textSecondary, size: 18),
            onChanged: _onCategorySelected,
            style: MyFont.medium(14, color: MyColors.textMain),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('ALL'),
              ),
              ...categories.map((category) {
                return DropdownMenuItem<int?>(
                  value: category.id,
                  child: Text(category.name),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: MyFont.medium(14, color: MyColors.textMain),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, color: MyColors.textSecondary, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

