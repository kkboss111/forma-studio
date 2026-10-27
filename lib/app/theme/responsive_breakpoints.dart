import 'package:flutter/material.dart';

enum DeviceLayoutType { portraitPhone, landscapePhone, tabletOrDesktop }

enum EditorDensity { adaptive, compact, comfortable }

class FormaResponsive {
  FormaResponsive._();

  static DeviceLayoutType getLayoutType(
    BoxConstraints constraints,
    Orientation orientation,
  ) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    // Only allow tablet/desktop 3-column permanent sidebar layout if BOTH width >= 900 AND height >= 550
    if (width >= 900 && height >= 550) {
      return DeviceLayoutType.tabletOrDesktop;
    } else if (orientation == Orientation.landscape || height < 550) {
      return DeviceLayoutType.landscapePhone;
    } else {
      return DeviceLayoutType.portraitPhone;
    }
  }

  static bool isPhone(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide < 600;
  }

  static bool isTabletOrDesktop(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 900 && size.height >= 550;
  }
}
