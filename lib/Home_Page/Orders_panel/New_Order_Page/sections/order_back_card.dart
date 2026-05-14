import 'package:flutter/material.dart';
import '../../../../Shared_Widgets/fonts.dart';
import '../../../../colors.dart';

class OrderBackCard extends StatelessWidget {
  final String heroTag;
  final String title;
  final bool sell;
  final bool editable;
  final bool showDeleteIcon;
  final VoidCallback onPressed;
  final bool wrapInMaterial;

  const OrderBackCard({
    super.key,
    required this.heroTag,
    required this.title,
    required this.sell,
    required this.editable,
    required this.showDeleteIcon,
    required this.onPressed,
    this.wrapInMaterial = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = showDeleteIcon
        ? Icons.delete_outline_rounded
        : Icons.arrow_back;
    final tooltip = editable
        ? "Back"
        : "Order is Confirmed\nYou can safely go Back";

    final content = Container(
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      decoration: BoxDecoration(
        color: sell ? MyColors.primary : MyColors.darkBlue,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(125),
            spreadRadius: 0.5,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Tooltip(
            message: tooltip,
            child: IconButton(
              hoverColor: Colors.white.withAlpha(50),
              onPressed: onPressed,
              icon: Icon(icon, color: MyColors.translucent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: MyFont.semiBold(22, color: MyColors.translucent),
              ),
            ),
          ),
        ],
      ),
    );

    return Hero(
      tag: heroTag,
      child: wrapInMaterial ? Material(color: Colors.transparent, child: content) : content,
    );
  }
}

