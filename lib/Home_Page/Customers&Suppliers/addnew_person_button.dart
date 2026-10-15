import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
import '../../colors.dart';

class AddNewPerson {
  static Widget addNew({
    required BuildContext context,
    required Widget action,
    bool isCustomer = false,
  }) {
    final String heroTag = 'newPersonHero_${isCustomer ? "customer" : "supplier"}';

    return Hero(
      tag: heroTag,
      child: UiHelper.myButton(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        callback: () {
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
    );
  }
}

class _AddNewPersonDialog extends StatefulWidget {
  final Widget action;
  final String heroTag;

  const _AddNewPersonDialog({
    super.key,
    required this.action,
    required this.heroTag,
  });

  @override
  State<_AddNewPersonDialog> createState() => _AddNewPersonDialogState();
}

class _AddNewPersonDialogState extends State<_AddNewPersonDialog> {
  bool showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final dialogWidth = isPhone ? (screenWidth - 32) : 450.0;

    return Center(
      child: Hero(
        tag: widget.heroTag,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: showContent
                ? widget.action
                : SizedBox(width: dialogWidth, height: 350),
          ),
        ),
      ),
    );
  }
}
