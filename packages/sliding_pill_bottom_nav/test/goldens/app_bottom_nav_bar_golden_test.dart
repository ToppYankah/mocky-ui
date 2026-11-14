import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:sliding_pill_bottom_nav/sliding_pill_bottom_nav.dart';

import '../helpers/golden_harness.dart';

// Variants covered: standard, five tabs (390pt and 320pt at 1.3x),
// content fading under the bar (320pt at 1x and 1.3x), and the centre
// action button with the bar morphed around it.

const _items = [
  SlidingPillNavBarItem(
    icon: Iconsax.flash,
    label: 'Meters',
    semanticLabel: 'Meters tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.wallet_2,
    label: 'Pay',
    semanticLabel: 'Pay tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.message_question,
    label: 'Complaints',
    semanticLabel: 'Complaints tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.profile_circle,
    label: 'Profile',
    semanticLabel: 'Profile tab',
  ),
];

/// The signed-in shell's five tabs.
const _shellItems = [
  SlidingPillNavBarItem(
    icon: Iconsax.home_2,
    label: 'Home',
    semanticLabel: 'Home tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.flash_circle,
    label: 'Meters',
    semanticLabel: 'Meters tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.wallet_2,
    label: 'Pay',
    semanticLabel: 'Pay tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.message_question,
    label: 'Complaints',
    semanticLabel: 'Complaints tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.profile_circle,
    label: 'Profile',
    semanticLabel: 'Profile tab',
  ),
];

Widget _fiveTabs({
  required ThemeMode mode,
  required double width,
  int selected = 0,
  double textScale = 1,
}) {
  return goldenHarness(
    SlidingPillBottomNavBar(
      items: _shellItems,
      selectedIndex: selected,
      onSelected: (_) {},
    ),
    themeMode: mode,
    width: width,
    height: 120,
    textScale: textScale,
  );
}

Widget _bar({
  required ThemeMode mode,
  int selected = 0,
  double? thumbPosition,
  double textScale = 1,
}) {
  return goldenHarness(
    SlidingPillBottomNavBar(
      items: _items,
      selectedIndex: selected,
      initialThumbPosition: thumbPosition,
      onSelected: (_) {},
    ),
    themeMode: mode,
    width: 390,
    height: 120,
    textScale: textScale,
  );
}

/// The bar as the shell uses it: a full-size Scaffold with extendBody and a
/// home-indicator inset, so the pill must sit at the bottom.
Widget _inScaffold({required ThemeMode mode}) {
  return goldenHarness(
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(bottom: 34),
          viewPadding: const EdgeInsets.only(bottom: 34),
        ),
        child: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          bottomNavigationBar: SlidingPillBottomNavBar(
            items: _items,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
    themeMode: mode,
    width: 390,
    height: 844,
  );
}

/// Rows of cards behind an extended body, so the fade reads as content
/// dissolving into the scaffold above and under the pill.
class _FadeContent extends StatelessWidget {
  const _FadeContent();

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (var i = 0; i < 12; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Payment'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The shell's extended body with content running under the bar.
Widget _fadeOverContent({required ThemeMode mode, required double textScale}) {
  return goldenHarness(
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(bottom: 34),
          viewPadding: const EdgeInsets.only(bottom: 34),
        ),
        child: Scaffold(
          extendBody: true,
          body: const _FadeContent(),
          bottomNavigationBar: SlidingPillBottomNavBar(
            items: _shellItems,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    ),
    themeMode: mode,
    width: 320,
    height: 400,
    textScale: textScale,
  );
}

const _centerActionItems = [
  SlidingPillNavBarItem(
    icon: Iconsax.home_2,
    label: 'Home',
    semanticLabel: 'Home tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.flash_circle,
    label: 'Meters',
    semanticLabel: 'Meters tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.message_question,
    label: 'Support',
    semanticLabel: 'Support tab',
  ),
  SlidingPillNavBarItem(
    icon: Iconsax.profile_circle,
    label: 'Profile',
    semanticLabel: 'Profile tab',
  ),
];

/// Four tabs split around the centre action, which the bar wraps.
Widget _centerAction({required ThemeMode mode, required int selected}) {
  return goldenHarness(
    SlidingPillBottomNavBar(
      items: _centerActionItems,
      selectedIndex: selected,
      onSelected: (_) {},
      centerAction: SlidingPillNavBarCenterAction(
        icon: Icons.add_rounded,
        foregroundColor: Colors.white,
        semanticLabel: 'New payment',
        onPressed: () {},
      ),
    ),
    themeMode: mode,
    width: 390,
    height: 120,
  );
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final suffix = mode == ThemeMode.light ? 'light' : 'dark';

    for (var i = 0; i < _items.length; i++) {
      await goldenTest(
        'SlidingPillBottomNavBar selected $i $suffix',
        fileName: 'app_bottom_nav_bar_selected_${i}_$suffix',
        builder: () => GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'selected_${i}_$suffix',
              child: _bar(mode: mode, selected: i),
            ),
          ],
        ),
      );
    }

    await goldenTest(
      'SlidingPillBottomNavBar mid-drag $suffix',
      fileName: 'app_bottom_nav_bar_mid_drag_$suffix',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'mid_drag_$suffix',
            child: _bar(mode: mode, selected: 1, thumbPosition: 1.35),
          ),
        ],
      ),
    );

    await goldenTest(
      'SlidingPillBottomNavBar in scaffold $suffix',
      fileName: 'app_bottom_nav_bar_in_scaffold_$suffix',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'in_scaffold_$suffix',
            child: _inScaffold(mode: mode),
          ),
        ],
      ),
    );

    await goldenTest(
      'SlidingPillBottomNavBar fade over content $suffix',
      fileName: 'app_bottom_nav_bar_fade_$suffix',
      builder: () => GoldenTestGroup(
        columns: 2,
        children: [
          for (final scale in [1.0, 1.3])
            GoldenTestScenario(
              name: scale == 1 ? 'fade_320_$suffix' : 'fade_320_1_3_$suffix',
              child: _fadeOverContent(mode: mode, textScale: scale),
            ),
        ],
      ),
    );

    await goldenTest(
      'SlidingPillBottomNavBar text scale 1.3 $suffix',
      fileName: 'app_bottom_nav_bar_text_scale_1_3_$suffix',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'text_scale_1_3_$suffix',
            child: _bar(mode: mode, textScale: 1.3),
          ),
        ],
      ),
    );

    await goldenTest(
      'SlidingPillBottomNavBar five tabs $suffix',
      fileName: 'app_bottom_nav_bar_five_tabs_$suffix',
      builder: () => GoldenTestGroup(
        children: [
          for (final selected in [0, 3])
            GoldenTestScenario(
              name: 'five_tabs_selected_${selected}_$suffix',
              child: _fiveTabs(mode: mode, width: 390, selected: selected),
            ),
        ],
      ),
    );

    await goldenTest(
      'SlidingPillBottomNavBar five tabs 320pt 1.3x $suffix',
      fileName: 'app_bottom_nav_bar_five_tabs_320_1_3_$suffix',
      builder: () => GoldenTestGroup(
        children: [
          for (final selected in [0, 3])
            GoldenTestScenario(
              name: 'five_tabs_320_1_3_selected_${selected}_$suffix',
              child: _fiveTabs(
                mode: mode,
                width: 320,
                selected: selected,
                textScale: 1.3,
              ),
            ),
        ],
      ),
    );

    await goldenTest(
      'SlidingPillBottomNavBar center action $suffix',
      fileName: 'app_bottom_nav_bar_center_action_$suffix',
      builder: () => GoldenTestGroup(
        children: [
          for (final selected in [0, 2])
            GoldenTestScenario(
              name: 'center_action_selected_${selected}_$suffix',
              child: _centerAction(mode: mode, selected: selected),
            ),
        ],
      ),
    );
  }
}
