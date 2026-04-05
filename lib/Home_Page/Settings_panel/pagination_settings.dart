import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Database/database.dart';

class PaginationSettingsWidget extends StatefulWidget {
  const PaginationSettingsWidget({super.key});

  @override
  State<PaginationSettingsWidget> createState() =>
      _PaginationSettingsWidgetState();
}

class _PaginationSettingsWidgetState extends State<PaginationSettingsWidget> {
  bool customize = false;
  int globalPageCount = 50;

  Future<void> _updateIntPref(
    String key,
    int value,
    void Function(int) assign,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (key == 'globalPageCount') {
      await _updateAll(value);
      return;
    } else {
      await prefs.setInt(key, value);
      setState(() => assign(value));
    }
  }

  @override
  void initState() {
    super.initState();
    if (productsPerPage == personsPerPage &&
        productsPerPage == ordersPerPage &&
        productsPerPage == transactionsPerPage) {
      setState(() {
        globalPageCount = productsPerPage!;
        customize = false;
      });
    } else {
      setState(() {
        customize = true;
      });
    }

    const steps = [10, 20, 50, 100, 250, 500, 700, 1000];

    void normalize(int current, String prefKey, void Function(int) assign) {
      if (!steps.contains(current)) {
        final fixed = steps.reduce(
          (a, b) => (current - a).abs() < (current - b).abs() ? a : b,
        );
        _updateIntPref(prefKey, fixed, assign);
      }
    }

    normalize(
      productsPerPage ?? 50,
      'productsPerPage',
      (v) => productsPerPage = v,
    );
    normalize(
      personsPerPage ?? 50,
      'personsPerPage',
      (v) => personsPerPage = v,
    );
    normalize(
      transactionsPerPage ?? 100,
      'transactionsPerPage',
      (v) => transactionsPerPage = v,
    );
    normalize(
      ordersPerPage ?? 50,
      'ordersPerPage',
          (v) => ordersPerPage = v,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: UiHelper.myBoxShadow(),
        border: UiHelper.myBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pagination Settings', style: MyFont.semiBold(20)),
          const SizedBox(height: 4),
          Text(
            'Adjust the number of items displayed per page across different sections.',
            style: MyFont.semiBold(12, color: MyColors.grey),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: .center,
            children: [
              Text('Customize pagination', style: MyFont.semiBold(14,color: MyColors.grey)),
              Transform.scale(
                scale: 0.8, // adjust (0.6–0.9)
                child: Switch(
                  value: customize,
                  onChanged: (v) {
                    if (!v) {
                      if((productsPerPage == personsPerPage &&
                          productsPerPage == ordersPerPage &&
                          productsPerPage == transactionsPerPage)){
                        globalPageCount = productsPerPage ?? 50;
                      }
                      _updateAll(globalPageCount);
                    }
                    setState(() => customize = v);
                  } ,
                  activeTrackColor: MyColors.primary,
                  activeColor: MyColors.translucent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          _paginationRow(
            label: 'Low Stock Limit',
            value: lowStockLimit,
            prefKey: 'lowStockLimit',
            assign: (v) => lowStockLimit = v,
            large: true,
          ),
          const SizedBox(height: 10),
          if (!customize)
            _paginationRow(
              label: 'All Pages',
              value: globalPageCount,
              prefKey: 'globalPageCount',
              assign: (v) => globalPageCount = v,
            ),

          if (customize) ...[
            _paginationRow(
              label: 'Products per page',
              value: productsPerPage!,
              prefKey: 'productsPerPage',
              assign: (v) => productsPerPage = v,
            ),
            _paginationRow(
              label: 'Persons per page',
              value: personsPerPage!,
              prefKey: 'personsPerPage',
              assign: (v) => personsPerPage = v,
            ),
            _paginationRow(
              label: 'Orders per page',
              value: ordersPerPage!,
              prefKey: 'ordersPerPage',
              assign: (v) => ordersPerPage = v,
            ),
            _paginationRow(
              label: 'Transactions per page',
              value: transactionsPerPage!,
              prefKey: 'transactionsPerPage',
              assign: (v) => transactionsPerPage = v,
            ),
          ],
        ],
      ),
    );
  }

  Widget _paginationRow({
    required String label,
    required int value,
    required String prefKey,
    required void Function(int) assign,
    bool large = false,
  }) {
    final List<int> pageSteps = large
        ? const [
            0,
            5,
            10,
            20,
            30,
            50,
            75,
            100,
            150,
            200,
            250,
            300,
            500,
            750,
            1000,
          ]
        : const [10, 20, 50, 100, 250, 500, 1000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                label,
                style: MyFont.semiBold(12),
              ),
            ),
            Expanded(
              flex: 3,
              child: Slider(
                padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
                value: pageSteps.indexOf(value).toDouble(),
                min: 0,
                max: (pageSteps.length - 1).toDouble(),
                divisions: pageSteps.length - 1, // equal spacing
                activeColor: MyColors.primary,
                onChanged: (v) {
                  final steppedValue = pageSteps[v.round()];
                  _updateIntPref(prefKey, steppedValue, assign);
                },
              ),
            ),
            //SizedBox(width: 20,),
            Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MyColors.lightGrey, width: 1),
              ),
              child: Center(
                child: Text(
                  "$value",
                  style: MyFont.semiBold(16, color: MyColors.grey),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateAll(int value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('productsPerPage', value);
    await prefs.setInt('personsPerPage', value);
    await prefs.setInt('ordersPerPage', value);
    await prefs.setInt('transactionsPerPage', value);

    setState(() {
      productsPerPage = value;
      personsPerPage = value;
      ordersPerPage = value;
      transactionsPerPage = value;
      globalPageCount = value;
    });
  }
}
