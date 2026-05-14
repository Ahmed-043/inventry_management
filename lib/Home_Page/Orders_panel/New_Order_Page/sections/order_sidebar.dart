import 'package:flutter/material.dart';
import 'package:inventry_management/Database/order_items.dart';
import '../../../../Database/db_info.dart';
import '../../../../Database/orders.dart';
import '../../../../Database/person.dart';

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
  bool get _hasPerson => widget.selectedPerson != null;

  void _handlePersonSelected(Person person) {
    widget.onPersonSelected(person);
    widget.callback.call();
    setState(() {});
  }

  void _handleOrderChanged() {
    setState(() {});
    widget.callback.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPersonCard(),
        if (_hasPerson) _buildDetailsCard(),
        if (_hasPerson) _buildCommentBox(),
      ],
    );
  }

  Widget _buildPersonCard() {
    return OrderPersonCard(
      key: ValueKey('order_person_card_${widget.order.id}'),
      sell: widget.sell,
      person: widget.selectedPerson,
      order: widget.order,
      onPersonSelected: _handlePersonSelected,
    );
  }

  Widget _buildDetailsCard() {
    return OrderDetailsCard(
      key: ValueKey('order_details_card_${widget.order.id}'),
      order: widget.order,
      selectedProducts: widget.selectedProducts,
      onOrderChanged: _handleOrderChanged,
    );
  }

  Widget _buildCommentBox() {
    return CommentBox(
      key: ValueKey('comment_box_${widget.order.id}'),
      order: widget.order,
      onChange: widget.callback,
    );
  }
}
