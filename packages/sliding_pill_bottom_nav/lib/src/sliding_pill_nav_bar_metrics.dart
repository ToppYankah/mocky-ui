import 'package:flutter/material.dart';

/// Geometry of the floating pill and sliding thumb.
@immutable
class SlidingPillNavBarMetrics {
  const SlidingPillNavBarMetrics({
    this.barHeight = 64,
    this.iconSize = 22,
    this.iconLabelGap = 4,
    this.thumbInset = 6,
    this.thumbPaddingH = 16,
    this.itemOverhang = 4,
    this.labelMinGap = 4,
    this.maxStretch = 0.1,
    this.squashRatio = 0.5,
    this.fullStretchSpeed = 1200,
    this.motionStep = 0.004,
    this.motionMaxFrame = 0.05,
    this.motionRestTolerance = 0.001,
    this.fadeExtent = 32,
    this.focusRingWidth = 2,
  });

  static const standard = SlidingPillNavBarMetrics();

  final double barHeight;
  final double iconSize;
  final double iconLabelGap;
  final double thumbInset;
  final double thumbPaddingH;
  final double itemOverhang;
  final double labelMinGap;
  final double maxStretch;
  final double squashRatio;
  final double fullStretchSpeed;
  final double motionStep;
  final double motionMaxFrame;
  final double motionRestTolerance;
  final double fadeExtent;
  final double focusRingWidth;

  double get itemsInsetH => thumbInset + itemOverhang;

  SlidingPillNavBarMetrics copyWith({
    double? barHeight,
    double? iconSize,
    double? iconLabelGap,
    double? thumbInset,
    double? thumbPaddingH,
    double? itemOverhang,
    double? labelMinGap,
    double? maxStretch,
    double? squashRatio,
    double? fullStretchSpeed,
    double? motionStep,
    double? motionMaxFrame,
    double? motionRestTolerance,
    double? fadeExtent,
    double? focusRingWidth,
  }) {
    return SlidingPillNavBarMetrics(
      barHeight: barHeight ?? this.barHeight,
      iconSize: iconSize ?? this.iconSize,
      iconLabelGap: iconLabelGap ?? this.iconLabelGap,
      thumbInset: thumbInset ?? this.thumbInset,
      thumbPaddingH: thumbPaddingH ?? this.thumbPaddingH,
      itemOverhang: itemOverhang ?? this.itemOverhang,
      labelMinGap: labelMinGap ?? this.labelMinGap,
      maxStretch: maxStretch ?? this.maxStretch,
      squashRatio: squashRatio ?? this.squashRatio,
      fullStretchSpeed: fullStretchSpeed ?? this.fullStretchSpeed,
      motionStep: motionStep ?? this.motionStep,
      motionMaxFrame: motionMaxFrame ?? this.motionMaxFrame,
      motionRestTolerance: motionRestTolerance ?? this.motionRestTolerance,
      fadeExtent: fadeExtent ?? this.fadeExtent,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    );
  }
}
