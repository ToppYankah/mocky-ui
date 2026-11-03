import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_item.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_metrics.dart';

/// Colours and layout for [SlidingPillBottomNavBar].
@immutable
final class SlidingPillNavBarTheme extends ThemeExtension<SlidingPillNavBarTheme> {
  const SlidingPillNavBarTheme({
    required this.barFill,
    required this.barBorder,
    required this.thumbFill,
    required this.itemActive,
    required this.itemInactive,
    required this.focusRingIdle,
    required this.selectedAccent,
    this.metrics = SlidingPillNavBarMetrics.standard,
    this.horizontalPadding = 20,
    this.maxBarWidth = 560,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.barShadow = const [],
    this.barBorderWidth = 1,
    this.labelStyleBuilder,
    this.activeLabelFontWeight = FontWeight.w600,
    this.inactiveLabelFontWeight = FontWeight.w500,
  });

  static const light = SlidingPillNavBarTheme(
    barFill: Color(0xFFFFFFFF),
    barBorder: Color(0xFFE5E5E5),
    thumbFill: Color(0xFFF5F5F5),
    itemActive: Color(0xFF1A1A1A),
    itemInactive: Color(0xFF6B6B6B),
    focusRingIdle: Colors.transparent,
    selectedAccent: Color(0xFF0066CC),
    barShadow: [
      BoxShadow(
        color: Color(0x0F1A1A1A),
        offset: Offset(0, 8),
        blurRadius: 24,
      ),
    ],
  );

  static const dark = SlidingPillNavBarTheme(
    barFill: Color(0xFF1E1E1E),
    barBorder: Color(0xFF3A3A3A),
    thumbFill: Color(0xFF2A2A2A),
    itemActive: Color(0xFFF5F5F5),
    itemInactive: Color(0xFF9E9E9E),
    focusRingIdle: Colors.transparent,
    selectedAccent: Color(0xFF66B3FF),
    barShadow: [],
    barBorderWidth: 1,
  );

  final Color barFill;
  final Color barBorder;
  final Color thumbFill;
  final Color itemActive;
  final Color itemInactive;
  final Color focusRingIdle;
  final Color selectedAccent;
  final SlidingPillNavBarMetrics metrics;
  final double horizontalPadding;
  final double maxBarWidth;
  final BorderRadius borderRadius;
  final List<BoxShadow> barShadow;
  final double barBorderWidth;
  final SlidingPillNavLabelStyleBuilder? labelStyleBuilder;
  final FontWeight activeLabelFontWeight;
  final FontWeight inactiveLabelFontWeight;

  static SlidingPillNavBarTheme of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Theme.of(context).extension<SlidingPillNavBarTheme>() ??
        (brightness == Brightness.dark ? dark : light);
  }

  TextStyle labelStyle(BuildContext context, {required bool active}) {
    if (labelStyleBuilder != null) {
      return labelStyleBuilder!(context, active: active);
    }
    final base = Theme.of(context).textTheme.labelMedium;
    return base!.copyWith(
      fontWeight: active ? activeLabelFontWeight : inactiveLabelFontWeight,
      color: active ? selectedAccent : itemInactive,
    );
  }

  @override
  SlidingPillNavBarTheme copyWith({
    Color? barFill,
    Color? barBorder,
    Color? thumbFill,
    Color? itemActive,
    Color? itemInactive,
    Color? focusRingIdle,
    Color? selectedAccent,
    SlidingPillNavBarMetrics? metrics,
    double? horizontalPadding,
    double? maxBarWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? barShadow,
    double? barBorderWidth,
    SlidingPillNavLabelStyleBuilder? labelStyleBuilder,
    FontWeight? activeLabelFontWeight,
    FontWeight? inactiveLabelFontWeight,
  }) {
    return SlidingPillNavBarTheme(
      barFill: barFill ?? this.barFill,
      barBorder: barBorder ?? this.barBorder,
      thumbFill: thumbFill ?? this.thumbFill,
      itemActive: itemActive ?? this.itemActive,
      itemInactive: itemInactive ?? this.itemInactive,
      focusRingIdle: focusRingIdle ?? this.focusRingIdle,
      selectedAccent: selectedAccent ?? this.selectedAccent,
      metrics: metrics ?? this.metrics,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      maxBarWidth: maxBarWidth ?? this.maxBarWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      barShadow: barShadow ?? this.barShadow,
      barBorderWidth: barBorderWidth ?? this.barBorderWidth,
      labelStyleBuilder: labelStyleBuilder ?? this.labelStyleBuilder,
      activeLabelFontWeight:
          activeLabelFontWeight ?? this.activeLabelFontWeight,
      inactiveLabelFontWeight:
          inactiveLabelFontWeight ?? this.inactiveLabelFontWeight,
    );
  }

  @override
  SlidingPillNavBarTheme lerp(SlidingPillNavBarTheme? other, double t) {
    if (other == null) return this;
    return SlidingPillNavBarTheme(
      barFill: Color.lerp(barFill, other.barFill, t)!,
      barBorder: Color.lerp(barBorder, other.barBorder, t)!,
      thumbFill: Color.lerp(thumbFill, other.thumbFill, t)!,
      itemActive: Color.lerp(itemActive, other.itemActive, t)!,
      itemInactive: Color.lerp(itemInactive, other.itemInactive, t)!,
      focusRingIdle: Color.lerp(focusRingIdle, other.focusRingIdle, t)!,
      selectedAccent: Color.lerp(selectedAccent, other.selectedAccent, t)!,
      metrics: t < 0.5 ? metrics : other.metrics,
      horizontalPadding:
          lerpDouble(horizontalPadding, other.horizontalPadding, t) ??
          horizontalPadding,
      maxBarWidth: lerpDouble(maxBarWidth, other.maxBarWidth, t) ?? maxBarWidth,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t)!,
      barShadow: t < 0.5 ? barShadow : other.barShadow,
      barBorderWidth:
          lerpDouble(barBorderWidth, other.barBorderWidth, t) ??
          barBorderWidth,
      labelStyleBuilder: t < 0.5 ? labelStyleBuilder : other.labelStyleBuilder,
      activeLabelFontWeight: t < 0.5
          ? activeLabelFontWeight
          : other.activeLabelFontWeight,
      inactiveLabelFontWeight: t < 0.5
          ? inactiveLabelFontWeight
          : other.inactiveLabelFontWeight,
    );
  }
}
