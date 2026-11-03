import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';

import 'helpers/nav_bar_test_theme.dart';

void main() {
  testWidgets('uses activeIcon and inactiveIcon with theme icon colors', (
    tester,
  ) async {
    const activeGlyph = Icons.home;
    const inactiveGlyph = Icons.home_outlined;
    const customActive = Color(0xFF112233);
    const customInactive = Color(0xFF445566);

    await tester.pumpWidget(
      MaterialApp(
        theme: NavBarTestTheme.light().copyWith(
          extensions: [
            SlidingPillNavBarTheme.light.copyWith(
              activeIconColor: customActive,
              inactiveIconColor: customInactive,
            ),
            SlidingPillNavBarMotion.regular,
          ],
        ),
        home: Scaffold(
          bottomNavigationBar: SlidingPillBottomNavBar(
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              SlidingPillNavBarItem(
                activeIcon: activeGlyph,
                inactiveIcon: inactiveGlyph,
                label: 'Home',
                semanticLabel: 'Home tab',
              ),
              SlidingPillNavBarItem(
                icon: Icons.person,
                label: 'Profile',
                semanticLabel: 'Profile tab',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(activeGlyph), findsOneWidget);
    expect(find.byIcon(inactiveGlyph), findsNothing);

    final activeIcon = tester.widget<Icon>(find.byIcon(activeGlyph));
    expect(activeIcon.color, customActive);

    final profileIcon = tester.widget<Icon>(find.byIcon(Icons.person));
    expect(profileIcon.color, customInactive);
  });

  testWidgets('per-item icon colors override theme', (tester) async {
    const overrideActive = Color(0xFFAABBCC);
    const overrideInactive = Color(0xCCDDEEFF);

    await tester.pumpWidget(
      MaterialApp(
        theme: NavBarTestTheme.light(),
        home: Scaffold(
          bottomNavigationBar: SlidingPillBottomNavBar(
            selectedIndex: 1,
            onSelected: (_) {},
            items: const [
              SlidingPillNavBarItem(
                icon: Icons.star,
                label: 'One',
                semanticLabel: 'One',
              ),
              SlidingPillNavBarItem(
                icon: Icons.favorite,
                activeIconColor: overrideActive,
                inactiveIconColor: overrideInactive,
                label: 'Two',
                semanticLabel: 'Two',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final star = tester.widget<Icon>(find.byIcon(Icons.star));
    expect(star.color, isNot(overrideActive));

    final heart = tester.widget<Icon>(find.byIcon(Icons.favorite));
    expect(heart.color, overrideActive);
  });
}
