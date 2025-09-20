# TrulyBudget - 🚧 In progress 🚧

A clean Flutter budgeting app

## Current features

* New month → add income → allocate (amount or %) → track expenses
* Emoji categories & quick emoji picker
* Month summary (income vs expenses, overspend alerts, spare)
* Currency switcher (GBP/EUR/USD/JPY/INR)

## Quick start

```bash
flutter pub get
flutter run
```

## Build (Android AAB)

```bash
flutter build appbundle \
  --build-name $(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1) \
  --build-number 1
```

CI builds on `main` and uploads `trulybudget-android-<semver>+<run_number>`.

## Structure

```
lib/
  models/ state/ utils/ widgets/ screens/
```

## Dev

* Pre-commit: `dart tool/lint_and_fix.dart`

## Notes

* Android CI only for now.
