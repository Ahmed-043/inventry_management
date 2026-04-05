import 'package:flutter/material.dart';
import 'package:inventry_management/Database/order_items.dart';
import '../../../Database/db_info.dart';
import '../../../Database/orders.dart';
import '../../../Database/person.dart';

import 'comment_box.dart';
import 'order_detail_card.dart';
import 'order_person_card.dart';
class OrderSidebar extends StatefulWidget {
  final VoidCallback callback;
  final Order order;
  final List<OrderItem> selectedProducts;
  final DBInfo info;
  final bool sell;
  final Person? selectedPerson;
  final Function(Person) onPersonSelected;

  const OrderSidebar({
    super.key,
    required this.selectedProducts,
    required this.callback,
    required this.order,
    required this.info,
    this.sell = true,
    required this.selectedPerson,
    required this.onPersonSelected,
  });

  @override
  State<OrderSidebar> createState() => _OrderSidebarState();
}

class _OrderSidebarState extends State<OrderSidebar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OrderPersonCard(
          sell: widget.sell,
          person: widget.selectedPerson,
          order: widget.order,
          onPersonSelected: (person) {
            widget.onPersonSelected(person);   // <-- send back to parent
            widget.callback.call();
            setState(() {});
          },
        ),

        if (widget.selectedPerson != null)
          OrderDetailsCard(
            order: widget.order,
            selectedProducts: widget.selectedProducts,
            onOrderChanged: () {
              setState(() {});
              widget.callback.call();
            },
          ),

        if (widget.selectedPerson != null)
          CommentBox(
            order: widget.order,
            onChange: widget.callback,
          ),
      ],
    );
  }
}

