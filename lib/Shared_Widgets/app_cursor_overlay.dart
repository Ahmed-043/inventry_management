import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Draws a custom SVG cursor that follows the mouse pointer.
class AppCursorOverlay extends StatefulWidget {
  final Widget child;
  final String assetPath;
  final double size;

  const AppCursorOverlay({
    super.key,
    required this.child,
    required this.assetPath,
    this.size = 24.0,
  });

  @override
  State<AppCursorOverlay> createState() => _AppCursorOverlayState();
}

class _AppCursorOverlayState extends State<AppCursorOverlay> {
  Offset? _position;

  void _updatePosition(PointerEvent event) {
    setState(() {
      _position = event.position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: _updatePosition,
      onPointerMove: _updatePosition,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          const Positioned.fill(
            child: MouseRegion(
              opaque: false,
              cursor: SystemMouseCursors.none,
              child: SizedBox.expand(),
            ),
          ),
          if (_position != null)
            Positioned(
              left: (_position!.dx - (widget.size / 2)+10), // correction for better alignment
              top: (_position!.dy - (widget.size / 2)+15), // correction for better alignment
              child: IgnorePointer(
                child: Image.asset(
                  widget.assetPath,
                  width: widget.size,
                  height: widget.size,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

