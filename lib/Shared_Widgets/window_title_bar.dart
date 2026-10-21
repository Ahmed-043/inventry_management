import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import 'package:inventry_management/colors.dart';
import 'fonts.dart';

class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({super.key});

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isFullScreen = false;
  bool _isMaximized = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkWindowState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkWindowState() async {
    final isFS = await windowManager.isFullScreen();
    final isMax = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isFullScreen = isFS;
        _isMaximized = isMax;
      });
    }
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) {
      setState(() {
        _isFullScreen = true;
      });
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) {
      setState(() {
        _isFullScreen = false;
      });
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = true;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() {
        _isMaximized = false;
      });
    }
  }

  Future<void> _toggleFullScreen() async {
    final isFS = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFS);
    if (mounted) {
      setState(() {
        _isFullScreen = !isFS;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 32,
          color: MyColors.sidebarBg,
          child: Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: Container(
                    height: double.infinity,
                    alignment: Alignment.centerLeft,
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/app_logo.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ODVENTORY',
                          style: MyFont.bold(12, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isFullScreen) ...[
                if (_isHovered)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 18,
                    icon: const Icon(
                      Icons.fullscreen_exit_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFullScreen,
                  ),
              ] else ...[
                if (_isMaximized)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 18,
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFullScreen,
                  ),
                WindowCaptionButton.minimize(
                  brightness: Brightness.dark,
                  onPressed: () => windowManager.minimize(),
                ),
                WindowCaptionButton.maximize(
                  brightness: Brightness.dark,
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  },
                ),
                WindowCaptionButton.close(
                  brightness: Brightness.dark,
                  onPressed: () => windowManager.close(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
