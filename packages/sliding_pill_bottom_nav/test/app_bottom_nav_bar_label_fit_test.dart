import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';
import 'helpers/nav_bar_test_theme.dart';

// Five shell tabs. When the measured labels would crowd, only the active
// item keeps its label; inactive items are icon-only but keep semantics.

const _items = [
  SlidingPillNavBarItem(
    key: ValueKey('shell_tab_home'),
    icon: Iconsax.home_2,
    label: 'Home',
    semanticLabel: 'Home tab',
  ),
  SlidingPillNavBarItem(
    key: ValueKey('shell_tab_meters'),
    icon: Iconsax.flash_circle,
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

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
  int selected = 0,
}) async {
  final size = Size(width, 700);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var index = selected;
  await tester.pumpWidget(
    MaterialApp(
      theme: NavBarTestTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: SlidingPillBottomNavBar(
              items: _items,
              selectedIndex: index,
              onSelected: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<bool> _labelsShown(WidgetTester tester) => [
  for (final item in _items)
    tester
        .widget<Visibility>(
          find.ancestor(
            of: find.text(item.label),
            matching: find.byType(Visibility),
          ),
        )
        .visible,
];

void _expectNoVisibleOverlap(WidgetTester tester) {
  final shown = _labelsShown(tester);
  final rects = [
    for (var i = 0; i < _items.length; i++)
      if (shown[i]) tester.getRect(find.text(_items[i].label)),
  ];
  for (var i = 0; i + 1 < rects.length; i++) {
    expect(
      rects[i].right + SlidingPillNavBarMetrics.standard.labelMinGap,
      lessThanOrEqualTo(rects[i + 1].left + 0.01),
    );
  }
}

void main() {
  testWidgets('390pt at 1.0x: every label shows', (tester) async {
    await _pump(tester, width: 390);
    expect(_labelsShown(tester), everyElement(isTrue));
    _expectNoVisibleOverlap(tester);
  });

  testWidgets('320pt at 1.0x: Complaints crowds, so only active shows', (
    tester,
  ) async {
    await _pump(tester, width: 320);
    expect(_labelsShown(tester), [true, false, false, false, false]);
    _expectNoVisibleOverlap(tester);
  });

  testWidgets('390pt at 1.3x: labels crowd, so only active shows', (
    tester,
  ) async {
    await _pump(tester, width: 390, textScale: 1.3, selected: 1);
    expect(_labelsShown(tester), [false, true, false, false, false]);
    _expectNoVisibleOverlap(tester);
  });

  testWidgets('320pt at 1.3x: only the active label shows', (tester) async {
    await _pump(tester, width: 320, textScale: 1.3, selected: 3);
    expect(_labelsShown(tester), [false, false, false, true, false]);
    _expectNoVisibleOverlap(tester);

    // The label follows the selection; icons keep their place.
    final iconTop = tester.getRect(find.byIcon(Iconsax.home_2)).top;
    await tester.tap(find.byKey(const ValueKey('shell_tab_home')));
    await tester.pumpAndSettle();
    expect(_labelsShown(tester), [true, false, false, false, false]);
    expect(tester.getRect(find.byIcon(Iconsax.home_2)).top, iconTop);
  });

  testWidgets('icon-only items keep their semantics labels', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, width: 320, textScale: 1.3);
    for (final item in _items) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(item.semanticLabel)),
        matchesSemantics(
          label: item.semanticLabel,
          isButton: true,
          isSelected: item == _items.first,
          hasSelectedState: true,
          hint: 'Tab ${_items.indexOf(item) + 1} of 5',
          textDirection: TextDirection.ltr,
        ),
      );
    }
    handle.dispose();
  });

  for (final selected in [0, 3, 4]) {
    testWidgets('320pt at 1.3x: thumb holds active item $selected', (
      tester,
    ) async {
      await _pump(tester, width: 320, textScale: 1.3, selected: selected);
      final pill = tester.getRect(
        find.byKey(const ValueKey('app_bottom_nav_pill')),
      );
      final thumb = tester.getRect(
        find.byKey(const ValueKey('app_bottom_nav_thumb')),
      );
      final active = _items[selected];
      final label = tester.getRect(find.text(active.label));
      final icon = tester.getRect(find.byIcon(active.icon!));
      // Label and icon sit inside the thumb with thumbPaddingH, centred.
      expect(
        label.left - thumb.left,
        greaterThanOrEqualTo(SlidingPillNavBarMetrics.standard.thumbPaddingH - 0.5),
      );
      expect(
        thumb.right - label.right,
        greaterThanOrEqualTo(SlidingPillNavBarMetrics.standard.thumbPaddingH - 0.5),
      );
      expect(label.center.dx, moreOrLessEquals(thumb.center.dx, epsilon: 1));
      expect(icon.center.dx, moreOrLessEquals(thumb.center.dx, epsilon: 1));
      expect(label.bottom, lessThanOrEqualTo(thumb.bottom));
      expect(icon.top, greaterThanOrEqualTo(thumb.top));
      expect(thumb.left, greaterThanOrEqualTo(pill.left));
      expect(thumb.right, lessThanOrEqualTo(pill.right));

      // Other icons stay clear of the thumb and evenly spaced.
      final others = [
        for (var i = 0; i < _items.length; i++)
          if (i != selected) tester.getRect(find.byIcon(_items[i].icon!)),
      ];
      for (final r in others) {
        expect(r.overlaps(thumb), isFalse);
      }
      final before = others.where((r) => r.center.dx < thumb.left).toList();
      final after = others.where((r) => r.center.dx > thumb.right).toList();
      for (final side in [before, after]) {
        for (var i = 0; i + 2 < side.length; i++) {
          expect(
            side[i + 1].center.dx - side[i].center.dx,
            moreOrLessEquals(
              side[i + 2].center.dx - side[i + 1].center.dx,
              epsilon: 0.5,
            ),
          );
        }
      }
    });
  }

  testWidgets('320pt at 1.3x: tapping each icon selects it', (tester) async {
    await _pump(tester, width: 320, textScale: 1.3);
    for (final i in [4, 1, 3, 0, 2]) {
      await tester.tap(find.byIcon(_items[i].icon!));
      await tester.pumpAndSettle();
      expect(_labelsShown(tester)[i], isTrue);
    }
  });

  testWidgets('end thumbs match in width', (tester) async {
    double thumbWidthAt(int index) => tester
        .getRect(find.byKey(const ValueKey('app_bottom_nav_thumb')))
        .width;
    await _pump(tester, width: 390);
    final first = thumbWidthAt(0);
    await tester.tap(find.byIcon(_items.last.icon!));
    await tester.pumpAndSettle();
    expect(thumbWidthAt(4), moreOrLessEquals(first, epsilon: 0.5));
  });

  group('labelsFitSlots', () {
    test('neighbours closer than the minimum gap do not fit', () {
      expect(labelsFitSlots([40, 40], 44, SlidingPillNavBarMetrics.standard), isTrue);
      expect(labelsFitSlots([40, 41], 44, SlidingPillNavBarMetrics.standard), isFalse);
    });

    test('end labels may use only the item overhang', () {
      const slot = 40.0;
      final room = slot + 8;
      expect(labelsFitSlots([room], slot, SlidingPillNavBarMetrics.standard), isTrue);
      expect(labelsFitSlots([room + 1], slot, SlidingPillNavBarMetrics.standard), isFalse);
    });

    test('no labels fit trivially', () {
      expect(labelsFitSlots(const [], 10, SlidingPillNavBarMetrics.standard), isTrue);
    });
  });
}
