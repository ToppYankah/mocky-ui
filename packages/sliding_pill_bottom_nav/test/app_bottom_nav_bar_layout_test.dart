import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';
import 'helpers/nav_bar_test_theme.dart';

// Layout of the bar inside Scaffold.bottomNavigationBar, the way the
// signed-in shell uses it: pinned to the bottom, sized to the pill plus the
// fade above it, with each item's icon and label centred vertically. The
// bottom gap equals the side gap (screenHorizontal) and ignores the
// safe-area inset.

const _screenHorizontal = 20.0;

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

const _screen = Size(390, 844);
const _bottomInset = 34.0;
const _pillKey = ValueKey<String>('app_bottom_nav_pill');
const _bodyProbeKey = ValueKey<String>('body_probe');
const _fadeKey = ValueKey<String>('app_bottom_nav_fade');

/// Side and bottom gap around the pill.
final double _gap = _screenHorizontal;

/// Fade, pill and bottom gap: the bar's full height.
final double _barTotalHeight =
    SlidingPillNavBarMetrics.standard.fadeExtent + SlidingPillNavBarMetrics.standard.barHeight + _gap;

Future<void> _pump(
  WidgetTester tester, {
  required ThemeMode mode,
  required int selectedIndex,
  double textScale = 1,
  ValueSetter<double>? onBodyPadding,
  Widget? body,
}) async {
  tester.view.physicalSize = _screen;
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
          size: _screen,
          padding: const EdgeInsets.only(bottom: _bottomInset),
          viewPadding: const EdgeInsets.only(bottom: _bottomInset),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          extendBody: true,
          body: Builder(
            builder: (context) {
              onBodyPadding?.call(MediaQuery.paddingOf(context).bottom);
              return body ??
                  const ColoredBox(
                    key: _bodyProbeKey,
                    color: Colors.transparent,
                    child: SizedBox.expand(),
                  );
            },
          ),
          bottomNavigationBar: SlidingPillBottomNavBar(
            items: _items,
            selectedIndex: selectedIndex,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectItemsCentred(WidgetTester tester) {
  final pill = tester.getRect(find.byKey(_pillKey));
  for (final item in _items) {
    final itemFinder = find.byKey(item.key!);
    final icon = tester.getRect(
      find.descendant(of: itemFinder, matching: find.byIcon(item.icon!)),
    );
    final label = tester.getRect(
      find.descendant(of: itemFinder, matching: find.text(item.label)),
    );
    final content = icon.expandToInclude(label);
    expect(
      content.center.dy,
      closeTo(pill.center.dy, 1),
      reason: '${item.label} icon + label should be centred in the pill',
    );
    expect(content.top, greaterThanOrEqualTo(pill.top));
    expect(content.bottom, lessThanOrEqualTo(pill.bottom));
  }
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final name = mode == ThemeMode.light ? 'light' : 'dark';

    for (final selected in [0, 3]) {
      testWidgets('$name, selected $selected: pill sits at the bottom', (
        tester,
      ) async {
        double? bodyPadding;
        await _pump(
          tester,
          mode: mode,
          selectedIndex: selected,
          onBodyPadding: (value) => bodyPadding = value,
        );

        final pill = tester.getRect(find.byKey(_pillKey));
        // Bottom gap == side gap, even with a 34px home-indicator inset.
        expect(pill.bottom, _screen.height - _gap);
        expect(pill.left, _gap);
        expect(pill.right, _screen.width - _gap);
        expect(pill.height, SlidingPillNavBarMetrics.standard.barHeight);

        final bar = tester.getRect(find.byType(SlidingPillBottomNavBar));
        expect(bar.height, _barTotalHeight);
        expect(bar.bottom, _screen.height);

        expect(bodyPadding, _barTotalHeight);
        _expectItemsCentred(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$name, text scale 1.3: items stay centred', (tester) async {
      await _pump(tester, mode: mode, selectedIndex: 0, textScale: 1.3);

      expect(
        tester.getRect(find.byKey(_pillKey)).height,
        SlidingPillNavBarMetrics.standard.barHeight,
      );
      _expectItemsCentred(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name: the fade runs from the scaffold colour to clear', (
      tester,
    ) async {
      await _pump(tester, mode: mode, selectedIndex: 0);

      final scaffold = Theme.of(tester.element(find.byKey(_bodyProbeKey)))
          .scaffoldBackgroundColor;
      final fade = tester.widget<DecoratedBox>(find.byKey(_fadeKey));
      final gradient =
          (fade.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(gradient.begin, Alignment.bottomCenter);
      expect(gradient.end, Alignment.topCenter);
      expect(gradient.colors, [scaffold, scaffold.withValues(alpha: 0)]);

      final rect = tester.getRect(find.byKey(_fadeKey));
      expect(rect.height, _barTotalHeight);
      expect(rect.bottom, _screen.height);
      expect(rect.left, 0);
      expect(rect.right, _screen.width);
      final pill = tester.getRect(find.byKey(_pillKey));
      expect(pill.top - rect.top, SlidingPillNavBarMetrics.standard.fadeExtent);
    });

    testWidgets('$name: taps in the fade and beside the pill reach the body', (
      tester,
    ) async {
      final taps = <Offset>[];
      await _pump(
        tester,
        mode: mode,
        selectedIndex: 0,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => taps.add(details.globalPosition),
          child: const SizedBox.expand(key: _bodyProbeKey),
        ),
      );
      final fade = tester.getRect(find.byKey(_fadeKey));
      final pill = tester.getRect(find.byKey(_pillKey));
      final inFade = Offset(
        _screen.width / 2,
        fade.top + SlidingPillNavBarMetrics.standard.fadeExtent / 2,
      );
      final besidePill = Offset(_gap / 2, pill.center.dy);
      final underPill = Offset(_gap / 2, pill.bottom + _gap / 2);
      for (final point in [inFade, besidePill, underPill]) {
        await tester.tapAt(point);
        await tester.pumpAndSettle();
      }
      expect(taps, [inFade, besidePill, underPill]);

      // The pill itself still takes its own taps.
      await tester.tapAt(pill.center);
      await tester.pumpAndSettle();
      expect(taps, hasLength(3));
    });

    testWidgets('$name: the last list item scrolls clear of the bar and fade', (
      tester,
    ) async {
      await _pump(
        tester,
        mode: mode,
        selectedIndex: 0,
        body: ListView(
          children: [
            for (var i = 0; i < 40; i++)
              SizedBox(height: 48, child: Text('row $i')),
          ],
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      final last = tester.getRect(find.text('row 39'));
      final fade = tester.getRect(find.byKey(_fadeKey));
      expect(last.bottom, lessThanOrEqualTo(fade.top));
    });
  }
}
