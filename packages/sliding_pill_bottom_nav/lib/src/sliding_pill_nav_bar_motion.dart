import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Motion springs and durations for the bottom nav bar.
@immutable
final class SlidingPillNavBarMotion extends ThemeExtension<SlidingPillNavBarMotion> {
  SlidingPillNavBarMotion({
    this.short = const Duration(milliseconds: 200),
    SpringDescription? standard,
    SpringDescription? snappy,
    SpringDescription? interactive,
    SpringDescription? follow,
    SpringDescription? wobble,
  }) : standard = standard ?? _spring(350, 0),
       snappy = snappy ?? _spring(250, 0.1),
       interactive = interactive ?? _spring(300, 0.15),
       follow = follow ?? _spring(280, 0.1),
       wobble = wobble ?? _spring(320, 0.15);

  static SpringDescription _spring(int ms, double bounce) =>
      SpringDescription.withDurationAndBounce(
        duration: Duration(milliseconds: ms),
        bounce: bounce,
      );

  static final SlidingPillNavBarMotion regular = SlidingPillNavBarMotion();

  final Duration short;
  final SpringDescription standard;
  final SpringDescription snappy;
  final SpringDescription interactive;
  final SpringDescription follow;
  final SpringDescription wobble;

  static SlidingPillNavBarMotion of(BuildContext context) {
    return Theme.of(context).extension<SlidingPillNavBarMotion>() ??
        regular;
  }

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      PlatformDispatcher.instance.accessibilityFeatures.reduceMotion;

  @override
  SlidingPillNavBarMotion copyWith({
    Duration? short,
    SpringDescription? standard,
    SpringDescription? snappy,
    SpringDescription? interactive,
    SpringDescription? follow,
    SpringDescription? wobble,
  }) {
    return SlidingPillNavBarMotion(
      short: short ?? this.short,
      standard: standard ?? this.standard,
      snappy: snappy ?? this.snappy,
      interactive: interactive ?? this.interactive,
      follow: follow ?? this.follow,
      wobble: wobble ?? this.wobble,
    );
  }

  @override
  SlidingPillNavBarMotion lerp(SlidingPillNavBarMotion? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
