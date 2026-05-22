import 'package:flutter/material.dart';

class ScaledContainer extends StatefulWidget {
  final Widget child;
  const ScaledContainer({super.key,required this.child});

  @override
  State<ScaledContainer> createState() => _ScaledContainerState();
}

class _ScaledContainerState extends State<ScaledContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        transformAlignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }

}
