import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';

class DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ValueChanged<int>? onScroll;
  final Color color;
  final Color textColor;

  const DateButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = MyColors.translucent,
    this.textColor = MyColors.textMain,
    this.onScroll,
  });

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: HoverScroll(
        onScroll: (delta) => onScroll?.call(delta),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: MyColors.lightGrey, width: 1),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: .center,
                mainAxisAlignment: .center,
                children: [
                  Text(
                    label,
                    style: MyFont.medium(14, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, color: MyColors.textSecondary, size: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HoverScroll extends StatefulWidget {
  final Widget child;
  final ValueChanged<int> onScroll;
  const HoverScroll({super.key, required this.child, required this.onScroll});

  @override
  State<HoverScroll> createState() => _HoverScrollState();
}

class _HoverScrollState extends State<HoverScroll> {
  double _accumulator = 0.0;
  static const double _threshold = 40.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => _accumulator = 0.0,
      child: GestureDetector(
        onVerticalDragUpdate: (_) {},
        onHorizontalDragUpdate: (_) {},
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              GestureBinding.instance.pointerSignalResolver.register(pointerSignal, (event) {
                if (event is PointerScrollEvent) {
                  final dy = event.scrollDelta.dy;
                  final dx = event.scrollDelta.dx;
                  _accumulator -= dy;
                  _accumulator += dx;
                  if (_accumulator.abs() >= _threshold) {
                    widget.onScroll(_accumulator > 0 ? 1 : -1);
                    _accumulator = 0;
                  }
                }
              });
            }
          },
          onPointerPanZoomUpdate: (event) {
            final dy = event.panDelta.dy;
            final dx = event.panDelta.dx;
            _accumulator += dy * 2.0;
            _accumulator -= dx * 2.0;
            if (_accumulator.abs() >= _threshold) {
              widget.onScroll(_accumulator > 0 ? 1 : -1);
              _accumulator = 0;
            }
          },
          child: widget.child,
        ),
      ),
    );
  }
}
