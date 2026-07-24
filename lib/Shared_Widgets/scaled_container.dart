import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/app_cursor_overlay.dart';

import '../Database/database.dart';

class ScaledContainer extends StatefulWidget {
  final Widget child;
  final double scale;
  const ScaledContainer({super.key,required this.child,this.scale = 1.05});

  @override
  State<ScaledContainer> createState() => _ScaledContainerState();
}

class _ScaledContainerState extends State<ScaledContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if(performanceMode) {
      return Material(
        color: Colors.transparent,
        child: widget.child,
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
        isClickable =true;
      }),
      onExit: (_) => setState((){
        _isHovered = false;
        isClickable = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? widget.scale : 1.0),
        transformAlignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }

}
