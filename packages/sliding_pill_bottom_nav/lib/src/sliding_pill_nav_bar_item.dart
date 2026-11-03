import 'package:flutter/material.dart';

/// Visual state passed to [SlidingPillNavBarItem.iconBuilder].
@immutable
class SlidingPillNavItemVisualState {
  const SlidingPillNavItemVisualState({
    required this.active,
    required this.color,
    required this.iconSize,
    this.activeIcon,
    this.inactiveIcon,
  });

  final bool active;
  final Color color;
  final double iconSize;

  /// Resolved [IconData] for the current [active] state, when using icons.
  final IconData? activeIcon;
  final IconData? inactiveIcon;

  IconData? get icon =>
      active ? (activeIcon ?? inactiveIcon) : (inactiveIcon ?? activeIcon);
}

typedef SlidingPillNavIconBuilder =
    Widget Function(
      BuildContext context,
      SlidingPillNavItemVisualState state,
    );

typedef SlidingPillNavLabelStyleBuilder =
    TextStyle Function(BuildContext context, {required bool active});

/// One destination in [SlidingPillBottomNavBar].
@immutable
class SlidingPillNavBarItem {
  const SlidingPillNavBarItem({
    required this.label,
    required this.semanticLabel,
    this.icon,
    this.activeIcon,
    this.inactiveIcon,
    this.activeIconColor,
    this.inactiveIconColor,
    this.iconBuilder,
    this.labelStyle,
    this.key,
  }) : assert(
         iconBuilder != null ||
             icon != null ||
             activeIcon != null ||
             inactiveIcon != null,
         'Provide iconBuilder, icon, or activeIcon/inactiveIcon',
       );

  final String label;
  final String semanticLabel;
  final IconData? icon;
  final IconData? activeIcon;
  final IconData? inactiveIcon;
  final Color? activeIconColor;
  final Color? inactiveIconColor;
  final SlidingPillNavIconBuilder? iconBuilder;
  final TextStyle? labelStyle;
  final Key? key;

  IconData iconFor({required bool active}) {
    if (active) {
      return activeIcon ?? icon ?? inactiveIcon!;
    }
    return inactiveIcon ?? icon ?? activeIcon!;
  }
}
