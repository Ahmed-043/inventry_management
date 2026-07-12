import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';

class AddNewPerson {
  static Widget addNew({
    required BuildContext context,
    required Widget action,
    bool isCustomer = false,
  }) {
    // Generate a unique tag if you have multiple buttons on one screen
    final String heroTag = 'newPersonHero_${isCustomer ? "customer" : "supplier"}';

    return Container(
      height: 30,
      //margin: const EdgeInsets.only(top: 5),
      width: 200,
      child: Hero(
        tag: heroTag,
        child: UiHelper.myButton(
          callback: () {
            // Using pushPage (as per your AddNewProduct logic) for the Hero transition
            UiHelper.pushPage(
              context: context,
              opaque: false,
              barrierColor: Colors.black54,
              barrierDismissible: true,
              page: _AddNewPersonDialog(
                action: action,
                heroTag: heroTag,
              ),
            );
          },
          filled: true,
          textSize: 15,
          borderRadius: 10,
          title: "Add New ${isCustomer ? 'Customer' : 'Supplier'}",
        ),
      ),
    );
  }
}

class _AddNewPersonDialog extends StatefulWidget {
  final Widget action;
  final String heroTag;

  const _AddNewPersonDialog({
    Key? key,
    required this.action,
    required this.heroTag,
  }) : super(key: key);

  @override
  State<_AddNewPersonDialog> createState() => _AddNewPersonDialogState();
}

class _AddNewPersonDialogState extends State<_AddNewPersonDialog> {
  bool showContent = false;

  @override
  void initState() {
    super.initState();
    // Delay showing the form content until the Hero animation is underway
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          showContent = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: widget.heroTag,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 450,
              maxHeight: 640,
              minWidth: 400,
              minHeight: 400,
            ),
            decoration: BoxDecoration(
              // Using Alpha 230 to match your AddNewProduct translucent look
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: showContent
                ? widget.action
                : const SizedBox(width: 450, height: 640),
          ),
        ),
      ),
    );
  }
}