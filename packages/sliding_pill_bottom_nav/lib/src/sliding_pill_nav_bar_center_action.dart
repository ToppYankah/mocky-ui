import 'package:flutter/material.dart';

/// A circular action button rendered in the centre of
/// `SlidingPillBottomNavBar`, between the two halves of its items.
///
/// The action is not a destination: pressing it calls [onPressed] and never
/// changes the selected item. The sliding thumb and drag gesture skip its
/// slot and land on the items either side.
///
/// It can only be used when the bar has an **even** number of items, so they
/// split evenly to its left and right; an odd count fails an assertion.
///
/// The circle is larger than the bar ([diameter] defaults to the bar height
/// plus 8), so it pokes past the bar's top and bottom edges. The bar's
/// outline morphs around it: a cradle of radius `diameter / 2 + cradleGap`
/// wraps the circle and blends into the pill with smooth fillets of radius
/// [cradleSmoothing]. The bar's fill, border, and shadow follow that shape.
@immutable
class SlidingPillNavBarCenterAction {
  const SlidingPillNavBarCenterAction({
    required this.onPressed,
    required this.semanticLabel,
    this.icon,
    this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.diameter,
    this.iconSize = 28,
    this.elevation = 4,
    this.shadowColor,
    this.cradleGap = 6,
    this.cradleSmoothing = 12,
    this.focusNode,
    this.key,
  }) : assert(
         icon != null || child != null,
         'SlidingPillNavBarCenterAction needs an icon or a child',
       ),
       assert(
         diameter == null || diameter > 0,
         'SlidingPillNavBarCenterAction.diameter must be positive',
       ),
       assert(cradleGap >= 0, 'cradleGap must not be negative'),
       assert(cradleSmoothing >= 0, 'cradleSmoothing must not be negative');

  /// Called when the button is tapped or activated from the keyboard.
  /// When null the button is shown disabled.
  final VoidCallback? onPressed;

  /// Accessibility label announced for the button, e.g. "New payment".
  final String semanticLabel;

  /// Icon drawn in [foregroundColor]. Ignored when [child] is set.
  final IconData? icon;

  /// Custom content for the circle; replaces [icon].
  final Widget? child;

  /// Optional tooltip shown on long press / hover.
  final String? tooltip;

  /// Solid fill of the circle. Defaults to the nav theme's `selectedAccent`.
  final Color? backgroundColor;

  /// Icon colour. Defaults to white or black, whichever contrasts with
  /// [backgroundColor].
  final Color? foregroundColor;

  /// Circle diameter. Defaults to `metrics.barHeight + 8`. Values larger
  /// than the bar height make the circle protrude past the bar.
  final double? diameter;

  /// Size of [icon].
  final double iconSize;

  /// Material elevation of the circle (its drop shadow). Use 0 for none.
  final double elevation;

  /// Shadow colour for [elevation]. Defaults to the theme's shadow colour.
  final Color? shadowColor;

  /// Space between the circle and the bar outline wrapped around it.
  final double cradleGap;

  /// Radius of the fillets that blend the cradle into the pill's edges.
  /// 0 gives a sharp join.
  final double cradleSmoothing;

  /// Optional focus node for the button.
  final FocusNode? focusNode;

  /// Key for the button widget, handy in tests.
  final Key? key;

  /// The resolved diameter for a bar of [barHeight].
  double resolveDiameter(double barHeight) => diameter ?? barHeight + 8;
}
