import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

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
  final GlobalKey _trackingRegionKey = GlobalKey();
  final GlobalKey _hideCursorRegionKey = GlobalKey();

  void _updatePosition(PointerEvent event) {
    setState(() {
      _position = event.position;
      _activeAssetPath = _resolveCursorAsset(event.position);
    });
  }

  String _resolveCursorAsset(Offset position) {
    final cursor = _hitTestCursor(position);
    if (cursor == SystemMouseCursors.text && widget.textCursorAssetPath != null) {
      return widget.textCursorAssetPath!;
    }
    if (cursor == SystemMouseCursors.click && widget.clickCursorAssetPath != null) {
      return widget.clickCursorAssetPath!;
    }
    return widget.assetPath;
  }

  MouseCursor _hitTestCursor(Offset position) {
    final result = HitTestResult();
    RendererBinding.instance.hitTest(result, position);
    final trackingRender = _trackingRegionKey.currentContext?.findRenderObject();
    final hideRender = _hideCursorRegionKey.currentContext?.findRenderObject();
    var hasClickableTarget = false;
    for (final entry in result.path) {
      final target = entry.target;
      if (target == trackingRender || target == hideRender) {
        continue;
      }
      if (target is RenderEditable) {
        return SystemMouseCursors.text;
      }
      if (target is MouseTrackerAnnotation) {
        final annotation = target as MouseTrackerAnnotation;
        final resolved = _resolveMouseCursor(annotation.cursor);
        if (_isTextCursor(resolved)) {
          return SystemMouseCursors.text;
        }
        if (_isClickCursor(resolved)) {
          return SystemMouseCursors.click;
        }
        if (!_isBasicCursor(resolved)) {
          return resolved;
        }
      }
      if (target is RenderSemanticsGestureHandler) {
        if (target.onTap != null || target.onLongPress != null) {
          hasClickableTarget = true;
        }
      }
    }
    return hasClickableTarget ? SystemMouseCursors.click : SystemMouseCursors.basic;
  }

  MouseCursor _resolveMouseCursor(MouseCursor cursor) {
    if (cursor is MaterialStateMouseCursor) {
      return cursor.resolve(<MaterialState>{MaterialState.hovered});
    }
    return cursor;
  }

  bool _isBasicCursor(MouseCursor cursor) {
    return cursor is SystemMouseCursor && cursor.kind == SystemMouseCursors.basic.kind;
  }

  bool _isClickCursor(MouseCursor cursor) {
    return cursor is SystemMouseCursor && cursor.kind == SystemMouseCursors.click.kind;
  }

  bool _isTextCursor(MouseCursor cursor) {
    return cursor is SystemMouseCursor && cursor.kind == SystemMouseCursors.text.kind;
  }

  @override
  Widget build(BuildContext context) {
    final cursorAsset = _activeAssetPath ?? widget.assetPath;
    return MouseRegion(
      key: _trackingRegionKey,
      opaque: false,
      cursor: SystemMouseCursors.none,
      onHover: _updatePosition,
      onEnter: _updatePosition,
      child: Stack(
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
          if (_position != null)
            Positioned(
              left: (_position!.dx - (widget.size / 2) + 10), // correction for better alignment
              top: (_position!.dy - (widget.size / 2) + 15), // correction for better alignment
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
    );
  }
}
