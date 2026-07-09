import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../colors.dart';
import 'fonts.dart';
import 'main_ui_helper.dart';

class AdderRemoverValue extends StatefulWidget {
  final int value;
  final ValueChanged<int> callBack;
  final bool isLarge;
  final int minValue;

  const AdderRemoverValue({
    super.key,
    required this.value,
    required this.callBack,
    this.isLarge = false,
    this.minValue = 0,
  });

  @override
  State<AdderRemoverValue> createState() => _AdderRemoverValueState();
}

class _AdderRemoverValueState extends State<AdderRemoverValue> {
  int selectedValue = 0;
  late int currentValue;

  final List<int> largeValues = [
    1, 5, 10, 25, 50, 100, 250, 500, 1000, 5000, 10000, 50000
  ];
  final List<int> values = [
    1, 5, 10, 25, 50, 100
  ];

  @override
  void initState() {
    super.initState();
    currentValue = widget.value;
  }

  final FocusNode _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: UiHelper.myDecoration(),

        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              // Skip if typing in a TextField or any editable field
              final focus = FocusManager.instance.primaryFocus;

              if (focus?.context != null &&
                  focus!.context!.findAncestorWidgetOfExactType<EditableText>() != null) {
                return;
              }

              final key = event.logicalKey.keyLabel; // "1", "2", "3", ...
              final index = int.tryParse(key);
              if (index != null && index >= 0) {
                if(currentValue.toString().length < 12){
                  currentValue = ((currentValue * 10) + index);
                }
              }
              else if (event.logicalKey == LogicalKeyboardKey.backspace) {
                if(currentValue > 0 ){
                  currentValue = (currentValue~/10);
                }
              }
              else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                currentValue += 1;
              }
              else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if(currentValue > 0) {
                  currentValue -= 1;
                }
              }
              }
            setState(() {
              widget.callBack(currentValue);
            });
          },
          child: widget.isLarge ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: MyColors.grey.withAlpha(12),
                      thumbColor:
                      selectedValue == 0 ? MyColors.info : MyColors.error,
                      groupValue: selectedValue,
                      children: {
                        0: Text('Add', style: MyFont.normal(15,color: selectedValue == 0 ? MyColors.translucent : MyColors.black)),
                        1: Text('Remove', style: MyFont.normal(15,color: selectedValue == 1 ? MyColors.translucent : MyColors.black)),
                      },
                      onValueChanged: (int? value) {
                        if (value != null) setState(() => selectedValue = value);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.undo_sharp),
                      onPressed: () {
                        setState(() => currentValue = widget.value);
                        widget.callBack(currentValue);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 5.0,
                      crossAxisSpacing: 5.0,
                      childAspectRatio: 2,
                    ),
                    itemCount: largeValues.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (selectedValue == 0) {
                              currentValue += largeValues[index];
                            } else {
                              currentValue =
                                  (currentValue - largeValues[index]).clamp(0, double.infinity).toInt();
                            }
                          });
                          widget.callBack(currentValue);
                        },
                        child: addBox(largeValues[index], selectedValue),
                      );
                    },
                  ),
                ),
              ],
            ),
          ): small(),
        ),
      ),
    );
  }
  Widget small(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Qty: ${NumberFormat.decimalPattern().format(currentValue)}",
                  style: MyFont.semiBold(18)
              ),
              IconButton(
                icon: const Icon(Icons.undo_sharp),
                onPressed: () {
                  setState(() => currentValue = widget.value);
                  widget.callBack(currentValue);
                },
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 5.0,
                      crossAxisSpacing: 5.0,
                      childAspectRatio: 2,
                    ),
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            currentValue += values[index];
                          });
                          widget.callBack(currentValue);
                        },
                        child: addBox(values[index], selectedValue),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 5.0,
                      crossAxisSpacing: 5.0,
                      childAspectRatio: 2,
                    ),
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            currentValue =
                                (currentValue - values[index]).clamp(widget.minValue, double.infinity).toInt();

                          });
                          widget.callBack(currentValue);
                        },
                        child: addBox(values[index], selectedValue == 0 ? 1 : 0),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget addBox(int value, int op) {
    return Container(
      decoration: BoxDecoration(
        color: op == 0
            ? MyColors.info.withAlpha(20)
            : MyColors.darkRed.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
          op == 0 ? MyColors.blue.withAlpha(50) : MyColors.darkRed.withAlpha(50),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          "${op == 0 ? '+' : '-'}${NumberFormat.decimalPattern().format(value)}",
          style: MyFiraFont.semiBold(
            20,
            color: op == 0 ? MyColors.blue : MyColors.darkRed,
          ),
        ),
      ),
    );
  }
}
