# mocky-ui

Reusable Flutter UI widgets. Install packages **only from GitHub** (no filesystem `path:` dependencies in consuming apps).

Repository: [https://github.com/ToppYankah/mocky-ui.git](https://github.com/ToppYankah/mocky-ui.git)

## Packages

| Package | Path in repo | Description |
| --- | --- | --- |
| `sliding_pill_bottom_nav` | `packages/sliding_pill_bottom_nav` | Floating pill bottom nav with sliding thumb, drag, scaffold fade, and optional centre action button |

## Install (git only)

```yaml
dependencies:
  sliding_pill_bottom_nav:
    git:
      url: https://github.com/ToppYankah/mocky-ui.git
      ref: sliding_pill_bottom_nav-v0.1.0
      path: packages/sliding_pill_bottom_nav
```

Pin `ref` to a tag or commit SHA for reproducible builds. Do not use `dependency_overrides` with a local path.

**CI:** configure SSH deploy key access to this repo so `flutter pub get` can resolve git dependencies.

## Contributing

Add new widgets under `packages/<name>/`, tag releases per package (e.g. `my_widget-v0.1.0`).
