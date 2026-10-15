import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
import '../../colors.dart';

class AddNewTransaction {
  static Widget addNew({required BuildContext context, required Widget action}) {
    return SizedBox(
      width: 200,
      child: Hero(
        tag: 'newTransaction',
        child: UiHelper.myButton(
          callback: () {
            UiHelper.pushPage(
              context: context,
              opaque: false,
              barrierColor: Colors.black54,
              page: AddNewTransactionDialog(action: action),
            );
          },
          title: "Add New Transaction",
          textSize: 15,
          filled: true,
          borderRadius: 10,
        ),
      ),
    );
  }
}

class AddNewTransactionDialog extends StatefulWidget {
  final Widget action;
  const AddNewTransactionDialog({super.key, required this.action});

  @override
  State<AddNewTransactionDialog> createState() => AddNewTransactionDialogState();
}

class AddNewTransactionDialogState extends State<AddNewTransactionDialog> {
  bool showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 0), () {
      if (mounted) {
        setState(() {
          showContent = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = context.isPhone;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = isPhone ? (screenWidth - 32) : 500.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Hero(
          tag: 'newTransaction',
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: isPhone ? (MediaQuery.of(context).size.height * 0.85) : 750,
              ),
              decoration: BoxDecoration(
                color: MyColors.translucent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: showContent ? widget.action : SizedBox(width: dialogWidth, height: 280),
            ),
          ),
        ),
      ),
    );
  }
}
