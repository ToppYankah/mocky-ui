import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_metrics.dart';

/// Whether labels fit in equal slots at the current width and text scale.
bool labelsFitSlots(
  List<double> labelWidths,
  double slotWidth,
  SlidingPillNavBarMetrics metrics,
) {
  if (labelWidths.isEmpty) return true;
  final gap = metrics.labelMinGap;
  for (var i = 0; i + 1 < labelWidths.length; i++) {
    if ((labelWidths[i] + labelWidths[i + 1]) / 2 + gap > slotWidth) {
      return false;
    }
  }
  final endRoom = metrics.itemOverhang;
  return labelWidths.first / 2 <= slotWidth / 2 + endRoom &&
      labelWidths.last / 2 <= slotWidth / 2 + endRoom;
}
