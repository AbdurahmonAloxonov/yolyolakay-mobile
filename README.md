# YolYolakay · Mobile

A Flutter client for ride-sharing and parcel delivery, with feature modules for search, trips, chat, profiles and safety.

**Stack:** Flutter · Dart · Riverpod · Dio · GoRouter

## Features

- Driver/passenger trip and booking flows.
- Chat, parcels, billing, ratings and notifications.
- Configurable backend and WebSocket endpoints.
- Dedicated unit, widget and integration test directories.

## Local setup

Flutter compatible with the Dart SDK constraint in pubspec.yaml; Android/iOS tooling for device builds.

```bash
flutter pub get
flutter run --dart-define=MOCK_AUTH=true
```

## Validation commands

```bash
flutter analyze
flutter test
```

These are reproducible commands, not a claim that the full application suite passed during portfolio preparation. See the workspace validation report for checks actually run.

## Structure

```text
lib/app/          app wiring and navigation
lib/core/         environment, networking and utilities
lib/features/     product features
test/             unit and widget tests
integration_test/ device integration tests
```

## Limitations and configuration

MOCK_AUTH bypasses the authentication flow only; it is not a complete offline backend. Connected features need a compatible API. Firebase configuration and signing keys are intentionally excluded; configure them locally for push notifications and signed releases. Older operational notes are retained in docs/ORIGINAL_README.md and may describe earlier endpoints.

## Further documentation

[Original project documentation](docs/ORIGINAL_README.md) is preserved for implementation details and original context.
