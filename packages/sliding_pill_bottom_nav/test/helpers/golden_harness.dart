import 'package:flutter/material.dart';
import 'nav_bar_test_theme.dart';

Widget goldenHarness(
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
  double width = 320,
  double height = 640,
  double textScale = 1,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: NavBarTestTheme.light(),
        darkTheme: NavBarTestTheme.dark(),
        themeMode: themeMode,
        home: child,
      ),
    ),
  );
}
