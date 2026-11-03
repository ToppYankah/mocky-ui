import 'package:flutter/material.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';

/// Test themes aligned with Iris nav bar tokens for stable layout tests.
abstract final class NavBarTestTheme {
  static const _accent = Color(0xFF54ACF6);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseText = Typography.material2021().black.apply(
      bodyColor: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF111111),
      displayColor: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF111111),
    );
    final textTheme = baseText.copyWith(
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 12 * -0.0025,
      ),
    );

    final nav = (isDark ? SlidingPillNavBarTheme.dark : SlidingPillNavBarTheme.light)
        .copyWith(
          selectedAccent: _accent,
          activeIconColor: _accent,
          barFill: isDark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFFFFFFF),
          barBorder: isDark
              ? const Color(0xFF3A3A3A)
              : const Color(0xFFE8E8EB),
          thumbFill: isDark
              ? const Color(0xFF262626)
              : const Color(0xFFF2F2F2),
          itemActive: isDark
              ? const Color(0xFFFAFAFA)
              : const Color(0xFF111111),
          itemInactive: isDark
              ? const Color(0xFF939393)
              : const Color(0xFF696969),
          barShadow: isDark
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x0F111111),
                    offset: Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
          labelStyleBuilder: (context, {required bool active}) {
            final base = textTheme.labelMedium!;
            return base.copyWith(
              fontFamily: 'Inter',
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active
                  ? Theme.of(context).extension<SlidingPillNavBarTheme>()!
                        .selectedAccent
                  : Theme.of(context).extension<SlidingPillNavBarTheme>()!
                        .itemInactive,
            );
          },
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF141414) : Colors.white,
      fontFamily: 'Inter',
      textTheme: textTheme,
      extensions: [nav, SlidingPillNavBarMotion.regular],
    );
  }
}
