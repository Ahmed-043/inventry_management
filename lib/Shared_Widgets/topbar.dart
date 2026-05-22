
import 'dart:ui';
import 'package:inventry_management/colors.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import '../Database/database.dart';
import 'main_ui_helper.dart';

class Topbar extends StatelessWidget {
  final String title;
  final Widget button;

  const Topbar({super.key, required this.title, required this.button});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        //const SizedBox(width: 20),
        Text(
          title,
          style: TextStyle(
            color: MyColors.blue,
            fontSize: 30,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(width: 20),
        button,
        Expanded(child: SizedBox()),


      ],
    );
  }
}

class ReusableTopBar extends StatelessWidget {
  final String title;
  final String searchHint;
  final Widget actionButton;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final List<Map<String, dynamic>> stockButtons;
  final int selectedIndex;
  final Function(int index) onButtonSelect;
  final applyBlur;

   const ReusableTopBar({
    super.key,
    required this.title,
    this.searchHint = "Search",
    required this.actionButton,
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    required this.stockButtons,
    required this.selectedIndex,
    required this.onButtonSelect,
    this.applyBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    final backgroundColor =  (plainUi && !applyBlur) ? MyColors.lightestGrey : Colors.transparent;
    bool compress = MediaQuery.of(context).size.width < 600;
    return Container(
      height: compress ? 100 : 60,
     // padding: EdgeInsets.symmetric(horizontal: 10),
      color: (plainUi && !applyBlur) ? MyColors.lightestGrey : Colors.transparent ,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if(applyBlur) ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 3),
              child: Container(color: backgroundColor),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT SECTION (Title + Custom Button)
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          if(title.isNotEmpty)
                          SizedBox(
                            width: title == 'Orders' ? 100 : 160,
                            child: Text(
                              title,
                              style: MyFont.bold(30,color: MyColors.blue)
                            ),
                          ),
                          //const SizedBox(width: 15),
                          Expanded(child: Padding(
                            padding: EdgeInsets.symmetric(vertical:5),
                            child: actionButton,
                          )),
                        ],
                      ),
                    ),

                    const SizedBox(width: 5),

                    // CENTER (Search Bar)
                    if(!compress)
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.only(top: 5),
                        child: UiHelper.mySearchBar(
                          controller: searchController,
                          hint: searchHint,
                          onChange: onSearch,
                          onCancel: onClear,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // RIGHT (Filter Buttons)
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Listener(
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              final offset = scrollController.offset + event.scrollDelta.dy;
                              scrollController.jumpTo(
                                offset.clamp(
                                  scrollController.position.minScrollExtent,
                                  scrollController.position.maxScrollExtent,
                                ),
                              );
                            }
                          },
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: scrollController,
                            child: Row(
                              children: List.generate(stockButtons.length, (i) {
                                final btn = stockButtons[i];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Tooltip(
                                    message:
                                    "${btn['title']}${btn['count'].toString().contains(RegExp(r'[^0-9]')) ? '\n' : ' '}${btn['count'].toString().replaceAll(RegExp(r'[\{\}\[\]]'), '').replaceAll(':', ' ').replaceAll(',', '\n')}".trim(),
                                    child: UiHelper.mySelectableButton(
                                      title: btn['title'],
                                      isSelected: selectedIndex == i,
                                      onPressed: () => onButtonSelect(i),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if(compress)
              SizedBox(
                height: 45,
                child: Container(
                  margin: const EdgeInsets.only(top: 5,right: 10,left:10),
                  child: UiHelper.mySearchBar(
                    controller: searchController,
                    hint: searchHint,
                    onChange: onSearch,
                    onCancel: onClear,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
