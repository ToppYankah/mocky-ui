import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';
import 'helpers/nav_bar_test_theme.dart';

const _items = [
  SlidingPillNavBarItem(
    key: ValueKey('shell_tab_meters'),
    icon: Iconsax.flash,
    label: 'Meters',
    semanticLabel: 'Meters tab',
  ),
  SlidingPillNavBarItem(
    key: ValueKey('shell_tab_pay'),
    icon: Iconsax.wallet_2,
    label: 'Pay',
    semanticLabel: 'Pay tab',
  ),
  SlidingPillNavBarItem(
    key: ValueKey('shell_tab_complaints'),
    icon: Iconsax.message_question,
    label: 'Complaints',
    semanticLabel: 'Complaints tab',
  ),
  SlidingPillNavBarItem(
    key: ValueKey('shell_tab_profile'),
    icon: Iconsax.profile_circle,
    label: 'Profile',
    semanticLabel: 'Profile tab',
  ),
];

const ValueKey<String> _thumbKey = ValueKey('app_bottom_nav_thumb');
const ValueKey<String> _pillKey = ValueKey('app_bottom_nav_pill');

/// Pill width at 390pt: the screen minus screenHorizontal on both sides.
const _barWidth = 350.0;

/// Width of one item slot inside the pill's horizontal item inset (inset 10).
const double _slotWidth = (_barWidth - 20) / 4;

Color? _iconColor(WidgetTester tester, String key) => tester
    .widget<Icon>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Icon),
      ),
    )
    .color;

double _thumbX(WidgetTester tester) =>
    tester.getRect(find.byKey(_thumbKey)).center.dx;

Future<void> _pump(
  WidgetTester tester, {
  List<SlidingPillNavBarItem> items = _items,
  int selectedIndex = 0,
  ValueChanged<int>? onSelected,
  bool disableAnimations = false,
  ThemeMode mode = ThemeMode.light,
  double textScale = 1,
  double? initialThumbPosition,
  bool inVerticalScroller = false,
}) async {
  final bar = SlidingPillBottomNavBar(
    items: items,
    selectedIndex: selectedIndex,
    initialThumbPosition: initialThumbPosition,
    onSelected: onSelected ?? (_) {},
  );
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: NavBarTestTheme.light(),
      darkTheme: NavBarTestTheme.dark(),
      themeMode: mode,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          // A vertical drag competing in the arena, like a scroll view.
          bottomNavigationBar: inVerticalScroller
              ? GestureDetector(onVerticalDragUpdate: (_) {}, child: bar)
              : bar,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tap selects and calls onSelected once', (tester) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);

    await tester.tap(find.byKey(const ValueKey('shell_tab_complaints')));
    await tester.pumpAndSettle();

    expect(calls, [2]);
  });

  testWidgets('tap on the current tab still calls onSelected', (tester) async {
    final calls = <int>[];
    await _pump(tester, selectedIndex: 0, onSelected: calls.add);

    await tester.tap(find.byKey(const ValueKey('shell_tab_meters')));
    await tester.pumpAndSettle();

    expect(calls, [0]);
  });

  testWidgets('drag from item 0 to item 2 selects on release only', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);

    final start = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_meters')),
    );
    final end = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_complaints')),
    );
    final before = tester.getRect(find.byKey(_thumbKey));

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(end - start);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    // Mid-drag: the thumb has moved, but onSelected has not fired.
    expect(calls, isEmpty);
    final mid = tester.getRect(find.byKey(_thumbKey));
    expect(mid.center.dx, greaterThan(before.center.dx));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(calls, [2]);
  });

  testWidgets('dragged thumb trails the finger, then catches up', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);

    final start = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_meters')),
    );
    final end = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_complaints')),
    );

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(end - start);
    // First frame starts the follower; the second advances it.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 32));

    // Lagging: strictly between where it started and the finger.
    final lagging = tester.getRect(find.byKey(_thumbKey)).center.dx;
    expect(lagging, greaterThan(start.dx + 0.5));
    expect(lagging, lessThan(end.dx - 0.5));

    // Still holding: it converges on the finger.
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_thumbKey)).center.dx,
      closeTo(end.dx, 0.5),
    );
    expect(calls, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, [2]);
  });

  testWidgets('a fast drag squashes and stretches the thumb, then settles', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);
    const restHeight = 52.0;
    final rest = tester.getRect(find.byKey(_thumbKey));
    expect(rest.height, restHeight);

    final start = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_meters')),
    );
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));

    var minHeight = restHeight;
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
      final thumb = tester.getRect(find.byKey(_thumbKey));
      minHeight = math.min(minHeight, thumb.height);
      // Always inside the pill with thumbInset.
      final pill = tester.getRect(find.byKey(_pillKey));
      expect(
        thumb.top - pill.top,
        greaterThanOrEqualTo(SlidingPillNavBarMetrics.standard.thumbInset - 0.01),
      );
      expect(
        pill.right - thumb.right,
        greaterThanOrEqualTo(SlidingPillNavBarMetrics.standard.thumbInset - 0.01),
      );
    }
    // Scale != 1 while moving fast.
    expect(minHeight, lessThan(restHeight - 0.5));

    await gesture.up();
    await tester.pumpAndSettle();

    // Back to scale 1 and the selected item's width.
    final settled = tester.getRect(find.byKey(_thumbKey));
    expect(settled.height, restHeight);
    final selected = calls.single;
    await _pump(tester, selectedIndex: selected);
    final reference = tester.getRect(find.byKey(_thumbKey));
    expect(settled.width, closeTo(reference.width, 0.01));
  });

  testWidgets('reduced motion: the thumb sits on the finger, no wobble', (
    tester,
  ) async {
    await _pump(tester, disableAnimations: true);
    const restHeight = 52.0;

    final start = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_meters')),
    );
    final end = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_complaints')),
    );
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(end - start);
    await tester.pump();

    final thumb = tester.getRect(find.byKey(_thumbKey));
    expect(thumb.center.dx, closeTo(end.dx, 0.5));
    expect(thumb.height, restHeight);

    await gesture.up();
    await tester.pump();
    expect(tester.getRect(find.byKey(_thumbKey)).height, restHeight);
  });

  testWidgets('pointer down moves the thumb before up; up selects once', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);
    final activeColor = _iconColor(tester, 'shell_tab_meters');
    final startX = _thumbX(tester);
    final target = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_complaints')),
    );

    final gesture = await tester.startGesture(target);
    // Frame 1 starts the spring, frame 2 advances it: well inside the
    // 100 ms tap-down delay and before any up.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_thumbX(tester), greaterThan(startX + 1));
    expect(calls, isEmpty);

    // Item colours preview the pressed item while held.
    await tester.pump(const Duration(milliseconds: 300));
    expect(_iconColor(tester, 'shell_tab_complaints'), activeColor);
    expect(_iconColor(tester, 'shell_tab_meters'), isNot(activeColor));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, [2]);
    expect(_thumbX(tester), closeTo(target.dx, 0.5));
  });

  testWidgets('pointer down then cancel springs back, no onSelected', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);
    final activeColor = _iconColor(tester, 'shell_tab_meters');
    final startX = _thumbX(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('shell_tab_profile'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 48));
    expect(_thumbX(tester), greaterThan(startX + 1));

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(_thumbX(tester), closeTo(startX, 0.5));
    expect(_iconColor(tester, 'shell_tab_meters'), activeColor);
    expect(_iconColor(tester, 'shell_tab_profile'), isNot(activeColor));
  });

  testWidgets('down then a vertical scroll winning reverts, no onSelected', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add, inVerticalScroller: true);
    final startX = _thumbX(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('shell_tab_pay'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));
    // Past touch slop vertically: the vertical drag wins the arena.
    await gesture.moveBy(const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(_thumbX(tester), closeTo(startX, 0.5));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(_thumbX(tester), closeTo(startX, 0.5));
  });

  testWidgets('a drag after down continues smoothly from the press', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('shell_tab_pay'))),
    );
    await tester.pump();
    final xs = <double>[_thumbX(tester)];
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      xs.add(_thumbX(tester));
    }
    // Small steps: the drag starts part-way, past touch slop.
    for (var i = 0; i < 16; i++) {
      await gesture.moveBy(const Offset(6, 0));
      await tester.pump(const Duration(milliseconds: 16));
      xs.add(_thumbX(tester));
    }
    for (var i = 1; i < xs.length; i++) {
      final step = xs[i] - xs[i - 1];
      // Never jumps backwards or teleports between frames.
      expect(step, greaterThan(-3), reason: 'frame $i');
      expect(step, lessThan(_slotWidth / 4), reason: 'frame $i');
      if (i > 1) {
        expect(
          (step - (xs[i - 1] - xs[i - 2])).abs(),
          lessThan(10),
          reason: 'frame $i',
        );
      }
    }
    expect(calls, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, [2]);
  });

  testWidgets('reduced motion: pointer down jumps the thumb at once', (
    tester,
  ) async {
    final calls = <int>[];
    await _pump(tester, disableAnimations: true, onSelected: calls.add);
    final target = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_complaints')),
    );

    final gesture = await tester.startGesture(target);
    await tester.pump();
    expect(_thumbX(tester), closeTo(target.dx, 0.5));
    expect(calls, isEmpty);

    await gesture.up();
    await tester.pump();
    expect(calls, [2]);
  });

  testWidgets('a drag past the ends clamps', (tester) async {
    final calls = <int>[];
    await _pump(tester, onSelected: calls.add);

    final start = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_meters')),
    );

    var gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(-500, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, [0]);

    calls.clear();
    gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(2000, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, [3]);
  });

  testWidgets('thumb width matches the formula and differs per item', (
    tester,
  ) async {
    await _pump(tester, selectedIndex: 0);

    final context = tester.element(find.byType(SlidingPillBottomNavBar));
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 1.2,
      letterSpacing: 12 * -0.0025,
    );
    final textScaler = MediaQuery.textScalerOf(context);

    double measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      return painter.width;
    }

    double expectedWidth(int i) {
      final contentWidth = math.max(
        SlidingPillNavBarMetrics.standard.iconSize,
        measure(_items[i].label),
      );
      final natural = math.max(
        contentWidth + 2 * SlidingPillNavBarMetrics.standard.thumbPaddingH,
        _slotWidth + 2 * SlidingPillNavBarMetrics.standard.itemOverhang,
      );
      return math.min(natural, _barWidth - 2 * SlidingPillNavBarMetrics.standard.thumbInset);
    }

    final widths = <double>[];
    for (var i = 0; i < _items.length; i++) {
      await _pump(tester, selectedIndex: i);
      final thumb = tester.getRect(find.byKey(_thumbKey));
      widths.add(thumb.width);
      expect(thumb.width, closeTo(expectedWidth(i), 0.5));
      // Centred on its item, end items included.
      final item = tester.getCenter(find.byKey(_items[i].key!));
      expect(thumb.center.dx, closeTo(item.dx, 0.5));
    }

    // "Complaints" (index 2) is wider than "Pay" (index 1).
    expect(widths[2], greaterThan(widths[1]));
  });

  testWidgets('mid-drag thumb width sits between its two neighbours', (
    tester,
  ) async {
    // Thumb positioned halfway between item 1 (Pay) and item 2 (Complaints).
    await _pump(tester, selectedIndex: 1);
    final pay = tester.getRect(find.byKey(_thumbKey)).width;

    await _pump(tester, selectedIndex: 2);
    final complaints = tester.getRect(find.byKey(_thumbKey)).width;

    await _pump(tester, selectedIndex: 1, initialThumbPosition: 1.5);
    final mid = tester.getRect(find.byKey(_thumbKey)).width;

    expect(mid, greaterThan(pay));
    expect(mid, lessThan(complaints));
  });

  testWidgets(
    'thumb is at least slotWidth + 2 * itemOverhang for a middle item',
    (tester) async {
      await _pump(tester, selectedIndex: 1);

      final thumb = tester.getRect(find.byKey(_thumbKey));
      expect(
        thumb.width,
        greaterThanOrEqualTo(_slotWidth + 2 * SlidingPillNavBarMetrics.standard.itemOverhang),
      );
    },
  );

  testWidgets('end thumbs are as generous as middle ones and stay inset', (
    tester,
  ) async {
    // Equal short labels, so every thumb uses the slot-based minimum.
    final equalItems = [
      for (var i = 0; i < 4; i++)
        SlidingPillNavBarItem(
          key: ValueKey('equal_tab_$i'),
          icon: Iconsax.flash,
          label: 'Tab',
          semanticLabel: 'Tab $i',
        ),
    ];
    final expected = _slotWidth + 8;

    final widths = <double>[];
    for (var i = 0; i < equalItems.length; i++) {
      await _pump(tester, items: equalItems, selectedIndex: i);
      final pill = tester.getRect(find.byKey(_pillKey));
      final thumb = tester.getRect(find.byKey(_thumbKey));
      widths.add(thumb.width);

      expect(thumb.width, closeTo(expected, 0.5), reason: 'item $i');
      expect(
        thumb.left - pill.left,
        greaterThanOrEqualTo(SlidingPillNavBarMetrics.standard.thumbInset - 0.5),
      );
      expect(
        pill.right - thumb.right,
        greaterThanOrEqualTo(SlidingPillNavBarMetrics.standard.thumbInset - 0.5),
      );
    }

    // Same width at the ends as in the middle.
    expect(widths.first, closeTo(widths[1], 0.5));
    expect(widths.last, closeTo(widths[2], 0.5));

    // The end thumbs reach exactly thumbInset from the pill edge, the same
    // as the vertical inset.
    await _pump(tester, items: equalItems, selectedIndex: 0);
    final pill = tester.getRect(find.byKey(_pillKey));
    final first = tester.getRect(find.byKey(_thumbKey));
    expect(first.left - pill.left, closeTo(SlidingPillNavBarMetrics.standard.thumbInset, 0.5));
    expect(first.top - pill.top, closeTo(SlidingPillNavBarMetrics.standard.thumbInset, 0.5));
  });

  testWidgets('all icons are filled Iconsax, never a _copy outline', (
    tester,
  ) async {
    await _pump(tester, selectedIndex: 0);

    expect(find.byIcon(Iconsax.flash), findsOneWidget);
    expect(find.byIcon(Iconsax.wallet_2), findsOneWidget);
    expect(find.byIcon(Iconsax.message_question), findsOneWidget);
    expect(find.byIcon(Iconsax.profile_circle), findsOneWidget);

    expect(find.byIcon(Iconsax.flash_copy), findsNothing);
    expect(find.byIcon(Iconsax.wallet_2_copy), findsNothing);
    expect(find.byIcon(Iconsax.message_question_copy), findsNothing);
    expect(find.byIcon(Iconsax.profile_circle_copy), findsNothing);
  });

  testWidgets('reduced motion jumps to the target in a single pump', (
    tester,
  ) async {
    await _pump(tester, selectedIndex: 0, disableAnimations: true);
    final before = tester.getRect(find.byKey(_thumbKey));

    await tester.tap(find.byKey(const ValueKey('shell_tab_complaints')));
    await tester.pump(); // single frame, no spring settling

    final after = tester.getRect(find.byKey(_thumbKey));
    final item2 = tester.getCenter(
      find.byKey(const ValueKey('shell_tab_complaints')),
    );
    expect(after.center.dx, closeTo(item2.dx, 0.5));
    expect(after.center.dx, greaterThan(before.center.dx));
  });

  testWidgets('semantics: selected flag and "Tab i of n"', (tester) async {
    await _pump(tester, selectedIndex: 1);

    Semantics semantics(String key) => tester.widget<Semantics>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label != null,
        ),
      ),
    );

    final pay = semantics('shell_tab_pay');
    expect(pay.properties.selected, isTrue);
    expect(pay.properties.hint, 'Tab 2 of 4');

    final meters = semantics('shell_tab_meters');
    expect(meters.properties.selected, isNot(isTrue));
  });

  testWidgets('renders in light and dark without forcing a theme', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await _pump(tester, mode: mode);
      expect(find.byKey(_thumbKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('labels do not clip at 1.3 text scale', (tester) async {
    await _pump(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.byKey(_thumbKey), findsOneWidget);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('selected icon and label use primaryAccent (${mode.name})', (
      tester,
    ) async {
      await _pump(tester, mode: mode);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SlidingPillBottomNavBar));
      final tokens = Theme.of(context).extension<SlidingPillNavBarTheme>()!;
      final accent = tokens.selectedAccent;
      // The accent differs from the nav bar's active token, so this test
      // fails if the selected item falls back to the token.
      expect(accent, isNot(tokens.itemActive));

      expect(_iconColor(tester, 'shell_tab_meters'), accent);
      final label = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('shell_tab_meters')),
          matching: find.text('Meters'),
        ),
      );
      expect(label.style?.color, accent);

      for (final key in ['shell_tab_pay', 'shell_tab_profile']) {
        expect(_iconColor(tester, key), tokens.itemInactive);
      }
    });
  }
}
