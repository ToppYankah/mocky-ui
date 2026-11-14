import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';

import 'helpers/nav_bar_test_theme.dart';

const _items = [
  SlidingPillNavBarItem(
    key: ValueKey('tab_home'),
    icon: Iconsax.home_2,
    label: 'Home',
    semanticLabel: 'Home tab',
  ),
  SlidingPillNavBarItem(
    key: ValueKey('tab_meters'),
    icon: Iconsax.flash,
    label: 'Meters',
    semanticLabel: 'Meters tab',
  ),
  SlidingPillNavBarItem(
    key: ValueKey('tab_pay'),
    icon: Iconsax.wallet_2,
    label: 'Pay',
    semanticLabel: 'Pay tab',
  ),
  SlidingPillNavBarItem(
    key: ValueKey('tab_profile'),
    icon: Iconsax.profile_circle,
    label: 'Profile',
    semanticLabel: 'Profile tab',
  ),
];

const ValueKey<String> _actionKey = ValueKey('center_action');
const ValueKey<String> _pillKey = ValueKey('app_bottom_nav_pill');
const ValueKey<String> _thumbKey = ValueKey('app_bottom_nav_thumb');

SlidingPillNavBarCenterAction _action({
  VoidCallback? onPressed,
  FocusNode? focusNode,
  Color? backgroundColor,
}) => SlidingPillNavBarCenterAction(
  key: _actionKey,
  icon: Icons.add_rounded,
  semanticLabel: 'New payment',
  onPressed: onPressed ?? () {},
  focusNode: focusNode,
  backgroundColor: backgroundColor,
);

Future<void> _pump(
  WidgetTester tester, {
  SlidingPillNavBarCenterAction? action,
  List<SlidingPillNavBarItem> items = _items,
  int selectedIndex = 0,
  ValueChanged<int>? onSelected,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: NavBarTestTheme.light(),
      home: Scaffold(
        extendBody: true,
        body: const SizedBox.expand(),
        bottomNavigationBar: SlidingPillBottomNavBar(
          items: items,
          selectedIndex: selectedIndex,
          onSelected: onSelected ?? (_) {},
          centerAction: action ?? _action(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A stateful host so selection round-trips like in an app.
class _Host extends StatefulWidget {
  const _Host({required this.onSelected, required this.onPressed});

  final ValueChanged<int> onSelected;
  final VoidCallback onPressed;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Text('selected $_index'),
      bottomNavigationBar: SlidingPillBottomNavBar(
        items: _items,
        selectedIndex: _index,
        onSelected: (i) {
          widget.onSelected(i);
          setState(() => _index = i);
        },
        centerAction: _action(onPressed: widget.onPressed),
      ),
    );
  }
}

void main() {
  testWidgets('renders centred with items split evenly either side', (
    tester,
  ) async {
    await _pump(tester);

    final pill = tester.getRect(find.byKey(_pillKey));
    final button = tester.getRect(find.byKey(_actionKey));
    expect(button.center.dx, moreOrLessEquals(pill.center.dx));
    expect(button.center.dy, moreOrLessEquals(pill.center.dy));

    // Two items on each side of the circle, none overlapping it.
    for (final key in ['tab_home', 'tab_meters']) {
      expect(tester.getRect(find.byKey(ValueKey(key))).right,
          lessThanOrEqualTo(button.left));
    }
    for (final key in ['tab_pay', 'tab_profile']) {
      expect(tester.getRect(find.byKey(ValueKey(key))).left,
          greaterThanOrEqualTo(button.right));
    }
    // Mirror-symmetric slots.
    final home = tester.getRect(find.byKey(const ValueKey('tab_home')));
    final profile = tester.getRect(find.byKey(const ValueKey('tab_profile')));
    expect(home.left - pill.left, moreOrLessEquals(pill.right - profile.right));
    expect(home.width, moreOrLessEquals(profile.width));
  });

  testWidgets('the circle is bigger than the bar and pokes past both edges', (
    tester,
  ) async {
    await _pump(tester);

    final pill = tester.getRect(find.byKey(_pillKey));
    final button = tester.getRect(find.byKey(_actionKey));
    expect(button.height, greaterThan(pill.height));
    expect(button.top, lessThan(pill.top));
    expect(button.bottom, greaterThan(pill.bottom));
  });

  testWidgets('without an action the pill keeps its position and size', (
    tester,
  ) async {
    Future<Rect> pillRect({required bool withAction}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NavBarTestTheme.light(),
          home: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: SlidingPillBottomNavBar(
              items: _items,
              selectedIndex: 0,
              onSelected: (_) {},
              centerAction: withAction ? _action() : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.byKey(_pillKey));
    }

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final plain = await pillRect(withAction: false);
    final withAction = await pillRect(withAction: true);
    expect(withAction, plain);
    expect(find.byKey(const ValueKey('app_bottom_nav_cradle')), findsOneWidget);
  });

  test('asserts when given an odd number of items', () {
    expect(
      () => SlidingPillBottomNavBar(
        items: _items.sublist(0, 3),
        selectedIndex: 0,
        onSelected: (_) {},
        centerAction: _action(),
      ),
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('even number of items'),
        ),
      ),
    );
  });

  test('odd item counts are still fine without an action', () {
    expect(
      () => SlidingPillBottomNavBar(
        items: _items.sublist(0, 3),
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      returnsNormally,
    );
  });

  testWidgets('tapping the action calls onPressed, never onSelected', (
    tester,
  ) async {
    var pressed = 0;
    final selected = <int>[];
    await _pump(
      tester,
      selectedIndex: 1,
      onSelected: selected.add,
      action: _action(onPressed: () => pressed++),
    );
    final thumbBefore = tester.getRect(find.byKey(_thumbKey));

    await tester.tap(find.byKey(_actionKey));
    await tester.pumpAndSettle();

    expect(pressed, 1);
    expect(selected, isEmpty);
    expect(tester.getRect(find.byKey(_thumbKey)), thumbBefore);
  });

  testWidgets('the parts of the circle outside the bar are tappable', (
    tester,
  ) async {
    var pressed = 0;
    final selected = <int>[];
    await _pump(
      tester,
      onSelected: selected.add,
      action: _action(onPressed: () => pressed++),
    );
    final pill = tester.getRect(find.byKey(_pillKey));
    final button = tester.getRect(find.byKey(_actionKey));

    await tester.tapAt(Offset(button.center.dx, (button.top + pill.top) / 2));
    await tester.pumpAndSettle();
    await tester.tapAt(
      Offset(button.center.dx, (button.bottom + pill.bottom) / 2),
    );
    await tester.pumpAndSettle();

    expect(pressed, 2);
    expect(selected, isEmpty);
  });

  testWidgets('the cradle gap around the circle selects nothing', (
    tester,
  ) async {
    var pressed = 0;
    final selected = <int>[];
    await _pump(
      tester,
      onSelected: selected.add,
      action: _action(onPressed: () => pressed++),
    );
    final button = tester.getRect(find.byKey(_actionKey));

    // Just outside the circle, inside the 6pt gap, on the bar's centre line.
    await tester.tapAt(button.centerRight + const Offset(3, 0));
    await tester.pumpAndSettle();

    expect(pressed, 0);
    expect(selected, isEmpty);
  });

  testWidgets('tapping items on both sides selects the right index', (
    tester,
  ) async {
    final selected = <int>[];
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: NavBarTestTheme.light(),
        home: _Host(onSelected: selected.add, onPressed: () => pressed++),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in ['tab_profile', 'tab_meters', 'tab_pay', 'tab_home']) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      final thumb = tester.getRect(find.byKey(_thumbKey));
      final item = tester.getRect(find.byKey(ValueKey(key)));
      expect(thumb.center.dx, moreOrLessEquals(item.center.dx, epsilon: 0.5));
    }
    expect(selected, [3, 1, 2, 0]);
    expect(pressed, 0);
  });

  testWidgets('a drag across the action lands on the item past it', (
    tester,
  ) async {
    final selected = <int>[];
    await _pump(tester, selectedIndex: 1, onSelected: selected.add);
    final from = tester.getCenter(find.byKey(const ValueKey('tab_meters')));
    final to = tester.getCenter(find.byKey(const ValueKey('tab_pay')));

    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, [2]);
  });

  testWidgets('keyboard: focus the action and press Enter', (tester) async {
    var pressed = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(
      tester,
      action: _action(onPressed: () => pressed++, focusNode: focusNode),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(pressed, 1);
  });

  testWidgets('semantics: a labelled, tappable button', (tester) async {
    final handle = tester.ensureSemantics();
    var pressed = 0;
    await _pump(tester, action: _action(onPressed: () => pressed++));

    final node = tester.getSemantics(find.byKey(_actionKey));
    expect(node.label, 'New payment');
    expect(
      node,
      matchesSemantics(
        label: 'New payment',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('backgroundColor paints the circle', (tester) async {
    const colour = Color(0xFFE91E63);
    await _pump(tester, action: _action(backgroundColor: colour));

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byKey(_actionKey),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, colour);
    expect(material.shape, const CircleBorder());
  });
}
