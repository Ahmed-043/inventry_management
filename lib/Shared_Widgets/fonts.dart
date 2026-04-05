import 'package:flutter/material.dart';

class MyFont {
  // Change this to your font family (ensure it's added in pubspec.yaml if custom)
  static const String family = 'Roboto';

  // Provide size every time; color optional
  static TextStyle normal(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle bold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle semiBold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
  );
  static TextStyle italic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle light(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    color: color,
  );
}


class MyFiraFont {
  static const String family = 'FiraSansCondensed';

  static TextStyle thin(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w100,
    color: color,
  );

  static TextStyle extraLight(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w200,
    color: color,
  );

  static TextStyle light(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    color: color,
  );

  static TextStyle regular(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle medium(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle semiBold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle bold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle extraBold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
  );

  static TextStyle black(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: color,
  );
}


class MyFiraSFont {
  static const String family = 'FiraSans';

  static TextStyle thin(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w100,
    color: color,
  );

  static TextStyle thinItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w100,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle extraLight(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w200,
    color: color,
  );

  static TextStyle extraLightItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w200,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle light(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    color: color,
  );

  static TextStyle lightItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle normal(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle italic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle medium(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle mediumItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle semiBold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle semiBoldItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle bold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle boldItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle extraBold(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
  );

  static TextStyle extraBoldItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    color: color,
  );

  static TextStyle black(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: color,
  );

  static TextStyle blackItalic(double size, {Color? color}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    color: color,
  );
}


