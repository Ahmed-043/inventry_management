import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/colors.dart';
import 'dart:math' as math;

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

class _AppCursorOverlayState extends State<AppCursorOverlay> with TickerProviderStateMixin {
  Offset? _position;
  String? _activeAssetPath;
  bool _isMouseInside = false;
  final GlobalKey _stackKey = GlobalKey();

  final List<_TrailPoint> _trail = [];
  final List<_ClickEffect> _clicks = [];
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final now = DateTime.now();
      bool changed = false;

      if (_trail.isNotEmpty) {
        _trail.removeWhere((p) => now.difference(p.createdAt).inMilliseconds > 400);
        changed = true;
      }

      if (_clicks.isNotEmpty) {
        // Clicks update via their own controllers, but we need to rebuild
        changed = true;
      }

      if (changed) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    for (var click in _clicks) {
      click.controller.dispose();
    }
    super.dispose();
  }

  void _addClick(Offset position) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final click = _ClickEffect(position, controller);
    setState(() {
      _clicks.add(click);
    });
    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _clicks.remove(click);
        });
      }
      controller.dispose();
    });
  }

  void _updatePosition(Offset globalPosition) {
    final renderObject = _stackKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final localPosition = renderObject.globalToLocal(globalPosition);
    setState(() {
      _position = localPosition;
      _activeAssetPath = _resolveCursorAsset(globalPosition);
      _trail.add(_TrailPoint(localPosition));
    });
  }

  void _onMouseExit(PointerExitEvent event) {
    setState(() {
      _isMouseInside = false;
      _position = null;
      _trail.clear();
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
    final renderObject = _stackKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final localPosition = renderObject.globalToLocal(event.position);
    _addClick(localPosition);
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
    if (performanceMode) {
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
              IgnorePointer(
                child: CustomPaint(
                  painter: _TrailPainter(_trail),
                  size: Size.infinite,
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _ClickPainter(_clicks),
                  size: Size.infinite,
                ),
              ),
              Positioned.fill(
                child: MouseRegion(
                  opaque: false,
                  cursor: SystemMouseCursors.none,
                  child: const SizedBox.expand(),
                ),
              ),
              if (_position != null && _isMouseInside)
                Positioned(
                  left: (_position!.dx - (isTextCursor ? (widget.size / 2) : ((widget.size / 2) - 5))),
                  top: (_position!.dy - (widget.size / 2) + 17),
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

class _TrailPoint {
  final Offset position;
  final DateTime createdAt;
  _TrailPoint(this.position) : createdAt = DateTime.now();
}

class _ClickEffect {
  final Offset position;
  final AnimationController controller;
  _ClickEffect(this.position, this.controller);
}

class _TrailPainter extends CustomPainter {
  final List<_TrailPoint> trail;
  _TrailPainter(this.trail);

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.isEmpty) return;
    final now = DateTime.now();
    final paint = Paint()..strokeCap = StrokeCap.round;
    final random = math.Random(42);

    for (int i = 0; i < trail.length; i++) {
      final p = trail[i];
      final age = now.difference(p.createdAt).inMilliseconds;
      final opacity = (1.0 - age / 400.0).clamp(0.0, 1.0);

      // Grained effect: multiple small shapes with slightly random positions
      for (int j = 0; j < 3; j++) {
        final offset = Offset(
          (random.nextDouble() - 0.5) * 10,
          (random.nextDouble() - 0.5) * 10,
        );
        final grainOpacity = opacity * (random.nextDouble() * 0.2 + 0.1);
        paint.color = MyColors.sidebarSelected.withOpacity(grainOpacity);

        final grainSize = random.nextDouble() * 2.0;
        final shapePos = p.position + offset;
        final shapeType = random.nextInt(3);

        if (shapeType == 0) {
          canvas.drawCircle(shapePos, grainSize, paint);
        } else if (shapeType == 1) {
          canvas.drawRect(Rect.fromCenter(center: shapePos, width: grainSize * 2, height: grainSize * 2), paint);
        } else {
          // A tiny diamond/rotated square
          canvas.save();
          canvas.translate(shapePos.dx, shapePos.dy);
          canvas.rotate(math.pi / 4);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: grainSize * 1.5, height: grainSize * 1.5), paint);
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) => true;
}

class _ClickPainter extends CustomPainter {
  final List<_ClickEffect> clicks;
  _ClickPainter(this.clicks);

  @override
  void paint(Canvas canvas, Size size) {
    for (var click in clicks) {
      final progress = click.controller.value;
      // Explosive but soft easing
      final curvedProgress = Curves.easeOutQuart.transform(progress);
      final opacity = (1.0 - progress).clamp(0.0, 0.6);
      
      final random = math.Random(click.position.hashCode + click.controller.hashCode);
      final paint = Paint()..strokeCap = StrokeCap.round;

      // Draw a "burst" of grains with varying shapes
      for (int i = 0; i < 30; i++) {
        final angle = random.nextDouble() * 2 * math.pi;
        final maxRadius = 30.0 * curvedProgress;
        final distance = random.nextDouble() * maxRadius;
        
        final grainOffset = Offset(
          math.cos(angle) * distance,
          math.sin(angle) * distance,
        );
        
        final grainOpacity = opacity * (random.nextDouble() * 0.6 + 0.2);
        paint.color = MyColors.primary.withOpacity(grainOpacity);

        final grainSize = random.nextDouble() * 2.7;
        final shapePos = click.position + grainOffset;
        final shapeType = random.nextInt(4);

        if (shapeType == 0) {
          canvas.drawCircle(shapePos, grainSize, paint);
        } else if (shapeType == 1) {
          canvas.drawRect(Rect.fromCenter(center: shapePos, width: grainSize * 2, height: grainSize * 2), paint);
        } else if (shapeType == 2) {
          // A small cross
          final sw = grainSize * 0.7;
          final p = Paint()
            ..color = paint.color
            ..strokeCap = StrokeCap.round
            ..strokeWidth = sw;
          canvas.drawLine(Offset(shapePos.dx - grainSize, shapePos.dy), Offset(shapePos.dx + grainSize, shapePos.dy), p);
          canvas.drawLine(Offset(shapePos.dx, shapePos.dy - grainSize), Offset(shapePos.dx, shapePos.dy + grainSize), p);
        } else {
          // A small triangle
          final path = Path();
          path.moveTo(shapePos.dx, shapePos.dy - grainSize);
          path.lineTo(shapePos.dx + grainSize, shapePos.dy + grainSize);
          path.lineTo(shapePos.dx - grainSize, shapePos.dy + grainSize);
          path.close();
          canvas.drawPath(path, paint);
        }
      }

      // Central core remains as subtle dots for focus
      // for (int i = 0; i < 5; i++) {
      //   final coreOffset = Offset(
      //     (random.nextDouble() - 0.5) * 10 * (1 - curvedProgress),
      //     (random.nextDouble() - 0.5) * 10 * (1 - curvedProgress),
      //   );
      //   paint.color = MyColors.primary.withOpacity(opacity * 0.8);
      //   canvas.drawCircle(click.position + coreOffset, 5, paint);
      // }
    }
  }

  @override
  bool shouldRepaint(_ClickPainter oldDelegate) => true;
}
