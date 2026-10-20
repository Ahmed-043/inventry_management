import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';

class MobilePageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? actionButton;
  final TextEditingController? searchController;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchCleared;
  final Widget? filterWidget;

  const MobilePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionButton,
    this.searchController,
    this.searchHint = "Search...",
    this.onSearchChanged,
    this.onSearchCleared,
    this.filterWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: MyColors.mainBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Action Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: MyFont.bold(22, color: MyColors.textMain),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: MyFont.medium(12, color: MyColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (actionButton != null) ...[
                const SizedBox(width: 8),
                actionButton!,
              ],
            ],
          ),

          // Row 2: Search Input
          if (searchController != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchController!,
                builder: (context, value, _) {
                  return TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: MyFont.medium(13, color: MyColors.textMain),
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: MyFont.medium(13, color: MyColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, color: MyColors.textSecondary, size: 20),
                      suffixIcon: value.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: MyColors.textSecondary),
                              onPressed: () {
                                searchController!.clear();
                                if (onSearchCleared != null) {
                                  onSearchCleared!();
                                } else if (onSearchChanged != null) {
                                  onSearchChanged!('');
                                }
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  );
                },
              ),
            ),
          ],

          // Row 3: Filter Widget
          if (filterWidget != null) ...[
            const SizedBox(height: 8),
            filterWidget!,
          ],
        ],
      ),
    );
  }
}
