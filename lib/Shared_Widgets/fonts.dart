import 'package:flutter/material.dart';

class MyFont {
  // Change this to your font family (ensure it's added in pubspec.yaml if custom)
  static const String family = 'Roboto';

  // Provide size every time; color optional
  static TextStyle normal(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );
  static TextStyle medium(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );

  static TextStyle bold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: height,
  );

  static TextStyle semiBold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    height: height,
  );
  static TextStyle italic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );

  static TextStyle light(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    color: color,
    height: height,
  );
}


class MyFiraFont {
  static const String family = 'FiraSansCondensed';

  static TextStyle thin(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w100,
    color: color,
    height: height,
  );

  static TextStyle extraLight(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w200,
    color: color,
    height: height,
  );

  static TextStyle light(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    color: color,
    height: height,
  );

  static TextStyle regular(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );

  static TextStyle medium(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    height: height,
  );

  static TextStyle semiBold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    height: height,
  );

  static TextStyle bold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: height,
  );

  static TextStyle extraBold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    height: height,
  );

  static TextStyle black(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: color,
    height: height,
  );
}


class MyFiraSFont {
  static const String family = 'FiraSans';

  static TextStyle thin(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w100,
    color: color,
    height: height,
  );

  static TextStyle thinItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w100,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle extraLight(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w200,
    color: color,
    height: height,
  );

  static TextStyle extraLightItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w200,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle light(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    color: color,
    height: height,
  );

  static TextStyle lightItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle normal(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );

  static TextStyle italic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle medium(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    height: height,
  );

  static TextStyle mediumItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle semiBold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    height: height,
  );

  static TextStyle semiBoldItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle bold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: height,
  );

  static TextStyle boldItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle extraBold(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    height: height,
  );

  static TextStyle extraBoldItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );

  static TextStyle black(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: color,
    height: height,
  );

  static TextStyle blackItalic(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    color: color,
    height: height,
  );
}
