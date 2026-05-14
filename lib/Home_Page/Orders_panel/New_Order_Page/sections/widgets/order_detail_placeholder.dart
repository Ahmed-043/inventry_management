import 'package:flutter/material.dart';

import '../../../../../colors.dart';

class OrderDetailPlaceholder extends StatelessWidget {
  const OrderDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionTitle(),
        const SizedBox(height: 6),
        _cardPlaceholder(height: 120),
        _statusCardPlaceholder(height: 140),
        _statusCardPlaceholder(height: 120),
      ],
    );
  }

  Widget _sectionTitle() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 18,
        width: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _cardPlaceholder({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MyColors.lightGrey.withAlpha(60),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(width: 140, height: 12),
          const SizedBox(height: 10),
          _line(width: 200, height: 16),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _line(width: double.infinity, height: 40)),
              const SizedBox(width: 10),
              Expanded(child: _line(width: double.infinity, height: 40)),
            ],
          ),
          const SizedBox(height: 10),

        ],
      ),
    );
  }
  Widget _statusCardPlaceholder({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: MyColors.lightGrey.withAlpha(60),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(width: 140, height: 12),
          const SizedBox(height: 10),
          _line(width: 200, height: 16),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _line(width: double.infinity, height: 26)),
              const SizedBox(width: 10),
              Expanded(child: _line(width: double.infinity, height: 26)),
              const SizedBox(width: 10),
              Expanded(child: _line(width: double.infinity, height: 26)),
            ],
          ),
          const SizedBox(height: 10),

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
}

