import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:inventry_management/Database/database.dart';

bool isClickable = false,isTextCursor = false;

/// Draws a custom SVG cursor that follows the mouse pointer.
class AppCursorOverlay extends StatefulWidget {
  final Widget child;
  final String assetPath;
  final String? clickCursorAssetPath;
  final String? textCursorAssetPath;
  final double size;

  const AppCursorOverlay({
    super.key,
    required this.child,
    required this.assetPath,
    this.clickCursorAssetPath,
    this.textCursorAssetPath,
    this.size = 24.0,
  });

  @override
  State<AppCursorOverlay> createState() => _AppCursorOverlayState();
}

class _AppCursorOverlayState extends State<AppCursorOverlay> {
  Offset? _position;
  String? _activeAssetPath;
  bool _isMouseInside = false;
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _trackingRegionKey = GlobalKey();
  final GlobalKey _hideCursorRegionKey = GlobalKey();

  void _updatePosition(Offset globalPosition) {
    final renderObject = _stackKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    setState(() {
      _position = renderObject.globalToLocal(globalPosition);
      _activeAssetPath = _resolveCursorAsset(globalPosition);
    });
  }

  void _onMouseExit(PointerExitEvent event) {
    setState(() {
      _isMouseInside = false;
      _position = null;
    });
  }

  void _onMouseEnter(PointerEnterEvent event) {
    setState(() {
      _isMouseInside = true;
      _updatePosition(event.position);
    });
  }

  void _onMouseHover(PointerHoverEvent event) {
    if (!_isMouseInside) {
      setState(() {
        _isMouseInside = true;
      });
    }
    _updatePosition(event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _updatePosition(event.position);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _updatePosition(event.position);
  }

  void _handlePointerUp(PointerUpEvent event) {
    _updatePosition(event.position);
  }

  String _resolveCursorAsset(Offset position) {
    if (isTextCursor) {
      return widget.textCursorAssetPath ?? widget.assetPath;
    } else if (isClickable) {
      return widget.clickCursorAssetPath ?? widget.assetPath;
    } else {
      return widget.assetPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    if(performanceMode) {
      return widget.child;
    } else {
      final cursorAsset = _activeAssetPath ?? widget.assetPath;
      return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: MouseRegion(
        cursor: SystemMouseCursors.none,
        onEnter: _onMouseEnter,
        onHover: _onMouseHover,
        onExit: _onMouseExit,
        child: Stack(
          key: _stackKey,
          fit: StackFit.expand,
          children: [
            widget.child,
            Positioned.fill(
              child: MouseRegion(
                key: _hideCursorRegionKey,
                opaque: false,
                cursor: SystemMouseCursors.none,
                child: const SizedBox.expand(),
              ),
            ),
            if (_position != null && _isMouseInside)
              Positioned(
                left: (_position!.dx - ( isTextCursor ? (widget.size / 2) : ((widget.size / 2)-5))),
                top: (_position!.dy - (widget.size / 2)+17),
                child: IgnorePointer(
                  child: Image.asset(
                    cursorAsset,
                    width: widget.size,
                    height: widget.size,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    }
  }
}
