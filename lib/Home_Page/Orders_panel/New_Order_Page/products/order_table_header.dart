import 'package:flutter/material.dart';

class OrderTableHeader extends StatelessWidget {
  final bool showDelete;
  const OrderTableHeader({super.key,this.showDelete = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 30,
            child: Center(
              child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 60),
          const Expanded(
            flex: 4,
            child: Text(
              'Product Name/SKU',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              'Quantity',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'Unit Price',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (showDelete)
            const SizedBox(
            width: 70,
            child: Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

