import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:sliding_pill_bottom_nav/src/center_action_cradle.dart';
import 'package:sliding_pill_bottom_nav/src/label_fit.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_center_action.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_item.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_metrics.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_motion.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_style.dart';
import 'package:sliding_pill_bottom_nav/src/sliding_pill_nav_bar_theme.dart';

/// Floating, rounded pill bottom navigation bar with a sliding thumb.
///
/// Behind the pill a gradient runs from the scaffold colour at the screen
/// edge to transparent [_metrics.fadeExtent] above the pill, so
/// content under an extended body fades out before it reaches the bar.
///
/// The selected item's icon and label use `appColors.primaryAccent`, the
/// brand accent for selection; the other items use the nav bar's inactive
/// colour, and the keyboard focus ring keeps the nav bar's active colour.
///
/// The thumb is generous, springy, resizes per label, and can be dragged.
/// While dragged it trails the finger on the `follow` spring and squashes
/// and stretches with its speed on the `wobble` spring; reduced motion
/// glues it to the finger with no wobble.
/// On pointer down the thumb springs to the touched item at once (before
/// the tap or drag is decided); a cancelled press springs it back.
/// It is stateless about routing: callers pass [items] and [selectedIndex]
/// and receive taps and drag releases through [onSelected].
///
/// An optional [centerAction] adds a circular action button in the centre,
/// with the items split evenly either side. It needs an even number of
/// [items]; see [SlidingPillNavBarCenterAction].
class SlidingPillBottomNavBar extends StatefulWidget {
  const SlidingPillBottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.initialThumbPosition,
    this.style,
    this.centerAction,
    super.key,
  }) : assert(
         centerAction == null || items.length % 2 == 0,
         'SlidingPillBottomNavBar.centerAction needs an even number of items '
         'so they split evenly either side of it; got an odd count.',
       );

  final List<SlidingPillNavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Optional circular action button in the centre of the bar. Only allowed
  /// with an even number of [items]. It is not a destination: it never
  /// changes [selectedIndex] or calls [onSelected].
  final SlidingPillNavBarCenterAction? centerAction;

  /// Optional first-frame fractional thumb position. Used by goldens to
  /// capture a mid-drag frame; defaults to [selectedIndex] when null.
  @visibleForTesting
  final double? initialThumbPosition;

  /// Optional overrides merged with [SlidingPillNavBarTheme].
  final SlidingPillNavBarStyle? style;

  @override
  State<SlidingPillBottomNavBar> createState() => _SlidingPillBottomNavBarState();
}

class _SlidingPillBottomNavBarState extends State<SlidingPillBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late final Ticker _motionTicker = createTicker(_onMotionTick);

  /// Horizontal stretch of the thumb (0 = rest, +maxStretch = fully
  /// stretched, small negative values = rebound after a stop).
  final ValueNotifier<double> _stretch = ValueNotifier(0);
  double _stretchVelocity = 0;
  Duration _lastMotionTick = Duration.zero;

  /// Finger position as a fractional item index, during a drag.
  double _fingerValue = 0;

  /// The trailing thumb's position and velocity (items, items/s) while
  /// dragged.
  double _followValue = 0;
  double _followVelocity = 0;
  late List<FocusNode> _focusNodes;
  late List<double> _naturalWidths;
  int _selectedIndex = 0;
  int? _dragActiveIndex;
  bool _dragging = false;

  /// The pointer that pressed the pill and whose tap or drag is still
  /// undecided, or null.
  int? _pressPointer;
  Offset _pressOrigin = Offset.zero;
  double _barWidth = 0;
  double _slotWidth = 0;

  /// Whether every label fits beside its neighbours at the current width
  /// and text scale. When false only the active item shows its label.
  bool _labelsFit = true;

  /// Left edge and width of each item's slot, in pill coordinates. Equal
  /// slots when labels fit; otherwise the active slot widens to hold its
  /// icon and label and the rest share what is left equally.
  List<double> _slotLefts = const [];
  List<double> _slotWidths = const [];

  int get _itemCount => widget.items.length;

  SlidingPillNavBarTheme get _navTheme => SlidingPillNavBarTheme.of(context);

  SlidingPillNavBarMotion get _motionExt => SlidingPillNavBarMotion.of(context);

  SlidingPillNavBarMetrics get _metrics =>
      widget.style?.metrics ?? _navTheme.metrics;

  double get _horizontalPadding =>
      widget.style?.horizontalPadding ?? _navTheme.horizontalPadding;

  double get _maxBarWidth => widget.style?.maxBarWidth ?? _navTheme.maxBarWidth;

  BorderRadius get _borderRadius =>
      widget.style?.borderRadius ?? _navTheme.borderRadius;

  List<BoxShadow> get _barShadow =>
      widget.style?.barShadow ?? _navTheme.barShadow;

  double get _barBorderWidth =>
      widget.style?.barBorderWidth ?? _navTheme.barBorderWidth;

  SlidingPillNavBarCenterAction? get _action => widget.centerAction;

  /// Diameter of the centre action's circle, or 0 without one.
  double get _actionDiameter =>
      _action?.resolveDiameter(_metrics.barHeight) ?? 0;

  /// Radius of the bar outline wrapped around the centre action.
  double get _cradleRadius =>
      _action == null ? 0 : _actionDiameter / 2 + _action!.cradleGap;

  /// How far the cradle reaches past the bar's top and bottom edges.
  double get _cradleProtrusion =>
      math.max(0, _cradleRadius - _metrics.barHeight / 2);

  /// Width of the empty slot the centre action leaves between the items.
  double get _centerGap =>
      _action == null ? 0 : 2 * (_cradleRadius + _metrics.itemOverhang);

  /// Number of items left of the centre action.
  int get _leftCount => _itemCount ~/ 2;


  @override
  void initState() {
    super.initState();
    assert(
      widget.items.length >= 2,
      'SlidingPillBottomNavBar needs at least two items',
    );
    _selectedIndex = widget.selectedIndex;
    _focusNodes = List.generate(_itemCount, (_) => FocusNode());
    _naturalWidths = List.filled(_itemCount, 0);
    _controller = _createController(
      value: widget.initialThumbPosition ?? _selectedIndex.toDouble(),
    );
  }

  AnimationController _createController({required double value}) {
    return AnimationController(
      vsync: this,
      value: value,
      lowerBound: 0,
      upperBound: math.max(0, _itemCount - 1).toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant SlidingPillBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      for (final node in _focusNodes) {
        node.dispose();
      }
      _focusNodes = List.generate(_itemCount, (_) => FocusNode());
      _naturalWidths = List.filled(_itemCount, 0);
      _controller.dispose();
      _controller = _createController(value: widget.selectedIndex.toDouble());
      _selectedIndex = widget.selectedIndex;
    } else if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
      _dragActiveIndex = null;
      _animateTo(
        widget.selectedIndex.toDouble(),
        spring: _motionExt.standard,
      );
    }
  }

  @override
  void dispose() {
    _motionTicker.dispose();
    _stretch.dispose();
    _controller.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _animateTo(
    double target, {
    required SpringDescription spring,
    double velocity = 0,
  }) {
    if (!mounted) return;
    if (SlidingPillNavBarMotion.reduced(context)) {
      _controller.value = target;
      return;
    }
    _controller.animateWith(
      SpringSimulation(spring, _controller.value, target, velocity),
    );
  }

  void _select(int index) {
    _pressPointer = null;
    setState(() {
      _selectedIndex = index;
      _dragActiveIndex = null;
    });
    if (index != _controller.value) {
      // Keeps the velocity of a press already heading there.
      _animateTo(
        index.toDouble(),
        spring: _motionExt.snappy,
        velocity: _controller.isAnimating ? _controller.velocity : 0,
      );
    }
    widget.onSelected(index);
  }

  /// Pointer down: preview the touched item and spring the thumb to it
  /// straight away, without waiting for the gesture arena.
  void _onPointerDown(PointerDownEvent event) {
    if (_pressPointer != null || _dragging) return;
    _pressPointer = event.pointer;
    _pressOrigin = event.localPosition;
    final index = _indexForX(event.localPosition.dx);
    setState(() => _dragActiveIndex = index);
    _animateTo(
      index.toDouble(),
      spring: _motionExt.snappy,
      velocity: _controller.isAnimating ? _controller.velocity : 0,
    );
    if (!SlidingPillNavBarMotion.reduced(context)) _startMotionTicker();
  }

  /// Pointer up or cancel, or the tap lost the arena. Tap-up and drag-start
  /// run in the same event dispatch and clear [_pressPointer], so a press
  /// still pending once the microtask runs was cancelled.
  void _onPressMaybeCancelled() {
    if (_pressPointer == null) return;
    scheduleMicrotask(() {
      if (!mounted || _pressPointer == null || _dragging) return;
      _pressPointer = null;
      setState(() => _dragActiveIndex = null);
      _animateTo(
        _selectedIndex.toDouble(),
        spring: _motionExt.snappy,
        velocity: _controller.isAnimating ? _controller.velocity : 0,
      );
      if (!SlidingPillNavBarMotion.reduced(context)) _startMotionTicker();
    });
  }

  /// Moving past touch slop ends the tap. A horizontal move starts the drag
  /// in the same dispatch; anything else (a vertical scroll) reverts.
  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pressPointer) return;
    final slop = computeHitSlop(
      event.kind,
      MediaQuery.maybeGestureSettingsOf(context),
    );
    if ((event.localPosition - _pressOrigin).distance > slop) {
      _onPressMaybeCancelled();
    }
  }

  void _onPointerEnd(PointerEvent event) {
    if (event.pointer == _pressPointer) _onPressMaybeCancelled();
  }

  /// Points the thumb at the finger. A per-frame spring follower in
  /// [_onMotionTick] then pulls the thumb after it, so it trails slightly
  /// behind. Reduced motion moves the thumb with the finger directly.
  void _followFinger(double fingerValue) {
    _fingerValue = fingerValue;
    if (SlidingPillNavBarMotion.reduced(context)) {
      _controller.value = fingerValue;
      return;
    }
    _startMotionTicker();
  }

  void _startMotionTicker() {
    if (_motionTicker.isActive) return;
    _lastMotionTick = Duration.zero;
    _motionTicker.start();
  }

  /// Advances a damped spring (position [x], velocity [v]) toward [target]
  /// by [dt] seconds with semi-implicit Euler in small steps.
  (double, double) _stepSpring(
    SpringDescription spring,
    double position,
    double velocity,
    double target,
    double dt,
  ) {
    var x = position;
    var v = velocity;
    var remaining = math.min(dt, _metrics.motionMaxFrame);
    while (remaining > 0) {
      final h = math.min(remaining, _metrics.motionStep);
      final a =
          (-spring.stiffness * (x - target) - spring.damping * v) / spring.mass;
      v += a * h;
      x += v * h;
      remaining -= h;
    }
    return (x, v);
  }

  /// One frame of drag motion:
  /// - while dragging, the thumb follows the finger on the `follow` spring
  ///   (re-targeted every frame, keeping its velocity);
  /// - the stretch follows the thumb's speed on the underdamped `wobble`
  ///   spring, so the thumb stretches as it speeds up and settles with a
  ///   small rebound when it slows, stops, or lands after release.
  void _onMotionTick(Duration elapsed) {
    final dt = (elapsed - _lastMotionTick).inMicroseconds / 1e6;
    _lastMotionTick = elapsed;
    if (dt <= 0) return;
    final motion = _motionExt;

    double speed; // thumb speed in items per second
    if (_dragging) {
      final upper = math.max(0, _itemCount - 1).toDouble();
      var (x, v) = _stepSpring(
        motion.follow,
        _followValue,
        _followVelocity,
        _fingerValue,
        dt,
      );
      if (x < 0 || x > upper) {
        x = x.clamp(0.0, upper);
        v = 0;
      }
      _followValue = x;
      _followVelocity = v;
      _controller.value = x;
      speed = v;
    } else if (_controller.isAnimating) {
      speed = _controller.velocity;
    } else {
      speed = 0;
    }

    final target =
        _metrics.maxStretch *
        ((speed * _slotWidth).abs() / _metrics.fullStretchSpeed).clamp(
          0.0,
          1.0,
        );
    final (s, sv) = _stepSpring(
      motion.wobble,
      _stretch.value,
      _stretchVelocity,
      target,
      dt,
    );
    _stretchVelocity = sv;

    final tolerance = _metrics.motionRestTolerance;
    // While held still the thumb rests on the finger; the next drag update
    // restarts the ticker.
    final thumbAtRest = _dragging
        ? (_followValue - _fingerValue).abs() < tolerance &&
              _followVelocity.abs() < tolerance
        : !_controller.isAnimating;
    final settled = thumbAtRest && s.abs() < tolerance && sv.abs() < tolerance;
    if (settled) {
      if (_dragging) {
        _followValue = _fingerValue;
        _followVelocity = 0;
        _controller.value = _fingerValue;
      }
      _stretch.value = 0;
      _stretchVelocity = 0;
      _motionTicker.stop();
      return;
    }
    _stretch.value = s.clamp(
      -_metrics.maxStretch,
      _metrics.maxStretch,
    );
  }

  void _finishDrag({required SpringDescription spring, double velocity = 0}) {
    // The last item the finger reached, not where the trailing thumb is.
    final target = _valueToIndex(_fingerValue);
    setState(() {
      _selectedIndex = target;
      _dragActiveIndex = null;
    });
    _animateTo(target.toDouble(), spring: spring, velocity: velocity);
    // Landing wobble as the thumb springs home.
    if (!SlidingPillNavBarMotion.reduced(context)) _startMotionTicker();
    widget.onSelected(target);
  }

  void _onDragStart(DragStartDetails details) {
    // Continues from wherever the press animation has the thumb.
    _pressPointer = null;
    _followVelocity = _controller.isAnimating ? _controller.velocity : 0;
    _followValue = _controller.value;
    _controller.stop();
    _dragging = true;
    final p = _positionToValue(details.localPosition.dx);
    setState(() => _dragActiveIndex = _valueToIndex(p));
    _followFinger(p);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    _finishDrag(
      spring: _motionExt.interactive,
      velocity: details.velocity.pixelsPerSecond.dx / _slotWidth,
    );
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _finishDrag(spring: _motionExt.snappy);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final p = _positionToValue(details.localPosition.dx);
    setState(() => _dragActiveIndex = _valueToIndex(p));
    _followFinger(p);
  }

  double _slotCentre(int i) => _slotLefts[i] + _slotWidths[i] / 2;

  double _positionToValue(double x) {
    if (x <= _slotCentre(0)) return 0;
    for (var i = 0; i + 1 < _itemCount; i++) {
      final from = _slotCentre(i);
      final to = _slotCentre(i + 1);
      if (x < to) return i + (x - from) / (to - from);
    }
    return _clampValue(_itemCount - 1);
  }

  double _clampValue(double p) {
    final upper = math.max(0, _itemCount - 1).toDouble();
    if (p < 0) return 0;
    if (p > upper) return upper;
    return p;
  }

  int _valueToIndex(double p) => _clampInt((p + 0.5).floor());

  int _indexForX(double x) {
    for (var i = 0; i < _itemCount - 1; i++) {
      // Halfway across any gap (the centre action's slot) to the next item.
      final right = _slotLefts[i] + _slotWidths[i];
      if (x < (right + _slotLefts[i + 1]) / 2) return i;
    }
    return _itemCount - 1;
  }

  /// Centre x of the thumb at fractional position [p], in pill coordinates.
  double _thumbCentre(double p) {
    final i0 = _clampInt(p.floor());
    final i1 = _clampInt(p.ceil());
    final frac = (p - p.floorToDouble()).clamp(0.0, 1.0);
    return _slotCentre(i0) + (_slotCentre(i1) - _slotCentre(i0)) * frac;
  }

  void _computeSlots() {
    if (_action != null) {
      _computeSlotsAroundAction();
      return;
    }
    final rowWidth = _barWidth - 2 * _metrics.itemsInsetH;
    final widths = List.filled(_itemCount, _slotWidth);
    if (!_labelsFit) {
      final active = _dragActiveIndex ?? _selectedIndex;
      // The active slot plus the overhang on each side is the thumb, so
      // the thumb holds the icon and label with thumbPaddingH.
      final activeWidth = math.min(
        _naturalWidths[active] - 2 * _metrics.itemOverhang,
        rowWidth,
      );
      final rest = (rowWidth - activeWidth) / (_itemCount - 1);
      for (var i = 0; i < _itemCount; i++) {
        widths[i] = i == active ? activeWidth : rest;
      }
    }
    final lefts = <double>[];
    var x = _metrics.itemsInsetH;
    for (final w in widths) {
      lefts.add(x);
      x += w;
    }
    _slotLefts = lefts;
    _slotWidths = widths;
  }

  /// Slots with the centre action: each half of the items shares the room
  /// on its side of the action's gap. When labels crowd, the active slot
  /// widens within its own half.
  void _computeSlotsAroundAction() {
    final half = math.max(
      0,
      (_barWidth - 2 * _metrics.itemsInsetH - _centerGap) / 2,
    ).toDouble();
    final widths = List.filled(_itemCount, _slotWidth);
    if (!_labelsFit) {
      final active = _dragActiveIndex ?? _selectedIndex;
      final activeLeft = active < _leftCount;
      final activeWidth = math.min(
        _naturalWidths[active] - 2 * _metrics.itemOverhang,
        half,
      );
      for (var i = 0; i < _itemCount; i++) {
        final sameHalf = (i < _leftCount) == activeLeft;
        if (i == active) {
          widths[i] = activeWidth;
        } else if (sameHalf) {
          widths[i] = (half - activeWidth) / (_leftCount - 1);
        } else {
          widths[i] = half / _leftCount;
        }
      }
    }
    final lefts = <double>[];
    var x = _metrics.itemsInsetH;
    for (var i = 0; i < _itemCount; i++) {
      if (i == _leftCount) x += _centerGap;
      lefts.add(x);
      x += widths[i];
    }
    _slotLefts = lefts;
    _slotWidths = widths;
  }

  int _clampInt(int i) {
    if (i < 0) return 0;
    if (i >= _itemCount) return _itemCount - 1;
    return i;
  }

  bool _isActive(int index) => _dragActiveIndex != null
      ? _dragActiveIndex == index
      : _selectedIndex == index;

  TextStyle _labelStyle(BuildContext context, {required bool active}) {
    return _navTheme.labelStyle(context, active: active);
  }

  double _measureLabel(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  void _computeWidths(BuildContext context) {
    final style = _labelStyle(context, active: true);
    final labelWidths = [
      for (final item in widget.items)
        _measureLabel(context, item.label, style),
    ];
    _labelsFit = labelsFitSlots(labelWidths, _slotWidth, _metrics);
    for (var i = 0; i < _itemCount; i++) {
      final labelWidth = labelWidths[i];
      final contentWidth = math.max(_metrics.iconSize, labelWidth);
      _naturalWidths[i] = math.max(
        contentWidth + 2 * _metrics.thumbPaddingH,
        _slotWidth + 2 * _metrics.itemOverhang,
      );
    }
  }

  double _thumbWidth(double p) {
    final i0 = _clampInt(p.floor());
    final i1 = _clampInt(p.ceil());
    final frac = (p - p.floorToDouble()).clamp(0.0, 1.0);
    final natural =
        _naturalWidths[i0] + (_naturalWidths[i1] - _naturalWidths[i0]) * frac;
    // Never shrink at the ends; only cap at the pill's inner width.
    return math.min(natural, _barWidth - 2 * _metrics.thumbInset);
  }

  /// Left edge of a thumb of [width] at [p]. Centred on the item, shifted
  /// inward only when a wide label would bring it closer than thumbInset
  /// to the pill edge.
  double _thumbLeft(double p, double width) {
    final inset = _metrics.thumbInset;
    final left = _thumbCentre(p) - width / 2;
    return left.clamp(inset, math.max(inset, _barWidth - inset - width));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;

    // The fade sits behind the pill and reaches _metrics.fadeExtent
    // above it. It is part of the bar's size, so with Scaffold.extendBody
    // the body's bottom padding covers the pill and the fade, and the last
    // scrollable item can scroll clear of both. It ignores pointers, and the
    // padding around the pill does not hit-test, so taps there reach the
    // body.
    final hasAction = _action != null;
    final border = isDark
        ? Border.all(color: _navTheme.barBorder, width: _barBorderWidth)
        : Border.all(color: _navTheme.barBorder);
    final content = ClipRRect(
      borderRadius: _borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _barWidth = constraints.maxWidth;
          _slotWidth =
              (_barWidth - 2 * _metrics.itemsInsetH - _centerGap) /
              _itemCount;
          _computeWidths(context);
          _computeSlots();
          return Stack(
            children: [
              _buildThumb(),
              Positioned.fill(
                left: _metrics.itemsInsetH,
                right: _metrics.itemsInsetH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _itemCount; i++) ...[
                      if (hasAction && i == _leftCount)
                        SizedBox(width: _centerGap),
                      SizedBox(
                        width: _slotWidths[i],
                        child: _buildItem(i),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final band = SizedBox(
      key: const ValueKey('app_bottom_nav_pill'),
      width: double.infinity,
      height: _metrics.barHeight,
      // Raw pointer events bypass the arena so a press reacts on down.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerEnd,
        onPointerCancel: _onPointerEnd,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _select(_indexForX(details.localPosition.dx)),
          onTapCancel: _onPressMaybeCancelled,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          // With a centre action the morphed outline is painted around the
          // band instead, so the band itself stays bare.
          child: hasAction
              ? content
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: _navTheme.barFill,
                    borderRadius: _borderRadius,
                    border: border,
                    boxShadow: _barShadow,
                  ),
                  child: content,
                ),
        ),
      ),
    );

    // The cradle pokes past the pill; it takes its room from the padding
    // above and below so the pill stays where it is without an action.
    final protrusion = _cradleProtrusion;
    final pill = Padding(
      // The bottom gap equals the side gap and ignores the safe-area inset,
      // so the pill floats evenly inside the screen corners.
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding,
        math.max(0, _metrics.fadeExtent - protrusion),
        _horizontalPadding,
        math.max(0, _horizontalPadding - protrusion),
      ),
      // Bottom-aligned and sized to the pill: Scaffold.bottomNavigationBar
      // allows the full screen height, so the bar must not expand.
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxBarWidth),
          child: hasAction
              ? _buildWithCenterAction(band, border.top.width, protrusion)
              : band,
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('app_bottom_nav_fade'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [scaffold, scaffold.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        pill,
      ],
    );
  }

  /// The band inside a taller box that also holds the morphed outline and
  /// the centre action. Everything shares one Stack, so the circle's
  /// protruding parts sit inside the box and receive taps.
  Widget _buildWithCenterAction(
    Widget band,
    double borderWidth,
    double protrusion,
  ) {
    final action = _action!;
    final barHeight = _metrics.barHeight;
    final height = barHeight + 2 * protrusion;
    final diameter = _actionDiameter;
    final cradleDiameter = 2 * _cradleRadius;
    return SizedBox(
      key: const ValueKey('app_bottom_nav_center_action_area'),
      width: double.infinity,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('app_bottom_nav_cradle'),
                    painter: CenterActionCradlePainter(
                      band: Rect.fromLTWH(0, protrusion, width, barHeight),
                      borderRadius: _borderRadius,
                      radius: _cradleRadius,
                      smoothing: action.cradleSmoothing,
                      fill: _navTheme.barFill,
                      borderColor: _navTheme.barBorder,
                      borderWidth: borderWidth,
                      shadows: _barShadow,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: protrusion,
                height: barHeight,
                child: band,
              ),
              // The cradle around the circle is part of the action, not the
              // items: presses there neither select nor move the thumb.
              SizedBox.square(
                dimension: cradleDiameter,
                child: const ClipOval(child: AbsorbPointer()),
              ),
              _CenterActionButton(
                action: action,
                diameter: diameter,
                focusRingColor: _navTheme.itemActive,
                focusRingWidth: _metrics.focusRingWidth,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumb() {
    final thumb = RepaintBoundary(
      key: const ValueKey('app_bottom_nav_thumb'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _navTheme.thumbFill,
          borderRadius: _borderRadius,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _stretch]),
      child: thumb,
      builder: (context, child) {
        final inset = _metrics.thumbInset;
        final restHeight = _metrics.barHeight - 2 * inset;
        final p = _clampValue(_controller.value);
        final stretch = _stretch.value;
        // Stretch widens the thumb and squashes it vertically; it never
        // grows taller than at rest, so it keeps thumbInset to the pill.
        final width = math.min(
          _thumbWidth(p) * (1 + stretch),
          _barWidth - 2 * inset,
        );
        final height =
            restHeight *
            (1 - _metrics.squashRatio * math.max(0, stretch));
        return Positioned(
          left: _thumbLeft(p, width),
          top: inset + (restHeight - height) / 2,
          width: width,
          height: height,
          child: child!,
        );
      },
    );
  }


  Widget _buildIcon(SlidingPillNavBarItem item, bool active) {
    final size = _metrics.iconSize;
    final color = active
        ? (item.activeIconColor ?? _navTheme.iconColor(active: true))
        : (item.inactiveIconColor ?? _navTheme.iconColor(active: false));
    if (item.iconBuilder != null) {
      return item.iconBuilder!(
        context,
        SlidingPillNavItemVisualState(
          active: active,
          color: color,
          iconSize: size,
          activeIcon: item.activeIcon ?? item.icon,
          inactiveIcon: item.inactiveIcon ?? item.icon,
        ),
      );
    }
    return _AnimatedNavIcon(
      icon: item.iconFor(active: active),
      color: color,
      size: size,
    );
  }

  Color _labelColor(SlidingPillNavBarItem item, {required bool active}) {
    return active ? _navTheme.selectedAccent : _navTheme.itemInactive;
  }

  Widget _buildItem(int index) {
    final item = widget.items[index];
    final active = _isActive(index);
    final labelColor = _labelColor(item, active: active);
    final style = item.labelStyle ?? _labelStyle(context, active: active);
    final tabLabel = MaterialLocalizations.of(context)
        .tabLabel(tabIndex: index + 1, tabCount: _itemCount);

    return FocusableActionDetector(
      key: item.key,
      focusNode: _focusNodes[index],
      mouseCursor: SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _select(index);
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) {
            _select(index);
            return null;
          },
        ),
      },
      child: Semantics(
        container: true,
        button: true,
        selected: active,
        label: item.semanticLabel,
        hint: tabLabel,
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _focusNodes[index],
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: _borderRadius,
              border: Border.all(
                color: _focusNodes[index].hasFocus
                    ? _navTheme.itemActive
                    : _navTheme.focusRingIdle,
                width: _metrics.focusRingWidth,
              ),
            ),
            child: child,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(item, active),
              SizedBox(height: _metrics.iconLabelGap),
              // Hidden labels keep their line so icons never shift when the
              // active item changes.
              Visibility.maintain(
                visible: _labelsFit || active,
                child: _AnimatedColorText(
                  label: item.label,
                  style: style,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  const _AnimatedNavIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: color, end: color),
      duration: SlidingPillNavBarMotion.of(context).short,
      builder: (context, value, child) => Icon(icon, color: value, size: size),
    );
  }
}

class _AnimatedColorText extends StatelessWidget {
  const _AnimatedColorText({
    required this.label,
    required this.style,
    required this.color,
  });

  final String label;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: color, end: color),
      duration: SlidingPillNavBarMotion.of(context).short,
      builder: (context, value, _) => Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: style.copyWith(color: value),
      ),
    );
  }
}

/// The solid circular centre action: elevated, with an ink ripple and a
/// slight press-in, a keyboard focus ring, and button semantics.
class _CenterActionButton extends StatefulWidget {
  const _CenterActionButton({
    required this.action,
    required this.diameter,
    required this.focusRingColor,
    required this.focusRingWidth,
  });

  final SlidingPillNavBarCenterAction action;
  final double diameter;
  final Color focusRingColor;
  final double focusRingWidth;

  @override
  State<_CenterActionButton> createState() => _CenterActionButtonState();
}

class _CenterActionButtonState extends State<_CenterActionButton> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final navTheme = SlidingPillNavBarTheme.of(context);
    final enabled = action.onPressed != null;
    final background = action.backgroundColor ?? navTheme.selectedAccent;
    final foreground =
        action.foregroundColor ??
        (ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black);
    final reduced = SlidingPillNavBarMotion.reduced(context);
    final duration = reduced
        ? Duration.zero
        : SlidingPillNavBarMotion.of(context).short;

    final content = IconTheme.merge(
      data: IconThemeData(color: foreground, size: action.iconSize),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: foreground),
        child: Center(
          child:
              action.child ??
              Icon(action.icon, color: foreground, size: action.iconSize),
        ),
      ),
    );

    Widget button = AnimatedScale(
      scale: _pressed ? 0.92 : 1,
      duration: duration,
      curve: Curves.easeOut,
      child: Material(
        color: enabled ? background : background.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        elevation: action.elevation,
        shadowColor: action.shadowColor,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          focusNode: action.focusNode,
          customBorder: const CircleBorder(),
          onTap: action.onPressed,
          onHighlightChanged: _setPressed,
          onFocusChange: (value) => setState(() => _focused = value),
          splashColor: foreground.withValues(alpha: 0.24),
          highlightColor: foreground.withValues(alpha: 0.12),
          focusColor: foreground.withValues(alpha: 0.12),
          child: SizedBox.square(dimension: widget.diameter, child: content),
        ),
      ),
    );

    // Focus ring just outside the circle, in the nav bar's active colour.
    button = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: CircleBorder(
          side: BorderSide(
            color: _focused ? widget.focusRingColor : Colors.transparent,
            width: widget.focusRingWidth,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
      child: button,
    );

    if (action.tooltip != null) {
      button = Tooltip(message: action.tooltip, child: button);
    }

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: action.semanticLabel,
      excludeSemantics: true,
      onTap: action.onPressed,
      child: SizedBox.square(
        key: action.key,
        dimension: widget.diameter,
        child: button,
      ),
    );
  }
}
