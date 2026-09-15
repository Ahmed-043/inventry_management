import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Database/ledger.dart';
import 'package:inventry_management/Database/payment_transactions.dart';
import 'package:inventry_management/Home_Page/home_page.dart';
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
import '../Customers&Suppliers/person_payment_dialog.dart';
import '../Orders_panel/New_Order_Page/dialogs/choose_person.dart';
import 'ledger_report_body.dart';
import 'ledger_side_panel.dart';

class LedgerPage extends StatefulWidget {
  final Person? initialPerson;
  final VoidCallback? onBack;
  const LedgerPage({super.key, this.initialPerson, this.onBack});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> with SingleTickerProviderStateMixin {
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

  final TextEditingController payController = TextEditingController();
  final TextEditingController receiveController = TextEditingController();

  late final AnimationController _topControlsController;
  late final Animation<double> _topControlsAnimation;

  @override
  void dispose() {
    payController.dispose();
    receiveController.dispose();
    _topControlsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    selectedPerson = widget.initialPerson;
    _loadCompanyInfo();
    
    _topControlsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _topControlsAnimation = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(parent: _topControlsController, curve: Curves.easeOut),
    );

    if (!performanceMode) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _topControlsController.forward();
        }
      });
    } else {
      _topControlsController.value = 1.0;
    }

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!performanceMode) {
          _topControlsController.reverse().then((_) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Material(
        color: MyColors.sidebarBg,
        child: Stack(
          children: [
          Hero(
            tag: "sidebar",
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: .topLeft,
                child: Container(
                  color: MyColors.sidebarBg,
                  width: 370,
                  child: LedgerSidePanel(
                    selectedPerson: selectedPerson,
                    fromDate: _fromDate,
                    toDate: _toDate,
                    payController: payController,
                    receiveController: receiveController,
                    onChoosePerson: _choosePerson,
                    onSelectFromDate: _selectFromDate,
                    onSelectToDate: _selectToDate,
                    onDateScrollFrom: (delta) => _onDateScroll(delta, true),
                    onDateScrollTo: (delta) => _onDateScroll(delta, false),
                    onBack: widget.onBack,
                    onAutoFill: () {
                      setState(() {
                        payController.text = selectedPerson!.outgoing.clamp(0, selectedPerson!.incoming).toString();
                        receiveController.text = payController.text;
                      });
                    },
                    onSavePayment: (pay, receive) async {
                      if (pay > 0 || receive > 0) {
                        await distributePayments(
                          currentDB!,
                          personId: selectedPerson!.id!,
                          pay: pay,
                          receive: receive,
                        );

                        if (mounted) {
                          UiHelper.showToast(context, "Payment Saved Successfully", type: 1);
                          payController.clear();
                          receiveController.clear();

                          // Refresh person data to update balances
                          final updatedPersons = await getPersons(
                            currentDB!,
                            personType: selectedPerson!.personType,
                            page: 0,
                            pageSize: 100
                          );
                          final p = updatedPersons.firstWhere(
                            (element) => element.id == selectedPerson!.id,
                            orElse: () => selectedPerson!
                          );

                          setState(() {
                            selectedPerson = p;
                          });

                          _loadLedger();
                        }
                      } else {
                        if (mounted) {
                          UiHelper.showToast(context, "Please enter an amount", type: 2);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 370,
            top: 0,
            right: 0,
            bottom: 0,
            child: Hero(
              tag: "main_page",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  color: MyColors.mainBg,
                  height: double.infinity,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 40)),

                          if (isLoading)
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
                            alignment: .topCenter,
                            child: _buildTopControls()),
                      if (selectedPerson != null)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildBottomActions(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildTopControls() {
    final Widget controls = Container(
      height: 40,
      width: 550,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        color: MyColors.sidebarBg,
      ),
      child: Row(
        mainAxisAlignment: .center,
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
          const SizedBox(width: 20),
          HoverScroll(
            onScroll: _onRangeHoverScroll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: MyColors.translucent),
                  onPressed: () => _navigatePeriod(-1),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 120),
                  alignment: Alignment.center,
                  child: Text(
                    _getPeriodLabel(),
                    style: MyFont.bold(14, color: MyColors.translucent),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: MyColors.translucent),
                  onPressed: () => _navigatePeriod(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (performanceMode) {
      return controls;
    }

    return AnimatedBuilder(
      animation: _topControlsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _topControlsAnimation.value),
          child: child,
        );
      },
      child: controls,
    );
  }


  Future<void> _choosePerson() async {
    final person = await UiHelper.pushPage<Person?>(
      context: context,
      opaque: false,
      barrierDismissible: true,
      page: Center(
        child: Material(
          color: Colors.transparent,
          child: Hero(
            tag: "person_card",
            child: Container(
              width: 400,
              height: 600,
              decoration: UiHelper.myDecoration(),
              child: ChoosePerson(
                filter: 0,
                person: selectedPerson,
              ),
            ),
          ),
        ),
      ),
    );

    if (person != null) {
      setState(() {
        selectedPerson = person;
      });
      _loadLedger();
    }
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
}
