import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../colors.dart';
class ThemeSelector extends StatefulWidget {
  final VoidCallback? update,refresh;
  const ThemeSelector({super.key, this.update, this.refresh});

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      padding: const EdgeInsets.only(top:15, left: 20,right: 20,bottom:10),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        border: UiHelper.myBorder(),
        boxShadow: UiHelper.myBoxShadow(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Theme Preferences',
            style: MyFont.semiBold(20,color: MyColors.black),
          ),
           Text(
            "Manage your application's general behavior and display.",
            style: MyFont.semiBold(12,color: MyColors.grey),

          ),
          const SizedBox(height: 14),
          /// Light / Dark buttons
          Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                "System Theme",
                style: MyFont.semiBold(12,color: MyColors.grey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: UiHelper.myButton(
                        callback: () async {
                          plainUi = false;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('plainUi', plainUi);
                          if (widget.update != null && widget.refresh != null ) {
                            widget.update!();
                            widget.refresh!();
                          }
                        },
                        filled: !plainUi,
                        borderRadius: 12,
                        child: Icon(Icons.wb_sunny_outlined,color: plainUi ? MyColors.primary : MyColors.translucent,)
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: UiHelper.myButton(
                        callback: () async {
                          plainUi = true;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('plainUi', plainUi);
                          if (widget.update != null && widget.refresh != null ) {
                            widget.update!();
                            widget.refresh!();
                          }
                        },
                        filled: plainUi,
                        borderRadius: 12,
                        child: Icon(Icons.layers_outlined,color: !plainUi ? MyColors.primary: MyColors.translucent,)
                    ),
                  ),
                ],
              ),


            ],
          ),

          const SizedBox(height: 10),

          /// Preview labels
          const Row(
            children: [
              Expanded(child: Text('Warm Preview')),
              Expanded(child: Text('Light Preview')),
            ],
          ),
          const SizedBox(height: 8),

          /// Preview boxes
          Row(
            children: [
              Expanded(child: InkWell(
                onTap: () async {
                  plainUi = false;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('plainUi', plainUi);
                  if (widget.update != null && widget.refresh != null ) {
                    widget.update!();
                    widget.refresh!();
                  }
                },
                  child: _previewBox(selected: true))),
              const SizedBox(width: 12),
              Expanded(child: InkWell(
                  onTap: () async {
                    plainUi = true;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('plainUi', plainUi);
                    if (widget.update != null && widget.refresh != null ) {
                      widget.update!();
                      widget.refresh!();
                    }
                  },
                  child: _previewBox(selected: false))),
            ],
          ),
        ],
      ),
    );
  }


  Widget _previewBox({required bool selected}) {
    return Container(
      height: 65,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? MyColors.light : MyColors.lightestGrey,
        borderRadius: BorderRadius.circular(10),
        border: BoxBorder.all(color: !selected ? MyColors.lightGrey : Colors.transparent, width: plainUi ? 1.5 : 0),
        boxShadow: [
          if(selected)
          BoxShadow(
          color: Colors.grey.withAlpha(100),
          spreadRadius: 0.5,
          blurRadius: 3,
          offset: const Offset(-1, 1),
        ),
        ]
      ),
      child: Text(
        'Content',
        style: MyFont.semiBold(16,color: MyColors.grey),
      ),
    );
  }
}