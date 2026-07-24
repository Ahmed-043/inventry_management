import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class HorizontalScroll extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final double speed;
  final bool scrollByWidth;
  final bool enableOuterScroll;
  final ScrollPhysics? physics;

  const HorizontalScroll({
    super.key,
    required this.child,
    this.controller,
    this.speed = 1.0,
    this.scrollByWidth = false,
    this.enableOuterScroll = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? ScrollController();

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent && ctrl.hasClients) {
              final delta = scrollByWidth
                  ? constraints.maxWidth * (event.scrollDelta.dy.sign)
                  : event.scrollDelta.dy * speed;

              ctrl.jumpTo(
                (ctrl.offset + delta).clamp(0.0, ctrl.position.maxScrollExtent),
              );
            }
          },
          child: enableOuterScroll
              ? SingleChildScrollView(
                  controller: ctrl,
                  scrollDirection: Axis.horizontal,
                  physics: physics,
                  child: child,
                )
              : child,
        );
      },
    );

    if (physics != null) {
      content = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(physics: physics),
        child: content,
      );
    }

    return content;
  }
}
