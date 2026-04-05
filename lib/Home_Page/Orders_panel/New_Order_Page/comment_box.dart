import 'package:flutter/material.dart';
import 'package:inventry_management/Database/orders.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

import '../../../Shared_Widgets/fonts.dart';

class CommentBox extends StatefulWidget {
  final VoidCallback onChange;
  final Order order;
  const CommentBox({super.key, required this.onChange,required this.order});

  @override
  State<CommentBox> createState() => _CommentBoxState();
}

class _CommentBoxState extends State<CommentBox> {
  late TextEditingController controller = TextEditingController(text: widget.order.remark);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
     // height: 200,
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      margin: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        borderRadius: BorderRadius.all(Radius.circular(20)),
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
        padding: const EdgeInsets.only(top: 5,left: 5,right: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Remarks / Comments",
              textAlign: TextAlign.start,
              style: MyFont.semiBold(20, color: MyColors.darkBlue),
            ),
            UiHelper.myTextArea(controller: controller,
                label: "Add a comment",
                hint: "Type your comment here",
                //focusNode: focusNode,
                maxLines: 5,
                readOnly: !(widget.order.orderStatus != 'Completed' || widget.order.update),
                fontSize: 16,
                onChanged: () {
                  widget.order.remark = controller.text;
                  if(widget.order.orderStatus != 'Completed' && !widget.order.editable){
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
