import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
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
          // Use a PageRouteBuilder for Hero animation instead of showDialog
          UiHelper.pushPage(
            context: context,
            opaque: false,
            barrierColor: Colors.black54,
            page: _AddNewProductDialog(action: action),
          );
          // Navigator.of(context).push(
          //   PageRouteBuilder(
          //     opaque: false, // background remains visible
          //     barrierColor: Colors.black54, // dim background
          //     pageBuilder: (_, __, ___) => _AddNewProductDialog(action: action),
          //   ),
          // );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 18),
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
    return Center(
      child: Hero(
        tag: 'newProduct',
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 850,
              maxHeight: 800,
              minWidth: 400,
            ),
            decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: showContent
                ? widget.action
                : SizedBox(
                    width: 850,
                    height: 680,
                    child: SizedBox(
                      width: 850,
                      height: 680,
                      child: Padding(
                        padding: const EdgeInsets.all(100.0),
                        child: UiHelper.appLogo(),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
