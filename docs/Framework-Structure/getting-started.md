# MapAnytime Mobile App — Getting Started Guide

Welcome to the MapAnytime Mobile App codebase! This application is built with **Flutter** for cross-platform deployment on iOS and Android.

---

## 1. Prerequisites

- **Flutter SDK**: `>= 3.19.0` (Dart `>= 3.3.0`)
- **IDE**: VS Code (with Flutter & Dart extensions) or Android Studio
- **Android**: Android Studio with Android SDK & emulator (API 34 recommended)
- **iOS**: macOS with Xcode 15+ & CocoaPods installed

---

## 2. Environment Configuration

The app uses flavor-based entrypoints:
- `lib/main_dev.dart`: Connects to local/staging API (`http://10.0.2.2:3000/v1` for Android emulator or `http://localhost:3000/v1` for iOS simulator).
- `lib/main_prod.dart`: Connects to production MapAnytime API.

Create your `.env` files if required:
```bash
# Copy example environment
cp .env.example .env.dev
```

---

## 3. Running the App

### Install Dependencies
```bash
flutter pub get
```

### Code Generation (Freezed & Riverpod)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Launch Development Flavor
```bash
# Android Emulator
flutter run -t lib/main_dev.dart

# iOS Simulator
flutter run -t lib/main_dev.dart -d iPhone
```

---

## 4. Project Architecture Overview

```
lib/
├── core/               # Network client (Dio), storage, error handling, constants
├── features/           # Feature-first modules (auth, checkout, cart, map, orders, rewards)
│   ├── presentation/   # UI widgets, screens, Riverpod controllers
│   ├── domain/         # Entities, value objects, business logic
│   └── data/           # Repositories, DTOs, data sources
├── routes/             # GoRouter navigation configuration
├── theme/              # Typography, color tokens, dark/light themes
└── shared/             # Reusable UI widgets and utility extensions
```

---

## 5. Running Tests & Quality Checks

```bash
# Run unit & widget tests
flutter test

# Run static analysis
flutter analyze
```
