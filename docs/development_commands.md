# MapAnytime Market - Development Commands

This document lists the common commands you'll need while developing the `mapanytime-market-app` Flutter application.

## Running the App

### 1. Development Mode (Recommended)
This is the easiest way to run the app during development. It uses the `main_dev.dart` entry point, which has the Mapbox token hardcoded and logging enabled.
```bash
flutter run -t lib/main_dev.dart
```

### 2. Using Environment Variables File
If you want to run the default entry point (`main.dart`) but ensure environment variables (like your Mapbox token) are loaded properly, pass the `.env.dev` file.
```bash
flutter run --dart-define-from-file=.env.dev
```

### 3. Production Mode
To test the production configuration (no logging, real backend, etc.) using the production environment variables:
```bash
flutter run --dart-define-from-file=.env.prod
```
Alternatively, if you want to use the explicit production entry point:
```bash
flutter run -t lib/main_prod.dart
```

## Project Maintenance

### Fetch Dependencies
Download all the packages listed in `pubspec.yaml`. Run this whenever you add a new package or pull new changes.
```bash
flutter pub get
```

### Clean Build Cache
If you encounter strange build errors, especially with native Android/iOS compilation or after upgrading Flutter, cleaning the build cache often fixes them.
```bash
flutter clean
flutter pub get
```

## Testing & Code Quality

### Run Tests
Execute all unit and widget tests in the project.
```bash
flutter test
```

### Analyze Code
Run the Dart analyzer to catch syntax errors, lint warnings, and other potential issues (based on the `very_good_analysis` rules).
```bash
flutter analyze
```

## Logs & Debugging
If you are running the app without an attached IDE and need to see the log output (e.g., from Mapbox or your custom loggers):
```bash
flutter logs
```
