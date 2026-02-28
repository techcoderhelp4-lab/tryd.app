import 'package:flutter/material.dart';

/// Device size categories for responsive design
enum DeviceSize { small, medium, large, tablet }

/// Responsive utility class for scaling fonts and sizes based on device
class ResponsiveUtils {
  /// Get the device size category based on screen width
  static DeviceSize getDeviceSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 360) {
      return DeviceSize.small;
    } else if (width < 414) {
      return DeviceSize.medium;
    } else if (width < 600) {
      return DeviceSize.large;
    } else {
      return DeviceSize.tablet;
    }
  }

  /// Get font scale multiplier based on device size
  static double getFontScale(BuildContext context) {
    final deviceSize = getDeviceSize(context);

    switch (deviceSize) {
      case DeviceSize.small:
        return 0.85;
      case DeviceSize.medium:
        return 1.0;
      case DeviceSize.large:
        return 1.05;
      case DeviceSize.tablet:
        return 1.15;
    }
  }

  /// Get responsive font size
  static double responsiveFont(BuildContext context, double baseSize) {
    return baseSize * getFontScale(context);
  }

  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    return getDeviceSize(context) == DeviceSize.tablet;
  }

  /// Check if device is small
  static bool isSmall(BuildContext context) {
    return getDeviceSize(context) == DeviceSize.small;
  }
}

/// Extension on BuildContext for easy access to responsive methods
extension ResponsiveContext on BuildContext {
  DeviceSize get deviceSize => ResponsiveUtils.getDeviceSize(this);
  double get fontScale => ResponsiveUtils.getFontScale(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isSmall => ResponsiveUtils.isSmall(this);

  /// Get responsive font size
  double rf(double baseSize) => ResponsiveUtils.responsiveFont(this, baseSize);
}

/// Extension on num for responsive font sizing
extension ResponsiveFont on num {
  /// Convert to responsive font size using context
  double rf(BuildContext context) => ResponsiveUtils.responsiveFont(context, toDouble());
}
