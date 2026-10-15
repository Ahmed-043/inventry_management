import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
import '../../colors.dart';

class AddNewProduct {
  static Widget addNew({
    required BuildContext context,
    required Widget action,
  }) {
    return Hero(
      tag: 'newProduct',
      child: UiHelper.myButton(
        callback: () {
          UiHelper.pushPage(
            context: context,
            opaque: false,
            barrierColor: Colors.black54,
            page: _AddNewProductDialog(action: action),
          );
        },
        title: "Add New Product",
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        textSize: 15,
        filled: true,
        borderRadius: 10,
      ),
    );
  }
}

class _AddNewProductDialog extends StatefulWidget {
  final Widget action;
  const _AddNewProductDialog({required this.action});

  @override
  State<_AddNewProductDialog> createState() => _AddNewProductDialogState();
}

class _AddNewProductDialogState extends State<_AddNewProductDialog> {
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
    final dialogWidth = isPhone ? (screenWidth - 32) : 850.0;

    return Center(
      child: Hero(
        tag: 'newProduct',
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: isPhone ? (MediaQuery.of(context).size.height * 0.88) : 800,
              minWidth: isPhone ? 280 : 400,
            ),
            decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: showContent
                ? widget.action
                : SizedBox(
                    width: dialogWidth,
                    height: 680,
                    child: Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: UiHelper.appLogo(),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
