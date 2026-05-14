import 'package:flutter/material.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

import '../../../../Shared_Widgets/fonts.dart';

class CommentBox extends StatefulWidget {
  final VoidCallback onChange;
  final Order order;
  const CommentBox({super.key, required this.onChange,required this.order});

  @override
  State<CommentBox> createState() => _CommentBoxState();
}

class _CommentBoxState extends State<CommentBox> {
  late final TextEditingController controller =
      TextEditingController(text: widget.order.remark);

  bool get _isReadOnly =>
      !(widget.order.orderStatus != 'Completed' || widget.order.update);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(125),
            spreadRadius: 0.5,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 5, left: 5, right: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Remarks / Comments",
              textAlign: TextAlign.start,
              style: MyFont.semiBold(20, color: MyColors.darkBlue),
            ),
            UiHelper.myTextArea(
              controller: controller,
              label: "Add a comment",
              hint: "Type your comment here",
              maxLines: 5,
              readOnly: _isReadOnly,
              fontSize: 16,
              onChanged: () {
                widget.order.remark = controller.text;
                if (widget.order.orderStatus != 'Completed' &&
                    !widget.order.editable) {
                  widget.order.update = true;
                  widget.onChange.call();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
