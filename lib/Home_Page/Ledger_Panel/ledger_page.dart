import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/ledger.dart';
import 'package:inventry_management/Shared_Widgets/sliding_segment_control.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/Database/pdf.dart';
import 'package:inventry_management/Database/person.dart';
import 'package:inventry_management/Home_Page/Expense_Tracking/Expense_Report/expense_report_widgets.dart';
import 'package:inventry_management/Shared_Widgets/date_time.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

import 'package:inventry_management/Database/db_info.dart';
import '../../Database/orders.dart';
import 'ledger_report_body.dart';

class LedgerPage extends StatefulWidget {
  final Person? initialPerson;
  const LedgerPage({super.key, this.initialPerson});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  Person? selectedPerson;
  List<Map<String, dynamic>> ledgerEntries = [];
  bool isLoading = false;
  DBInfo? companyInfo;

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  String _selectedView = 'Monthly';

  bool isSharing = false;
  bool isSaving = false;
  final GlobalKey _reportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    selectedPerson = widget.initialPerson;
    _loadCompanyInfo();
    
    if (selectedPerson != null) {
      _loadLedger();
    }
  }

  Future<void> _loadCompanyInfo() async {
    if (currentDB != null) {
      final info = await getDBInfo(currentDB!);
      setState(() => companyInfo = info);
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
    _loadLedger();
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
    _loadLedger();
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

  void _onRangeHoverScroll(int delta) {
    setState(() {
      _fromDate = _fromDate.add(Duration(days: delta));
      _toDate = _toDate.add(Duration(days: delta));
    });
    _loadLedger();
  }

  double _openingBalance = 0.0;

  Future<void> _loadLedger() async {
    if (selectedPerson == null || currentDB == null) return;
    setState(() => isLoading = true);
    
    final start = DateTime(_fromDate.year, _fromDate.month, _fromDate.day, 0, 0, 0).millisecondsSinceEpoch;
    final end = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59).millisecondsSinceEpoch;

    // Calculate opening balance if a start date is provided
    _openingBalance = await LedgerHelper.getOpeningBalance(
      currentDB!,
      personId: selectedPerson!.id!,
      timestamp: start,
    );

    final entries = await LedgerHelper.getLedgerEntries(
      currentDB!,
      personId: selectedPerson!.id!,
      startDate: start,
      endDate: end,
    );

    // Calculate running balances on the fly to handle backdating correctly
    double currentBal = _openingBalance;
    final List<Map<String, dynamic>> processedEntries = [];
    for (var entry in entries) {
      final amount = (entry['amount'] as num).toDouble();
      if (entry['entry_type'] == 'debit') {
        currentBal += amount;
      } else {
        currentBal -= amount;
      }
      
      final Map<String, dynamic> newEntry = Map.from(entry);
      newEntry['calculated_balance'] = currentBal;
      processedEntries.add(newEntry);
    }

    setState(() {
      ledgerEntries = processedEntries;
      isLoading = false;
    });
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
    _loadLedger();
  }

  Future<void> _selectFromDate() async {
    DateTime? picked = await pickDate(context, _fromDate);
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      });
      _loadLedger();
    }
  }

  Future<void> _selectToDate() async {
    DateTime? picked = await pickDate(context, _toDate);
    if (picked != null) {
      setState(() {
        _toDate = picked;
        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
      });
      _loadLedger();
    }
  }

  Future<void> _handleShare() async {
    setState(() => isSharing = true);
    await captureAndShareReceipt(_reportKey, 'LedgerReport_${selectedPerson?.name}');
    if (mounted) setState(() => isSharing = false);
  }

  Future<void> _handleSave() async {
    setState(() => isSaving = true);
    await captureAndSaveReceipt(_reportKey, name: 'LedgerReport_${selectedPerson?.name}_${DateFormat('yyyyMMdd').format(_fromDate)}');
    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MyColors.mainBg,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: MyColors.mainBg,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: MyColors.textMain),
                  onPressed: () => Navigator.pop(context),
                ),
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedPerson != null ? "${selectedPerson!.name}'s Ledger" : "Account Ledger",
                        style: MyFont.bold(20, color: MyColors.textMain),
                      ),
                      if (selectedPerson != null)
                        Row(
                          children: [
                            StatusSegmentedControl(
                              fontSize: 14,
                              selected: _selectedView,
                              options: const [
                                TwoValue(first: 'Daily', second: MyColors.sidebarSelected),
                                TwoValue(first: 'Weekly', second: MyColors.sidebarSelected),
                                TwoValue(first: 'Monthly', second: MyColors.sidebarSelected),
                                TwoValue(first: 'Yearly', second: MyColors.sidebarSelected),
                              ],
                              onChanged: (view) => _updateDatesForView(view),
                            ),
                            const SizedBox(width: 16),
                            HoverScroll(
                              onScroll: _onRangeHoverScroll,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, color: MyColors.grey),
                                    onPressed: () => _navigatePeriod(-1),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 120),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _getPeriodLabel(),
                                      style: MyFont.bold(14, color: MyColors.grey),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, color: MyColors.grey),
                                    onPressed: () => _navigatePeriod(1),
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
                  if (selectedPerson != null) ...[
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
                ],
              ),
              if (selectedPerson == null)
                SliverFillRemaining(child: _buildPersonSelector())
              else if (isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: RepaintBoundary(
                        key: _reportKey,
                        child: _buildLedgerView(),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          if (selectedPerson != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomActions(),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonSelector() {
    return FutureBuilder<List<Person>>(
      future: getPersons(currentDB!, pageSize: 100, personType: 'Customer', page: 1),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final persons = snapshot.data!;
        return ListView.builder(
          itemCount: persons.length,
          itemBuilder: (context, index) {
            final p = persons[index];
            return ListTile(
              title: Text(p.name, style: MyFont.medium(16)),
              subtitle: Text(p.personType, style: MyFont.normal(14, color: MyColors.grey)),
              onTap: () {
                setState(() => selectedPerson = p);
                _loadLedger();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLedgerView() {
    if (ledgerEntries.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          "No ledger entries found for this period.",
          style: MyFont.medium(16, color: MyColors.grey),
        ),
      );
    }

    double totalDebit = ledgerEntries
        .where((e) => e['entry_type'] == 'debit')
        .fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
    double totalCredit = ledgerEntries
        .where((e) => e['entry_type'] == 'credit')
        .fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
    double closingBalance = ledgerEntries.isEmpty ? _openingBalance : (ledgerEntries.last['calculated_balance'] as double);

    return LedgerReportBody(
      ledgerEntries: ledgerEntries,
      personName: selectedPerson?.name ?? '',
      fromDate: _fromDate,
      toDate: _toDate,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      closingBalance: closingBalance,
      companyInfo: companyInfo,
    );
  }

  Widget _buildBottomActions() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 45,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UiHelper.myButton(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            callback: _handleShare,
            title: "Share Ledger",
            child: isSharing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: MyColors.info))
                : const Icon(Icons.share_rounded, size: 20, color: MyColors.info),
            color: MyColors.info,
            borderRadius: 12,
            filled: false,
          ),
          const SizedBox(width: 12),
          UiHelper.myButton(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            callback: _handleSave,
            title: "Save as Image",
            child: isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download_rounded, size: 20, color: Colors.white),
            color: MyColors.info,
            borderRadius: 12,
            filled: true,
          ),
        ],
      ),
    );
  }
}
