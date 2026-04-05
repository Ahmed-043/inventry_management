import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class HorizontalScroll extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final double speed;
  final bool scrollByWidth;

  const HorizontalScroll({
    super.key,
    required this.child,
    this.controller,
    this.speed = 1.0,
    this.scrollByWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? ScrollController();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent && ctrl.hasClients) {
              final delta = scrollByWidth
                  ? constraints.maxWidth * (event.scrollDelta.dy.sign)
                  : event.scrollDelta.dy * speed;

              ctrl.jumpTo(
                (ctrl.offset + delta)
                    .clamp(0.0, ctrl.position.maxScrollExtent),
              );
            }
          },
          child: SingleChildScrollView(
            controller: ctrl,
            scrollDirection: Axis.horizontal,
            child: child,
          ),
        );
      },
    );
  }
}
