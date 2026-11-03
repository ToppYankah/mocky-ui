import 'package:flutter/material.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_metrics.dart';

/// Per-build overrides merged on top of [SlidingPillNavBarTheme].
@immutable
class SlidingPillNavBarStyle {
  const SlidingPillNavBarStyle({
    this.horizontalPadding,
    this.maxBarWidth,
    this.metrics,
    this.borderRadius,
    this.barShadow,
    this.barBorderWidth,
  });

  final double? horizontalPadding;
  final double? maxBarWidth;
  final SlidingPillNavBarMetrics? metrics;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? barShadow;
  final double? barBorderWidth;
}
