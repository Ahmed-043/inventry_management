import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';

import '../colors.dart';
import 'fonts.dart';

class FilterButton extends StatelessWidget {
  final String title;
  final List<String> options;
  final double width;
  final Future<void> Function(int index) onSelected;

  const FilterButton({
    super.key,
    required this.title,
    required this.options,
    required this.onSelected,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: GestureDetector(
        onTapDown: (details) {
          final tapPosition = details.globalPosition;

          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (_) => Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
                Positioned(
                  left: tapPosition.dx - 10,
                  top: tapPosition.dy + 5,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: Container(
                      width: width,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          options.length,
                              (index) => InkWell(
                            onTap: () async {
                              await onSelected(index);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                options[index],
                                style: MyFont.medium(
                                  14,
                                  color: MyColors.textMain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: MyFont.medium(
                  14,
                  color: MyColors.textMain,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                color: MyColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}