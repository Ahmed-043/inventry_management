import 'package:flutter/material.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/colors.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';

import 'app_cursor_overlay.dart';

class PaginationBar extends StatefulWidget {
  final int page;
  final int pageSize;
  final int itemCount;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ScrollController? scrollController; // NEW

  const PaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.itemCount,
    this.onNext,
    this.onPrevious,
    this.scrollController, // NEW
  });

  @override
  State<PaginationBar> createState() => _PaginationBarState();
}

class _PaginationBarState extends State<PaginationBar> {
  bool _hover = false;

  void _scrollToTop() {
    if (widget.scrollController != null) {
      widget.scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _hover ? 1.0 : 0.2,
          child: Container(
            margin: const EdgeInsets.only(bottom: 5),
            width: 160,
            height: 40,
            decoration: BoxDecoration(
              color: plainUi ? MyColors.lightestGrey : MyColors.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MouseRegion(
                  onEnter: (_)  {
                    isClickable =true;
                  },
                  onExit: (_) {
                    isClickable = false;
                  },
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.page > 0
                        ? () {
                      widget.onPrevious?.call();
                      _scrollToTop(); // Scroll to top on page change
                    }
                        : null,
                  ),
                ),
                Text(
                  "Page ${widget.page + 1}",
                  style: MyFont.semiBold(15, color: MyColors.black),
                ),
                MouseRegion(
                  onEnter: (_)  {
                    isClickable =true;
                  },
                  onExit: (_) {
                    isClickable = false;
                  },
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: widget.itemCount == widget.pageSize
                        ? () {
                      widget.onNext?.call();
                      _scrollToTop(); // Scroll to top on page change
                    }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

