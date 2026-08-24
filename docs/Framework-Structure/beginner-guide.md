# MapAnytime Mobile App — Beginner's Guide

A quick orientation guide for new developers working on the **MapAnytime Flutter App**.

---

## 1. Quick Concepts

| Concept | Where It Lives | What It Does |
| :--- | :--- | :--- |
| **Riverpod** | `features/*/presentation/controllers/` | Manages app state and connects UI to backend APIs reactively. |
| **GoRouter** | `lib/routes/` | Manages screen transitions, deep links, and route redirects. |
| **Freezed** | `features/*/data/models/` | Generates immutable data classes with JSON serialization and copyWith methods. |
| **Dio** | `lib/core/network/` | Handles HTTP REST API requests with auth token headers and interceptors. |
| **Theme** | `lib/theme/` | Contains colors, fonts, card styles, button themes, and dark/light modes. |

---

## 2. Common Workflows

### How to Add a New Screen
1. Create your screen widget in `lib/features/<feature>/presentation/screens/<screen_name>_screen.dart`.
2. Add a route definition in `lib/routes/app_router.dart`.
3. If the screen requires backend data, create a Riverpod controller in `lib/features/<feature>/presentation/controllers/`.

### How to Connect a New Backend API Endpoint
1. Define the response model with `@freezed` in `lib/features/<feature>/data/models/`.
2. Run `dart run build_runner build --delete-conflicting-outputs` to generate serialization code.
3. Add the API call method to `lib/features/<feature>/data/datasources/<feature>_remote_datasource.dart`.
4. Expose the data through a repository and Riverpod provider.

---

## 3. Useful Commands

```bash
# Get dependencies
flutter pub get

# Rebuild code generation
dart run build_runner build --delete-conflicting-outputs

# Watch code generation (auto-rebuild on file save)
dart run build_runner watch --delete-conflicting-outputs

# Run app on connected device
flutter run

# Run tests
flutter test
```
