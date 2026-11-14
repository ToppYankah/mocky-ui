# Sliding pill bottom nav

Floating pill bottom navigation with a sliding thumb, press preview, horizontal drag, and scaffold fade.

## Install (GitHub only)

```yaml
dependencies:
  sliding_pill_bottom_nav:
    git:
      url: https://github.com/ToppYankah/mocky-ui.git
      ref: sliding_pill_bottom_nav-v0.1.0
      path: packages/sliding_pill_bottom_nav
```

Do not use filesystem `path:` dependencies or `dependency_overrides` in consuming apps.

## Setup

Register theme extensions on your `ThemeData`:

```dart
ThemeData(
  extensions: [
    SlidingPillNavBarTheme.light, // or .dark / custom copyWith
    SlidingPillNavBarMotion.regular,
  ],
)
```

Use with `Scaffold(extendBody: true, bottomNavigationBar: SlidingPillBottomNavBar(...))`.

## Custom icons and fonts

- **Icons:** set `icon` for the same glyph in both states, or `activeIcon` / `inactiveIcon` for different glyphs.
- **Icon colours:** set `SlidingPillNavBarTheme.activeIconColor` and `inactiveIconColor` (defaults match `selectedAccent` / `itemInactive`). Override per item with `activeIconColor` / `inactiveIconColor` on [SlidingPillNavBarItem].
- **Custom widgets:** `iconBuilder` receives [SlidingPillNavItemVisualState] with `active`, `color`, `iconSize`, and resolved `activeIcon` / `inactiveIcon`.
- **Fonts:** `SlidingPillNavBarTheme.labelStyleBuilder` or per-item `labelStyle`.

## Centre action button

Pass `centerAction` to put a solid circular action button in the middle of the bar, between two equal halves of the items. The circle is bigger than the bar, so it pokes past the bar's top and bottom edges, and the bar's outline morphs around it (fill, border, and shadow all follow the wrapped shape).

```dart
SlidingPillBottomNavBar(
  items: items, // must be an even number of items
  selectedIndex: index,
  onSelected: (i) => setState(() => index = i),
  centerAction: SlidingPillNavBarCenterAction(
    icon: Icons.add_rounded,
    semanticLabel: 'New payment',
    tooltip: 'New payment',
    backgroundColor: Colors.deepPurple, // default: theme selectedAccent
    foregroundColor: Colors.white, // default: contrasts with background
    onPressed: () => openComposer(),
  ),
)
```

- **Even items only:** with an odd number of items the constructor fails an assertion (`centerAction needs an even number of items`). Odd counts are still fine without an action.
- **Not a destination:** pressing it calls `onPressed` only; it never changes `selectedIndex` or calls `onSelected`. The sliding thumb, taps, and drags skip its slot and land on the items either side.
- **Shape:** `diameter` (default `barHeight + 8`), `cradleGap` (space between circle and bar outline, default 6), and `cradleSmoothing` (fillet radius where the outline meets the bar, default 12).
- **Look and feel:** `icon` or a custom `child`, `iconSize`, `elevation` and `shadowColor`. It has an ink ripple and a slight press-in, a keyboard focus ring (pass your own `focusNode` if needed), and is announced as a button with `semanticLabel`.
- The protruding parts of the circle are tappable; the cradle gap around it is part of the action area and does not select a tab. The pill's position and height are unchanged: the bulge uses the space above and below it.

See `example/` for a minimal app.
