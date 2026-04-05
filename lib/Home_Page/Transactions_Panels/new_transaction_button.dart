import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
class AddNewTransaction {
  static Widget addNew({required BuildContext context, required Widget action}) {
    return SizedBox(

      width: 200,
      child: Hero(
        tag: 'newTransaction',
        child: UiHelper.myButton(
          callback: () {
            // Use a PageRouteBuilder for Hero animation instead of showDialog
            UiHelper.pushPage(
                context: context,
                opaque: false, // background remains visible
                barrierColor: Colors.black54, // dim background
                page: AddNewTransactionDialog(action: action));

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
  const AddNewTransactionDialog({Key? key, required this.action}) : super(key: key);

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
   // double height = MediaQuery.of(context).size.height > 850 ? 800.0 : MediaQuery.of(context).size.height-20;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Hero(
          tag: 'newTransaction',
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 500,
             // height: height ,
              constraints: BoxConstraints(
                maxHeight: 750
              ),
              decoration: BoxDecoration(
                color: MyColors.translucent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: showContent ? widget.action : const SizedBox(width: 450,height: 280),
            ),
          ),
        ),
      ),
    );
  }
}


