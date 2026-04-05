import 'package:flutter/material.dart';

class BlinkingCursor extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Duration duration;

  const BlinkingCursor({
    super.key,
    this.width = 2,
    this.height = 20,
    this.color = Colors.black,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // 0 → visible, 1 → invisible
        final visible = _controller.value < 0.5;
        return Visibility(
          visible: visible,
          child: Container(
            width: widget.width,
            height: widget.height,
            color: widget.color,
          ),
        );
      },
    );
  }
}
