# Changelog

## 0.2.0

- Add `SlidingPillNavBarCenterAction` and `SlidingPillBottomNavBar.centerAction`: an optional solid circular action button in the centre of the bar, with a customisable background colour, foreground colour, diameter, elevation, tooltip, and semantics label.
- The bar's outline morphs around the circle with a smooth cradle (`cradleGap`, `cradleSmoothing`); fill, border, and shadow follow the morphed shape.
- Items split evenly either side of the action; the thumb, taps, and drags skip its slot. Using it with an odd number of items fails an assertion.
- The circle pokes past the bar's top and bottom edges and stays tappable there; it supports keyboard focus and activation.
- No change to layout or behaviour when `centerAction` is not set.

## 0.1.1

- Active/inactive icons and icon colours per item and theme.

## 0.1.0

- Initial release: floating pill bottom nav with sliding thumb, press preview, horizontal drag, and scaffold fade.
