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

- Pass `IconData` on [SlidingPillNavBarItem.icon], or use `iconBuilder` for SVG/custom widgets.
- Fonts come from your app `TextTheme` via `SlidingPillNavBarTheme.labelStyleBuilder`, or per-item `labelStyle`.

See `example/` for a minimal app.
