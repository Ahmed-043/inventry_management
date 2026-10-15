import 'package:flutter/material.dart';

/// Defines the target hardware device/screen layout type.
enum AppDeviceType {
  /// Phone screen layout (< 600px width or narrow handheld screen)
  phone,

  /// Cube / Tablet screen layout (600px - 1024px width or ~1:1 square/foldable screen)
  cube,

  /// Desktop / wide screen layout (>= 1024px width)
  desktop,
}

/// Central responsive utility providing a single source of truth for screen layout decisions.
class Responsive {
  /// Evaluates and returns the [AppDeviceType] for the given [BuildContext].
  static AppDeviceType getDeviceType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final aspectRatio = height > 0 ? width / height : 1.0;

    // Cube / Foldable / Tablet detection
    if (width >= 600 && width < 1024) {
      return AppDeviceType.cube;
    }

    if (width < 600) {
      // Check for compact square ratio (e.g. folded/unfolded dual screen or cube display)
      if (aspectRatio >= 0.88 && aspectRatio <= 1.15) {
        return AppDeviceType.cube;
      }
      return AppDeviceType.phone;
    }

    return AppDeviceType.desktop;
  }

  static bool isPhone(BuildContext context) => getDeviceType(context) == AppDeviceType.phone;
  static bool isCube(BuildContext context) => getDeviceType(context) == AppDeviceType.cube;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == AppDeviceType.desktop;
  static bool isCompact(BuildContext context) => isPhone(context) || isCube(context);
}

/// Extension on [BuildContext] for concise responsive getters across all UI widgets.
extension ResponsiveContext on BuildContext {
  AppDeviceType get deviceType => Responsive.getDeviceType(this);
  bool get isPhone => Responsive.isPhone(this);
  bool get isCube => Responsive.isCube(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isCompact => Responsive.isCompact(this);
}
