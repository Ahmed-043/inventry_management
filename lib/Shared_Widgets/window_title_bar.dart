import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import 'package:inventry_management/colors.dart';
import 'fonts.dart';

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: MyColors.sidebarBg, // You can change this to any color you want
      child: WindowCaption(
        brightness: Brightness.dark,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/app_logo.svg',
              width: 16,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'ODVENTORY',
              style: MyFont.bold(12, color: Colors.white),
            ),
          ],
        ),

      ),
    );
  }
}
