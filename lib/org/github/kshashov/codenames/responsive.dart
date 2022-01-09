import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double xlWidth = 1500; // max app size
  static const double mdWidth = 1000; // min full layout size
  static const double smWidth = 500; // separate layout
  // static const xsWidth = 250; // mobile mostly
  static final ResponsiveUI xlUI = ResponsiveUI(
      size: ResponsiveSize.xl,
      paddingBig: 20,
      padding: 15,
      paddingSmall: 10,
      radiusBig: 20,
      radius: 15,
      radiusSmall: 10,
      fontSizeBig: 25,
      fontSize: 15,
      fontSizeSmall: 10);
  static final ResponsiveUI mdUI = ResponsiveUI(
      size: ResponsiveSize.md,
      paddingBig: 14,
      padding: 10,
      paddingSmall: 7,
      radiusBig: 14,
      radius: 10,
      radiusSmall: 7,
      fontSizeBig: 20,
      fontSize: 13,
      fontSizeSmall: 9);
  static final ResponsiveUI smUI = ResponsiveUI(
      size: ResponsiveSize.sm,
      paddingBig: 7,
      padding: 5,
      paddingSmall: 3,
      radiusBig: 11,
      radius: 8,
      radiusSmall: 5,
      fontSizeBig: 17,
      fontSize: 12,
      fontSizeSmall: 8);
  static final ResponsiveUI xsUI = ResponsiveUI(
      size: ResponsiveSize.xs,
      paddingBig: 4,
      padding: 3,
      paddingSmall: 2,
      radiusBig: 8,
      radius: 6,
      radiusSmall: 3,
      fontSizeBig: 15,
      fontSize: 12,
      fontSizeSmall: 8);

  // static bool isXl(BuildContext context) {
  //   return MediaQuery.of(context).size.width >= xlWidth;
  // }
  //
  // static bool isMd(BuildContext context) {
  //   return mdWidth <= MediaQuery.of(context).size.width && MediaQuery.of(context).size.width < xlWidth;
  // }
  //
  // static bool isSM(BuildContext context) {
  //   return smWidth <= MediaQuery.of(context).size.width && MediaQuery.of(context).size.width < mdWidth;
  // }
  //
  // static bool isXS(BuildContext context) {
  //   return MediaQuery.of(context).size.width < smWidth;
  // }

  static ResponsiveUI ui(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (width >= xlWidth) {
      return xlUI;
    } else if (width >= mdWidth) {
      return mdUI;
    } else if (width >= smWidth) {
      return smUI;
    } else {
      return xsUI;
    }
  }
}

class ResponsiveUI {
  final double paddingBig;
  final double padding;
  final double paddingSmall;

  final double radiusBig;
  final double radius;
  final double radiusSmall;

  final ResponsiveSize size;

  final double fontSizeBig;
  final double fontSize;
  final double fontSizeSmall;

  ResponsiveUI(
      {required this.size,
      required this.padding,
      required this.paddingBig,
      required this.paddingSmall,
      required this.radiusBig,
      required this.radius,
      required this.radiusSmall,
      required this.fontSizeBig,
      required this.fontSize,
      required this.fontSizeSmall});
}

enum ResponsiveSize { xs, sm, md, xl }
