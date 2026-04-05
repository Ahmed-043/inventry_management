import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';

showDeleteDialog({
  required BuildContext context,
  final String? message,
  VoidCallback? onDeleted,
}) async {

    return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Delete Confirmation",style: MyFont.normal(25),),
      content: Text("Are you sure you want to delete this content?${message ?? ''}",style: MyFont.normal(15)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(), // Cancel
          child: Text("Cancel",style: MyFont.normal(15)),
        ),
        DeleteButton(onDeleted: onDeleted),
      ],
    ),
  );
}

class DeleteButton extends StatefulWidget {
  final VoidCallback? onDeleted;
  const DeleteButton({
    super.key,
    this.onDeleted,
  });

  @override
  State<DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<DeleteButton> {
  int countdown = 5;
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 1));
      if (!mounted) return false; // stop if dialog closed
      if (countdown > 1) {
        setState(() => countdown--);
        return true;
      } else {
        setState(() => countdown = 0);
        return false;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: TextButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(MyColors.error),
        ),
        onPressed: (countdown == 0 && !deleting)
            ? () async {
                setState(() => deleting = true);

                Navigator.of(context).pop();
                widget.onDeleted?.call();
              }
            : null,
        child: Text(
          countdown > 0 ? "Delete ($countdown)" : "Delete",
          style: MyFont.normal(15,color: Colors.white),
        ),
      ),
    );
  }
}
