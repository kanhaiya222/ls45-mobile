# LS45 — Mobile App

Flutter customer app for **LS45** wellness travel, mirroring the web booking funnel: browse journeys,
view a journey's detail (itinerary / departures / FAQs), start a booking, add travellers, and check
out.

## Stack

- **Flutter 3.32** / Dart 3.8
- **riverpod** (state) · **go_router** (navigation) · **dio** (HTTP) · `flutter_secure_storage`
- Feature-first structure; hand-written `fromJson` models (no codegen)

## Run

```bash
flutter pub get
flutter run                 # device / emulator
flutter run -d chrome       # web (no device needed)
```

API base URL is resolved per platform in `AppConfig` (Android emulator → `http://10.0.2.2:8080/api/v1`;
web/desktop → `http://localhost:8080/api/v1`). The backend must be running.

## Verify

```bash
flutter analyze
flutter test
flutter build web           # build gate that needs no device
```

Android APK and iOS builds need the Android SDK / a macOS+Xcode toolchain respectively.

## Structure

```
lib/
  core/       AppConfig, dio + auth interceptor (refresh-on-401), token storage, theme
  features/<feature>/
    models/         data classes + fromJson
    data/           repositories (dio)
    application/    controllers (riverpod AsyncNotifier)
    state/          providers
    ui/             screens + widgets
```

Features: auth · catalog (search/paging) · package detail · booking start (occupancy + travellers) ·
checkout (reserve + payment) · my bookings (+ resume payment) · profile, behind a bottom-nav shell.
