import 'package:flutter/material.dart';

class ReceiptPlaceholder extends StatelessWidget {
  const ReceiptPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 385,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _circle(48),
          const SizedBox(height: 8),
          _line(width: 140, height: 16),
          const SizedBox(height: 6),
          _line(width: 160, height: 12),
          const SizedBox(height: 10),
          _line(width: 220, height: 10),
          const SizedBox(height: 6),
          _line(width: 180, height: 10),
          const Divider(height: 16),
          _row([
            _line(width: 110, height: 12),
            _line(width: 110, height: 12),
          ]),
          const SizedBox(height: 12),
          _tableHeader(),
          const SizedBox(height: 6),
          _itemRow(),
          const Divider(height: 8),
          _itemRow(),
          const Divider(height: 8),
          _itemRow(),
          const Divider(height: 16),
          _row([
            _line(width: 160, height: 10),
            _line(width: 80, height: 10),
          ]),
          const Divider(height: 16),
          _row([
            _line(width: 80, height: 12),
            _line(width: 90, height: 12),
          ]),
          const SizedBox(height: 6),
          _row([
            _line(width: 110, height: 10),
            _line(width: 90, height: 10),
          ]),
          const SizedBox(height: 6),
          _row([
            _line(width: 120, height: 10),
            _line(width: 90, height: 10),
          ]),
          const SizedBox(height: 12),
          _line(width: 200, height: 16),
          const SizedBox(height: 8),
          _line(width: 220, height: 10),
          const SizedBox(height: 6),
          _line(width: 140, height: 10),
        ],
      ),
    );
  }

  Widget _line({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey.shade200,
      child: Row(
        children: [
          Expanded(child: _line(width: double.infinity, height: 10)),
          const SizedBox(width: 12),
          _line(width: 40, height: 10),
          const SizedBox(width: 12),
          _line(width: 60, height: 10),
          const SizedBox(width: 12),
          _line(width: 60, height: 10),
        ],
      ),
    );
  }

  Widget _itemRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: _line(width: double.infinity, height: 12)),
          const SizedBox(width: 12),
          _line(width: 24, height: 12),
          const SizedBox(width: 12),
          _line(width: 50, height: 12),
          const SizedBox(width: 12),
          _line(width: 60, height: 12),
        ],
      ),
    );
  }
}
