import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
class AddNewProduct {
  static Widget addNew({required BuildContext context, required Widget action}) {
    return Container(
      height: double.infinity,
      width: 200,
      margin: const EdgeInsets.only(top: 5),
      child: Hero(
        tag: 'newProduct',
        child: UiHelper.myButton(
          callback: () {
            // Use a PageRouteBuilder for Hero animation instead of showDialog
            UiHelper.pushPage(
                context: context,
                opaque: false,
                barrierColor: Colors.black54,
                page: _AddNewProductDialog(action: action));
            // Navigator.of(context).push(
            //   PageRouteBuilder(
            //     opaque: false, // background remains visible
            //     barrierColor: Colors.black54, // dim background
            //     pageBuilder: (_, __, ___) => _AddNewProductDialog(action: action),
            //   ),
            // );
          },
          title: "Add New Product",
          textSize: 15,
          filled: true,
          borderRadius: 10,
        ),
      ),
    );
  }
}

class _AddNewProductDialog extends StatefulWidget {
  final Widget action;
  const _AddNewProductDialog({Key? key, required this.action}) : super(key: key);

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
              maxHeight: 680,
              minWidth: 400,
            ),
            decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: showContent ? widget.action : const SizedBox(width: 850,height: 680),
          ),
        ),
      ),
    );
  }
}


