import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense.dart';
import 'package:inventry_management/Database/Expense_Tracking/expense_category.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import 'package:inventry_management/Shared_Widgets/date_time.dart';
import 'package:inventry_management/Shared_Widgets/sliding_segment_control.dart';
import 'package:inventry_management/Database/pdf.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../../Database/orders.dart';
import 'expense_report_body.dart';
import 'expense_report_widgets.dart';

class DailyExpenseTracker extends StatefulWidget {
  const DailyExpenseTracker({super.key});

  @override
  State<DailyExpenseTracker> createState() => _DailyExpenseTrackerState();
}

class _DailyExpenseTrackerState extends State<DailyExpenseTracker> {
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  String _selectedView = 'Daily';

  List<Expense> expenses = [];
  Map<int, String> categoryNames = {};
  bool isLoading = false;
  bool isSharing = false;
  bool isSaving = false;

  final GlobalKey _reportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _toDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    if (currentDB != null) {
      final categories = await ExpenseCategory.getAll(currentDB!);
      categoryNames = {for (var c in categories) c.id!: c.name};

      final start = DateTime(_fromDate.year, _fromDate.month, _fromDate.day, 0, 0, 0).millisecondsSinceEpoch;
      final end = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59).millisecondsSinceEpoch;
      
      expenses = await Expense.getExpenses(
        db: currentDB!,
        startDate: start,
        endDate: end,
      );
    }
    setState(() => isLoading = false);
  }

  void _onDateScroll(int delta, bool isFromDate) {
    setState(() {
      if (isFromDate) {
        _fromDate = _fromDate.add(Duration(days: delta));
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = _toDate.add(Duration(days: delta));
        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
      }
    });
    _loadData();
  }

  void _onRangeHoverScroll(int delta) {
    setState(() {
      _fromDate = _fromDate.add(Duration(days: delta));
      _toDate = _toDate.add(Duration(days: delta));
    });
    _loadData();
  }

  Future<void> _selectFromDate() async {
    DateTime? picked = await pickDate(context, _fromDate);
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      });
      _loadData();
    }
  }

  Future<void> _selectToDate() async {
    DateTime? picked = await pickDate(context, _toDate);
    if (picked != null) {
      setState(() {
        _toDate = picked;
        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
      });
      _loadData();
    }
  }

  void _updateDatesForView(String view) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedView = view;
      switch (view) {
        case 'Daily':
          _fromDate = today;
          _toDate = today;
          break;
        case 'Weekly':
          _fromDate = today.subtract(Duration(days: today.weekday - 1));
          _toDate = _fromDate.add(const Duration(days: 6));
          break;
        case 'Monthly':
          _fromDate = DateTime(today.year, today.month, 1);
          _toDate = DateTime(today.year, today.month + 1, 0);
          break;
        case 'Yearly':
          _fromDate = DateTime(today.year, 1, 1);
          _toDate = DateTime(today.year, 12, 31);
          break;
      }
    });
    _loadData();
  }

  void _navigatePeriod(int delta) {
    setState(() {
      switch (_selectedView) {
        case 'Daily':
          _fromDate = _fromDate.add(Duration(days: delta));
          _toDate = _fromDate;
          break;
        case 'Weekly':
          _fromDate = _fromDate.add(Duration(days: delta * 7));
          _toDate = _fromDate.add(const Duration(days: 6));
          break;
        case 'Monthly':
          _fromDate = DateTime(_fromDate.year, _fromDate.month + delta, 1);
          _toDate = DateTime(_fromDate.year, _fromDate.month + 1, 0);
          break;
        case 'Yearly':
          _fromDate = DateTime(_fromDate.year + delta, 1, 1);
          _toDate = DateTime(_fromDate.year, 12, 31);
          break;
      }
    });
    _loadData();
  }

  String _getPeriodLabel() {
    switch (_selectedView) {
      case 'Daily':
        return DateFormat('dd MMM yyyy').format(_fromDate);
      case 'Weekly':
        return "${DateFormat('dd MMM').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}";
      case 'Monthly':
        return DateFormat('MMMM yyyy').format(_fromDate);
      case 'Yearly':
        return DateFormat('yyyy').format(_fromDate);
      default:
        return "";
    }
  }

  Future<void> _handleShare() async {
    setState(() {
      isSharing = true;
    });

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await captureAndShareReceipt(_reportKey, 'ExpenseReport');
      if (mounted) {
        UiHelper.showToast(context, 'Image copied to clipboard!', type: 1);
      }
    } else {
      await captureAndShareReceipt(_reportKey, 'ExpenseReport');
    }
    if (mounted) {
      setState(() {
        isSharing = false;
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() {
      isSaving = true;
    });
    await captureAndSaveReceipt(_reportKey, name: 'ExpenseReport_${DateFormat('yyyyMMdd').format(_fromDate)}');
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalIn = expenses.where((e) => e.amount > 0).fold(0, (sum, item) => sum + item.amount);
    double totalOut = expenses.where((e) => e.amount < 0).fold(0, (sum, item) => sum + item.amount.abs());
    double netTotal = totalIn - totalOut;

    return Material(
      color: MyColors.translucent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: false,
                  backgroundColor: MyColors.translucent,
                  elevation: 2,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  titleSpacing: 0,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Expense Report ", style: MyFont.bold(20)),
                        Row(
                          children: [
                            StatusSegmentedControl(
                              fontSize: 20,
                              selected: _selectedView,
                              options: const [
                                TwoValue(first: 'Daily', second: MyColors.sidebarSelected),
                                TwoValue(first: 'Weekly', second: MyColors.sidebarSelected),
                                TwoValue(first: 'Monthly', second: MyColors.sidebarSelected),
                                TwoValue(first: 'Yearly', second: MyColors.sidebarSelected),
                              ],
                              onChanged: (view) => _updateDatesForView(view),
                            ),
                            const SizedBox(width: 24),
                            HoverScroll(
                              onScroll: _onRangeHoverScroll,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaledContainer(
                                    scale: 1.4,
                                    child: IconButton(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      icon: const Icon(Icons.arrow_back_rounded, color: MyColors.lightGrey, size: 28),
                                      onPressed: () => _navigatePeriod(-1),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 150),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _getPeriodLabel(),
                                      style: MyFont.bold(18, color: MyColors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  ScaledContainer(
                                    scale: 1.4,
                                    child: IconButton(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      icon: const Icon(Icons.arrow_forward_rounded, color: MyColors.lightGrey, size: 28),
                                      onPressed: () => _navigatePeriod(1),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(),
                      ],
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    DateButton(
                      label: 'From: ${DateFormat('dd MMM yyyy').format(_fromDate)}',
                      onTap: _selectFromDate,
                      onScroll: (delta) => _onDateScroll(delta, true),
                    ),
                    const SizedBox(width: 8),
                    DateButton(
                      label: 'To: ${DateFormat('dd MMM yyyy').format(_toDate)}',
                      onTap: _selectToDate,
                      onScroll: (delta) => _onDateScroll(delta, false),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 70),
                      child: Center(
                        child: RepaintBoundary(
                          key: _reportKey,
                          child: ExpenseReportBody(
                            expenses: expenses,
                            categoryNames: categoryNames,
                            fromDate: _fromDate,
                            toDate: _toDate,
                            totalIn: totalIn,
                            totalOut: totalOut,
                            netTotal: netTotal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(15),
              height: 35,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiHelper.myButton(
                    padding: const EdgeInsets.all(14),
                    callback: _handleShare,
                    title: "Share Report",
                    child: isSharing
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
                    textSize: 14,
                  ),
                  const SizedBox(width: 8),
                  UiHelper.myButton(
                    padding: const EdgeInsets.all(14),
                    callback: _handleSave,
                    title: "Save Report",
                    child: isSaving
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
                    textSize: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
