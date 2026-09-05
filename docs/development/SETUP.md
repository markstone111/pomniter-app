# Pomniter App — Development Setup Guide

## Prerequisites

Before you begin, ensure you have the following installed:

| Tool | Version | Installation |
|---|---|---|
| Flutter SDK | >= 3.47 | https://flutter.dev/docs/get-started/install |
| Dart SDK | >= 3.13 | Bundled with Flutter |
| Android Studio | Latest | https://developer.android.com/studio |
| Xcode (macOS only) | Latest | App Store |
| Docker Desktop | Latest | https://www.docker.com/products/docker-desktop/ |
| Node.js | >= 22.x | https://nodejs.org/ |
| Python | >= 3.12 | https://www.python.org/ |
| Git | Latest | https://git-scm.com/ |

## Step 1: Clone the Repository

`ash
git clone https://github.com/markstone111/pomniter-app.git
cd pomniter-app
`

## Step 2: Install Melos

Melos is used to manage the Flutter monorepo (multiple packages/apps).

`ash
dart pub global activate melos
`

Ensure the Dart global bin is on your PATH. Add to your shell profile if needed:
`ash
export PATH="":"C:\Users\nikun/.pub-cache/bin"
`

## Step 3: Bootstrap All Packages

`ash
melos bootstrap
`

This will run `flutter pub get` in every package and app, linking local dependencies.

## Step 4: Run the Flutter App

`ash
cd apps/mobile
flutter run
`

Use `flutter devices` to see available devices/emulators.

## Step 5: Start Backend Services (Optional for Phase 1)

`ash
# Ensure Docker Desktop is running
make up

# View logs
make logs

# Stop services
make down
`

## Troubleshooting

### Flutter doctor
`ash
flutter doctor -v
`

### Melos issues
`ash
melos clean
melos bootstrap
`

### Docker issues
Ensure Docker Desktop is running and the `docker` command is available in your terminal.

## IDE Setup

### VS Code (Recommended)
Install extensions:
- Flutter
- Dart
- Docker
- YAML

### Android Studio
- Install Flutter and Dart plugins
- Configure Flutter SDK path in Settings > Languages & Frameworks > Flutter

## Next Steps

- Read the Architecture Decision Records in `docs/architecture/`
- Review the API specifications in `docs/api/`
- Check the Contributing Guidelines in `docs/development/CONTRIBUTING.md`
