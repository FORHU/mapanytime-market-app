# MapAnytime Mobile App — Engineering Handbook

This handbook defines the architectural patterns, state management principles, and code style rules for the **MapAnytime Flutter App**.

---

## 1. State Management (Riverpod)

- **Provider Types**:
  - `NotifierProvider` / `AsyncNotifierProvider`: Use for stateful feature controllers with async mutations.
  - `FutureProvider`: Use for simple read-only data fetching with auto-caching.
  - `Provider`: Use for dependency injection of services, repositories, and network clients.
- **Rules**:
  - Keep controllers lean; business logic belongs in domain services or repository implementations.
  - Never call `ref.read` inside `build()` methods—use `ref.watch()` for reactive UI updates.

---

## 2. Feature-First Folder Structure

Every feature lives under `lib/features/<feature_name>/` with three distinct layers:

```
feature_name/
├── data/
│   ├── datasources/    # Remote API endpoints (Dio) & local caches
│   ├── models/         # JSON-serializable DTOs (Freezed)
│   └── repositories/   # Concrete repository implementations
├── domain/
│   ├── entities/       # Pure Dart domain models
│   └── repositories/   # Abstract repository interfaces
└── presentation/
    ├── controllers/    # Riverpod state notifiers
    ├── screens/        # Full-page screen widgets
    └── widgets/        # Component-level reusable widgets
```

---

## 3. Navigation & Routing (GoRouter)

- All routes are defined declaratively in `lib/routes/`.
- Use type-safe route parameters and query params.
- Route guards handle authentication redirects (e.g. unauthenticated users trying to access checkout are redirected to login).

---

## 4. Network Layer & Error Handling (Dio)

- All HTTP calls go through the shared Dio client in `lib/core/network/`.
- Automatic interceptors attach bearer tokens and correlation IDs (`X-Correlation-Id`).
- Errors are mapped to domain-level `Failure` objects (e.g. `NetworkFailure`, `AuthFailure`, `ValidationFailure`) rather than throwing raw exceptions in presentation widgets.

---

## 5. UI & Design System

- Use theme tokens from `Theme.of(context).colorScheme` and `Theme.of(context).textTheme` rather than hardcoding colors.
- Maintain responsive layouts supporting multiple device sizes (phones and tablets).
- Add semantic labels for accessibility where appropriate.
