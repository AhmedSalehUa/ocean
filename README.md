# Trail · PO Verification

Field verification mobile app for **REPRESENTATIVE** users. Two-tier Master PO → Vendor PO walk-through with photo + GPS proof, item-by-item resolution, and finalize-with-recompute.

Built in **Flutter** (iOS + Android), state via **Provider**, routing via **go_router**.

## First-time setup

This repo ships the `lib/` tree, theme, models, mock API, and UI screens. You need to generate the iOS + Android platform folders once on your machine:

```bash
flutter create . --org com.ocean --project-name trail --platforms=ios,android
flutter pub get
```

`flutter create .` will **not** overwrite anything inside `lib/` — it only adds the missing `ios/` and `android/` folders.

## Run

Open the folder in VS Code, then **Run → Start Debugging** (or pick a config from the **Run and Debug** sidebar):

- **Trail (mock api)** — runs against the in-memory mock (default; uses the data shape from the Claude Design prototype).
- **Trail (real api)** — points at the URL in `.env`.

From the CLI:

```bash
flutter run --dart-define=USE_MOCK=true
flutter run --dart-define=USE_MOCK=false
```

## Configuration

Edit `.env`:

```
API_BASE_URL=http://localhost:4000
USE_MOCK=true
```

`USE_MOCK` is overridden by `--dart-define=USE_MOCK=...` at run-time.

## Permissions

The app needs **camera** and **location** at runtime. The required entries are documented in `docs/PLATFORM_CONFIG.md` — paste them into the generated `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml` after `flutter create .`.

## Project layout

```
lib/
  main.dart, app.dart
  core/         theme, design-system widgets, utils, errors
  data/         api (mock + http), models, repositories
  features/    9 feature screens with their controllers
  l10n/         generated localizations (en + ar)
  routing/      go_router config
  services/     camera, location, locale
```

## Screens

1. Login (JWT)
2. Master PO Dashboard
3. Vendor PO List
4. Vendor Detail (steps + items)
5. Shipment Capture (camera + GPS)
6. Item Loop (per-item photo + Mark Missing)
7. Proof History
8. Finalize
9. Handoff

## i18n + RTL

EN/AR strings live in `lib/l10n/app_en.arb` and `app_ar.arb`. Toggle the locale from the dashboard header — `Directionality` flips the whole tree automatically.
