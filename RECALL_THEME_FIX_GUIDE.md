# Recall — Material 3 Expressive Theme Glitch: Diagnosis & Safe Fix Guide

## Purpose

This document is for the AI coding agent working on **Recall**.

The goal is to fix the current theme glitches shown on the Settings screen without changing unrelated application behavior, navigation, persistence, AI/BYOK functionality, database logic, or the existing visual design direction.

The repository was reviewed against the current `master` branch on 2026-08-18.

Relevant files:

- `lib/app.dart`
- `lib/core/theme.dart`
- `lib/core/providers/theme_controller.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/core/router.dart`
- `pubspec.yaml`

Current dependency: `material_3_expressive: ^1.0.7`.

---

# 1. Executive diagnosis

## Primary issue: duplicated theme ownership

Recall currently uses two theme layers:

```text
DynamicColorBuilder
       ↓
resolved Flutter ColorScheme
       ↓
ThemeData
       ↓
MaterialApp.router
       ↓
M3ETheme / M3EThemeData
       ↓
routed widgets
```

The important point is **not** that Flutter and Material 3 Expressive cannot coexist. They can.

The problem is that Recall currently makes both systems participate in theme resolution and then mixes ordinary Flutter Material widgets with M3E widgets inside the same screen.

`MaterialApp.router` receives:

- `theme: lightTheme`
- `darkTheme: darkTheme`
- `themeMode: themeMode`

Then its `builder` separately calculates `isDark`, chooses `activeTheme`, converts that theme into `M3EThemeData`, and inserts a second inherited theme:

```dart
M3ETheme(
  data: M3EThemeData.fromMaterial(activeTheme),
  child: child,
)
```

This is a second theme authority below `MaterialApp`.

The code comments in `app.dart` already recognize the risk, but the current implementation still keeps the two-layer arrangement.

**Treat this as the main architectural problem to fix first.**

---

# 2. Evidence from the current code

## `lib/app.dart`

Current flow:

```dart
final ThemeMode themeMode = ref.watch(themeControllerProvider);
final ThemePreset preset = ref.watch(themePresetControllerProvider);

return DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    final lightScheme = AppTheme.createScheme(...);
    final darkScheme = AppTheme.createScheme(...);

    final lightTheme = AppTheme.buildThemeData(lightScheme);
    final darkTheme = AppTheme.buildThemeData(darkScheme);

    return MaterialApp.router(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      builder: (context, child) {
        final isDark = ...;
        final activeTheme = isDark ? darkTheme : lightTheme;

        return M3ETheme(
          data: M3EThemeData.fromMaterial(activeTheme),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  },
);
```

The app therefore has:

1. a Flutter `ThemeData` selected by `MaterialApp.themeMode`, and
2. a separate `M3EThemeData` inherited widget selected by custom logic inside `builder`.

Do not assume that a rebuild failure is the only explanation. The more fundamental problem is that theme state is resolved in two places and consumed by two widget systems.

---

# 3. Theme mode is resolved twice

Flutter already resolves:

```dart
themeMode: themeMode
```

Yet `app.dart` also manually resolves:

```dart
final isDark =
    themeMode == ThemeMode.dark ||
    (themeMode == ThemeMode.system &&
        MediaQuery.platformBrightnessOf(context) == Brightness.dark);
```

This duplicates the decision made by `MaterialApp`.

That creates an avoidable dependency on two theme-resolution paths:

```text
MaterialApp theme resolution
        +
custom MediaQuery/platformBrightness resolution
```

These should not both be responsible for deciding active brightness.

### Required direction

Create one canonical theme state and derive all theme consumers from it.

Do not introduce another `ThemeMode` resolver elsewhere.

---

# 4. Why the screenshots look like they are "ghosting"

The screenshots show combinations such as:

- light app bar with a dark body/background,
- light cards over a dark surface,
- theme-dependent text/icons appearing out of sync,
- visual state changing between screenshots while the same route remains visible.

This is consistent with a theme/compositing desynchronization, but **do not label GoRouter as the root cause**.

`lib/core/router.dart` contains ordinary `GoRoute` builders and no custom transparent route or custom page-transition overlay. There is currently no strong evidence of a transparent GoRouter page being left on top.

The app does, however, configure a fade-forward page transition in `ThemeData`:

```dart
pageTransitionsTheme: const PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    ...
  },
)
```

That transition can make a theme/compositing mismatch **look** like a ghosting problem during route/theme updates.

### Required direction

Do not remove GoRouter or rewrite navigation as part of this fix.

Do not remove page transitions unless testing proves they independently reproduce the issue after the theme architecture is corrected.

---

# 5. Mixed Material and M3E component usage

`lib/features/settings/settings_screen.dart` imports both Flutter Material and Material 3 Expressive.

The screen currently uses:

```dart
Scaffold(...)
Card(...)
SegmentedButton(...)
FilterChip(...)
FilledButton(...)
SwitchListTile(...)
```

while also using:

```dart
M3EAppBar.top(...)
```

This means the same screen contains widgets that read standard Flutter `Theme.of(context)` values and an M3E widget that reads `M3ETheme` tokens.

That is allowed, but it makes theme synchronization especially important.

### Required direction

Do not blindly convert the entire Settings screen to M3E components.

The immediate goal is to synchronize the theme foundations first while preserving the current UI.

After synchronization, only migrate individual components where there is an intentional design reason.

---

# 6. Dynamic color generation is not the primary bug

`lib/core/theme.dart` correctly creates light and dark schemes separately and supports the dynamic wallpaper palette:

```dart
final lightScheme = AppTheme.createScheme(
  preset: preset,
  brightness: Brightness.light,
  dynamicScheme: lightDynamic?.harmonized(),
);

final darkScheme = AppTheme.createScheme(
  preset: preset,
  brightness: Brightness.dark,
  dynamicScheme: darkDynamic?.harmonized(),
);
```

The `ThemePreset.dynamicColor` path uses the supplied dynamic scheme when available.

Do **not** remove dynamic color or replace it with hard-coded colors.

Preserve:

- Dynamic wallpaper colors
- Ocean
- Emerald
- Indigo
- Slate
- Amber
- Amethyst
- System / Light / Dark mode

The bug is in how the resolved themes are propagated and consumed, not in the basic preset model.

---

# 7. The chip selector has a separate layout problem

The color preset chips are built with Flutter `FilterChip` and a custom `avatar`:

```dart
FilterChip(
  selected: isSelected,
  showCheckmark: false,
  avatar: Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: p.color,
      shape: BoxShape.circle,
    ),
  ),
  ...
)
```

The screenshot shows the colored dot can appear slightly vertically displaced / visually off-center.

This is an independent UI/layout issue.

### Why it happens

`FilterChip` owns the internal avatar layout, padding, spacing, density, and label alignment. The custom `14x14` widget is inserted into that layout instead of being positioned by a custom chip layout.

Theme changes can make the mismatch more noticeable because selected and unselected chip metrics/colors change.

### Required direction

Do not solve this by adding arbitrary pixel offsets until the theme problem is fixed.

After the theme architecture is stable:

1. verify whether the dot still misaligns,
2. then either tune chip `padding`, `avatarBoxConstraints`, `visualDensity`, or equivalent supported chip properties,
3. or replace the preset selector with a small custom selectable pill only if Flutter's `FilterChip` cannot achieve the intended alignment.

Preserve the current labels, presets, wrapping behavior, and selection affordance.

---

# 8. Theme controller persistence is a separate issue

`lib/core/providers/theme_controller.dart` currently defaults to:

```dart
ThemeMode.system
```

and:

```dart
ThemePreset.oceanBlue
```

The controller only changes in-memory Riverpod state.

There is no persistence in this controller.

This is **not the root cause of the visual glitch**.

Do not mix persistence work into the theme bug fix unless it is already part of the app's intended architecture.

If persistence is later added, it should be treated as a separate change.

---

# 9. Safe fix strategy

## Principle

Create exactly one canonical resolved `ColorScheme` pair:

```text
light ColorScheme
      +
dark ColorScheme
```

and make both Flutter Material and M3 Expressive derive from those same resolved values.

The brightness choice must also have one authority.

### Preferred architecture

```text
ThemeMode + ThemePreset
            ↓
   DynamicColorBuilder
            ↓
 resolve light ColorScheme
 resolve dark ColorScheme
            ↓
   build Flutter ThemeData
            ↓
 MaterialApp.router
            ↓
 provide matching M3E theme
            ↓
        app routes
```

The key requirement is that the M3E theme must be derived from the exact same resolved palette and brightness as the active Material theme, not independently regenerated from another seed or another adaptive decision.

---

# 10. Important package guidance

The currently published `material_3_expressive` package documents two relevant patterns:

### Recommended full-app pattern

`M3EMaterialApp` can own adaptive theming, dynamic color, and Material `ThemeMode` alignment.

### Subtree pattern

`M3ETheme` can be used when an existing app shell already owns the rest of the application.

Recall already has a custom `MaterialApp.router`, Riverpod theme state, custom color presets, and GoRouter. Therefore **do not automatically replace the whole root with `M3EMaterialApp`** just because the package recommends it.

That is a larger architectural change and risks breaking routing, Riverpod integration, dynamic presets, or existing styling.

Use the smallest change that produces one synchronized theme pipeline.

---

# 11. Recommended implementation approach

## Step A — keep the existing theme model

Keep:

- `ThemeMode`
- `ThemePreset`
- `DynamicColorBuilder`
- `AppTheme.createScheme()`
- `AppTheme.buildThemeData()`
- all current custom seeds
- all current screens and routes

Do not redesign the app theme API unless necessary.

## Step B — establish the resolved schemes as the source of truth

In `app.dart`, resolve:

```text
lightScheme
 darkScheme
```

exactly once per build of the root theme layer.

Then construct:

```text
lightTheme = buildThemeData(lightScheme)
darkTheme  = buildThemeData(darkScheme)
```

from those schemes.

## Step C — synchronize M3E with the same resolved theme

The M3E theme must be created from the same active material theme/scheme.

Do not independently call `M3EThemeData.light(seedColor: ...)` or `dark(seedColor: ...)` for the same screen if that would regenerate a different palette.

If `M3EThemeData.fromMaterial(...)` is the correct API for the installed package version, keep using it, but make sure it is generated from the same resolved `ThemeData` that `MaterialApp` is using.

If the package version has a better supported bridge from `ThemeData`/`ColorScheme` to M3E tokens, use that documented API instead.

## Step D — eliminate the second brightness decision

Do not use a second manual `isDark` calculation where possible.

Prefer a single resolved brightness/scheme and derive the M3E theme from that state.

If the Flutter framework's `Theme.of(context).brightness` can safely be used after `MaterialApp` resolves the theme, prefer that over independently reading `MediaQuery.platformBrightnessOf(context)` again.

The exact implementation must be verified against Flutter's build behavior before changing it.

## Step E — do not remove the root `MaterialApp.router`

Keep `MaterialApp.router` unless there is a concrete package-compatibility reason to migrate.

This is a routing/theme bug fix, not a navigation rewrite.

---

# 12. Do not apply these dangerous "fixes"

The AI IDE must NOT:

- add `Future.delayed()` to force a repaint,
- call `setState()` just to force theme updates,
- call `Navigator.pop()` / push replacement to refresh Settings,
- rebuild GoRouter whenever the theme changes,
- insert opaque `Container`s over the screen as a workaround,
- hard-code light/dark background colors in Settings,
- remove dynamic color,
- remove custom theme presets,
- globally replace `Theme.of(context)` with `M3ETheme.of(context)` without auditing every widget,
- replace every Material widget with an M3E equivalent in one pass,
- add arbitrary transforms/offsets to chip avatars before fixing the theme architecture,
- introduce a third theme provider,
- change Android system bar behavior as a workaround,
- add random `Key`s to route widgets to force remounts.

These would hide symptoms or introduce regressions instead of fixing the underlying theme flow.

---

# 13. Settings screen preservation requirements

The following must continue working exactly as before:

### Theme mode

- System
- Light
- Dark

### Theme presets

- Dynamic
- Ocean
- Emerald
- Indigo
- Slate
- Amber
- Amethyst

### AI section

The Gemini BYOK configuration UI must not be changed as part of this fix.

### Notifications

The notification settings must not be changed.

### Export and backup

Markdown/JSON export must not be changed.

### Privacy/local storage

The local-storage section must not be changed.

### Navigation

Settings must remain reachable through the current GoRouter route `/settings`.

---

# 14. Visual acceptance criteria

After the fix, repeatedly test all combinations.

## Mode tests

1. System + phone light
2. System + phone dark
3. Light while phone is dark
4. Dark while phone is light
5. Dark → Light
6. Light → Dark
7. System → Light
8. System → Dark

## Preset tests

For each mode, switch:

```text
Dynamic
Ocean
Emerald
Indigo
Slate
Amber
Amethyst
```

The screen must update as one coherent frame.

There must be no moment where:

- app bar is light while body is dark,
- card surface remains from the previous theme,
- text uses the previous brightness,
- selected chip background uses a previous palette,
- icons use an old primary/on-primary pair,
- the Settings route appears duplicated or translucent.

## Route tests

From Home:

```text
Home → Settings
Settings → Home
Home → Detail
Detail → Settings
```

Change theme while staying on Settings and while navigating between routes.

No route should flash a stale theme.

## Dynamic color tests

On a supported Android device:

1. Change the system wallpaper.
2. Select Dynamic.
3. Switch System/Light/Dark.
4. Re-enter Settings.

The palette should remain internally consistent.

---

# 15. Chip acceptance criteria

After the theme fix, inspect every preset chip.

The colored circular dot or dynamic icon must:

- remain vertically centered,
- have consistent spacing from the label,
- retain the same apparent size selected/unselected,
- not shift when switching Light/Dark,
- not shift when switching Dynamic/custom presets.

Do not sacrifice accessibility or tap target size to achieve the visual alignment.

---

# 16. Regression checklist

Run:

```bash
flutter analyze
flutter test
```

Then build/run on Android.

Also verify:

- app starts normally,
- share intent still works,
- Home list still loads,
- search still works,
- detail screen still works,
- Gemini configuration still opens,
- notifications still work,
- exports still work,
- no exceptions occur when switching themes repeatedly.

If the project has generated Riverpod files or other generated code, do not manually modify generated files unless regeneration is required.

---

# 17. Suggested tests to add

Add at least one widget-level regression test for the theme pipeline.

A useful test should:

1. render the app/theme shell,
2. switch ThemeMode light → dark → light,
3. confirm the active Material `ColorScheme.brightness` follows the requested mode,
4. confirm the M3E theme brightness/color scheme follows the same resolved state,
5. ensure there is only one coherent active palette.

If direct inspection of M3E internals is difficult, expose a small testable theme-resolution helper rather than testing private implementation details.

Also consider a Settings widget test that verifies the selected preset updates without reconstructing the route.

---

# 18. Definition of done

The task is complete only when all of the following are true:

- [ ] There is one authoritative theme-resolution pipeline.
- [ ] Flutter `ThemeData` and M3E theme data always derive from the same resolved palette/brightness.
- [ ] No duplicate/manual brightness resolver is required for the same theme state.
- [ ] Light/Dark/System switches update the whole visible Settings screen coherently.
- [ ] Dynamic wallpaper colors still work.
- [ ] All seven presets still work.
- [ ] GoRouter remains unchanged unless a real navigation regression is found.
- [ ] Gemini/BYOK UI remains unchanged functionally.
- [ ] Notifications and export settings remain unchanged.
- [ ] The chip dot alignment is corrected or demonstrably verified as a separate remaining issue.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] Android manual testing confirms no theme ghosting or stale surfaces.

---

# 19. Implementation philosophy

**Do not rewrite the app.**

This should be a focused theme-architecture correction.

The safest order is:

```text
1. Inspect current package APIs/version
2. Fix theme ownership/synchronization
3. Run analyzer/tests
4. Test all theme combinations
5. Only then fix chip geometry
6. Test navigation and unrelated features
```

If a proposed change touches unrelated files, stop and reassess whether the change is actually necessary.

The desired result is the same Recall application with the same design, same features, and same navigation — but with a single synchronized Material 3 / Material 3 Expressive theme state and no visual stale-frame artifacts.

---

## Source references used for this diagnosis

- 
- `lib/app.dart`
- `lib/core/theme.dart`
- `lib/core/providers/theme_controller.dart`
- `lib/features/settings/settings_screen.dart`
- `lib/core/router.dart`
- `pubspec.yaml`
- Material 3 Expressive package documentation: https://pub.dev/packages/material_3_expressive

The package documentation currently describes `M3EMaterialApp` as the recommended full-app adaptive theme integration and `M3ETheme` as the subtree approach. The current Recall app uses a custom `MaterialApp.router` plus `M3ETheme`, so preserve the existing app shell unless a migration is proven necessary.
