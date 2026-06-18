# NTECH-SERVICES Flutter Architecture

> The conventions that `flut-cli` enforces — and the rationale behind each one.

---

## Table of Contents

1. [Guiding principles](#1-guiding-principles)
2. [Folder structure](#2-folder-structure)
3. [Layer responsibilities](#3-layer-responsibilities)
4. [State management](#4-state-management)
5. [Data modeling](#5-data-modeling)
6. [Error handling](#6-error-handling)
7. [Dependency injection](#7-dependency-injection)
8. [Navigation](#8-navigation)
9. [The service layer](#9-the-service-layer)
10. [Translation keys](#10-translation-keys)
11. [Banned packages](#11-banned-packages)
12. [What `flut check` enforces](#12-what-flut-check-enforces)

---

## 1. Guiding principles

| Principle | Implication |
|-----------|-------------|
| **Explicit over magic** | No code generation for data classes or DI wiring — every field and registration is visible in plain Dart. |
| **Features-first** | A feature is a self-contained vertical slice; you can read its business logic, data, and UI without jumping between top-level folders. |
| **One codegen tool max** | AutoRoute is allowed because manual route registration does not scale. Everything else stays plain Dart. |
| **Sealed state exhaustiveness** | The compiler enforces every state variant is handled — no silent "else" branches. |
| **Thin presentation layer** | Screens subscribe to state; they do not compute state. Logic lives in the Cubit/Bloc. |

---

## 2. Folder structure

```
lib/
├── core/                          ← shared infrastructure, imported by features
│   ├── api/
│   │   ├── api_client.dart        ← Dio instance builder
│   │   ├── api_endpoints.dart     ← all API paths in one place
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart        ← token injection + silent refresh
│   │       ├── retry_interceptor.dart       ← exponential back-off on 5xx
│   │       └── connectivity_interceptor.dart ← fails fast when offline
│   ├── auth/
│   │   └── auth_guard.dart        ← AutoRoute guard
│   ├── bloc/
│   │   └── app_bloc_observer.dart ← global BlocObserver for logging
│   ├── bootstrap.dart             ← runApp() setup, GetIt init, EasyLocalization
│   ├── config/
│   │   └── app_config.dart        ← dev / staging / prod flavors
│   ├── custom_transition_builders.dart  ← single shared RouteTransitionsBuilder
│   ├── di/
│   │   └── service_locator.dart   ← manual GetIt registrations
│   ├── error/
│   │   ├── failures.dart          ← AppFailure sealed class
│   │   └── exception_mapper.dart  ← maps Dio/platform errors → AppFailure
│   ├── router/
│   │   └── app_router.dart        ← @AutoRouterConfig root
│   ├── storage/
│   │   └── secure_storage.dart    ← flutter_secure_storage wrapper
│   └── theme/
│       └── app_theme.dart
│
├── features/                      ← one sub-folder per domain feature
│   └── <name>/
│       ├── business_logic/
│       │   ├── <name>_state.dart       ← plain sealed class
│       │   ├── <name>_cubit.dart       ← default
│       │   └── <name>_bloc.dart        ← opt-in with --bloc
│       ├── data/
│       │   ├── models/
│       │   │   └── <name>_model.dart   ← plain Dart, manual fromJson/toJson
│       │   ├── repositories/
│       │   │   └── <name>_repository.dart
│       │   └── services/              ← opt-in with --service
│       │       └── <name>_service.dart
│       └── presentation/
│           ├── router/
│           │   └── <name>_router_module.dart  ← @AutoRouterConfig per-feature
│           ├── screens/
│           │   └── <name>_screen.dart
│           └── widgets/               ← private components for this feature
│
└── shared/                        ← cross-feature, non-core code
    ├── models/                    ← DTOs used by multiple features
    ├── widgets/                   ← reusable UI components
    └── utils/                     ← pure functions, extensions
```

### The rule: imports flow inward

```
presentation  →  business_logic  →  data  →  core
```

- `presentation/` may import `business_logic/` and `core/`.
- `business_logic/` may import `data/` and `core/`.
- `data/` may import `core/`.
- Nothing in `features/` imports from another feature (use `shared/` instead).
- `core/` imports nothing from `features/` or `shared/`.

`flut check` enforces one specific rule: no file in `presentation/` may import `data/` directly.

---

## 3. Layer responsibilities

### `data/` — I/O only

- Makes HTTP calls via the injected Dio client.
- Maps raw JSON → domain model.
- Catches `DioException` and re-throws as `AppFailure` (via `exception_mapper.dart`).
- **No business logic.** A repository does not decide what to show the user.

### `business_logic/` — decisions only

- Holds the Cubit or Bloc.
- Calls repository/service methods and emits state.
- Catches `AppFailure`; never catches `Exception` directly.
- **No Flutter imports** (no `BuildContext`, no widgets).

### `presentation/` — UI only

- Reads state with `BlocBuilder` / `BlocConsumer`.
- Routes to other screens using AutoRoute.
- **No direct calls** to repositories, services, or Dio.

---

## 4. State management

### Sealed classes — not freezed

```dart
sealed class AuthState { const AuthState(); }

final class AuthInitial extends AuthState  { const AuthInitial(); }
final class AuthLoading extends AuthState  { const AuthLoading(); }
final class AuthLoaded  extends AuthState  { const AuthLoaded(this.user);    final UserModel user; }
final class AuthError   extends AuthState  { const AuthError(this.message);  final String message; }
```

Dart's `sealed` keyword (available since Dart 3.0) makes switch exhaustiveness checking a compile-time guarantee. Adding a new state variant causes the compiler to flag every `switch` that doesn't handle it — no runtime surprises.

`freezed` is banned because it adds code generation for a problem Dart already solves natively.

### Cubit vs Bloc

| Use Cubit | Use Bloc |
|-----------|----------|
| Single async action per state change | Multiple distinct user-triggered events that can share state transitions |
| Simple flows (login, load list, submit form) | Complex flows (a real-time feed, multi-step checkout) |

Default is Cubit (`flut feature <name>`). Opt into Bloc with `--bloc`.

### Emitting safely

```dart
try {
  final result = await _repository.doWork();
  if (!isClosed) emit(AuthLoaded(result));
} on AppFailure catch (f) {
  if (!isClosed) emit(AuthError(f.userMessage));
}
```

The `isClosed` guard prevents emitting after a widget tree disposes the Cubit (common in tests and rapid navigation).

---

## 5. Data modeling

### Plain Dart classes — no json_serializable

```dart
class UserModel {
  const UserModel({required this.id, required this.name});

  final String id;
  final String name;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:   json['id']   as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  UserModel copyWith({String? id, String? name}) => UserModel(
        id:   id   ?? this.id,
        name: name ?? this.name,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType &&
      id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}
```

**Why:** `json_serializable` adds a `build_runner` dependency and a generated `*.g.dart` file for every model. For most API responses the fields are known and stable — writing `fromJson` manually takes two minutes and produces code that is immediately readable and debuggable.

---

## 6. Error handling

### AppFailure — the single error type

```dart
// lib/core/error/failures.dart
sealed class AppFailure {
  const AppFailure(this.userMessage);
  final String userMessage;
}

final class NetworkFailure    extends AppFailure { ... }
final class ServerFailure     extends AppFailure { ... }
final class UnauthorizedFailure extends AppFailure { ... }
final class NotFoundFailure   extends AppFailure { ... }
final class UnknownFailure    extends AppFailure { ... }
```

### exception_mapper.dart

Repositories should not contain Dio-specific logic. `ExceptionMapper` converts infrastructure-level exceptions into `AppFailure` variants:

```dart
// In a repository
try {
  final response = await _dio.get('/users/$id');
  return UserModel.fromJson(response.data as Map<String, dynamic>);
} on DioException catch (e) {
  throw ExceptionMapper.map(e);
}
```

This keeps the Cubit/Bloc free of Dio imports and makes error scenarios testable with a simple `throw` mock.

---

## 7. Dependency injection

### Manual GetIt — no injectable

```dart
// lib/core/di/service_locator.dart
final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core
  sl.registerSingleton<Dio>(buildDioClient());
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // Auth feature
  sl.registerSingleton<AuthRepository>(AuthRepository(sl<Dio>()));
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl<AuthRepository>()));
}
```

**Registration rules:**
- `registerSingleton` — shared state across the app (repositories, API clients, storage).
- `registerFactory` — Cubits and Blocs (a new instance per screen to avoid shared state).
- `registerLazySingleton` — singletons initialized on first use (use sparingly).

**Why not injectable:** The `@injectable`/`@lazySingleton` annotations require `build_runner` to generate `*.config.dart` files. For most projects the DI graph is small enough that manual registration is faster to write and easier to read during code review.

---

## 8. Navigation

### AutoRoute — one codegen tool

AutoRoute is the sole codegen dependency. It is justified because manual route registration in a medium-to-large Flutter app requires:
- Maintaining route names as strings (typo-prone)
- Manually typing argument classes
- Keeping guards, transitions, and deep-link paths in sync

AutoRoute solves all of this with one `@AutoRouterConfig` annotation.

### Per-feature RouterModule

Instead of one monolithic `app_router.dart` listing every route, each feature owns a `<name>_router_module.dart`:

```dart
// lib/features/auth/presentation/router/auth_router_module.dart
@AutoRouterConfig()
class AuthRouterModule extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AuthRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
  ];

  @override
  RouteTransitionsBuilder? get transitionsBuilder =>
      CustomTransitionBuilders.fadeTransition;
}
```

The root `app_router.dart` imports these modules and composes them:

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    ...AuthRouterModule().routes,
    ...HomeRouterModule().routes,
  ];
}
```

**Benefit:** adding a new screen to a feature touches only that feature's router module, not the root config.

### Shared transition

`lib/core/custom_transition_builders.dart` defines a `RouteTransitionsBuilder` used by every module. To change the global transition — fade, slide, none — edit one file.

---

## 9. The service layer

Optional (`--service`). Use it when a Cubit/Bloc needs to:

- Combine data from **multiple repositories**
- Apply **business rules** before state sees the result (e.g., filter, sort, enrich)
- **Cache or debounce** calls shared across multiple Cubits

```
Repository  →  Service  →  Cubit / Bloc  →  Screen
```

Without `--service`, the Cubit injects the repository directly — simpler and sufficient for most CRUD features.

```dart
// with --service
class AuthService {
  AuthService(this._repo, this._profileRepo);

  Future<UserModel> loginAndLoadProfile(String email, String password) async {
    final token = await _repo.login(email, password);
    return _profileRepo.getProfile(token.userId);
  }
}
```

---

## 10. Translation keys

All user-visible strings are localized via `easy_localization`. The key convention is:

```
<feature>.<context>.<string>
```

Examples: `auth.login.title`, `auth.login.emailHint`, `common.loading`, `common.error.network`.

`flut check` scans for `tr('...')` calls in all Dart files and warns about keys missing from either `en.json` or `fr.json`.

---

## 11. Banned packages

| Package | Replacement | Why banned |
|---------|-------------|-----------|
| `freezed` | Plain `sealed` classes | Dart 3 seals classes natively. `freezed` adds ~2 000 lines of generated code per model and a `build_runner` dependency. |
| `json_serializable` | Manual `fromJson`/`toJson` | Generated `.g.dart` files bloat the repo and obscure mapping logic. Manual serialization is readable and requires no tooling. |
| `injectable` | Manual `GetIt` registration | `@injectable` annotations generate a `.config.dart` that is hard to audit. Explicit registration in `service_locator.dart` is self-documenting. |

`flut check` reports a warning if `freezed` or `json_serializable` appear in `pubspec.yaml`.

---

## 12. What `flut check` enforces

| Check | Severity | Rule |
|-------|----------|------|
| Feature structure | Error | Every feature must have `business_logic/`, `data/`, `data/models/`, `data/repositories/`, `presentation/`, `presentation/screens/`, `presentation/router/`, `presentation/widgets/` |
| Sealed states | Error | Every `*_state.dart` must declare a `sealed class` |
| Banned packages | Warning | `freezed` and `json_serializable` must not appear in `pubspec.yaml` |
| Layer boundaries | Error | No file in `presentation/` may `import` a path containing `data/` |
| Router registration | Warning | Every screen in `presentation/screens/` should appear in `app_router.dart` |
| DI registration | Warning | Every class registered in `service_locator.dart` must have a matching file |
| Translation keys | Warning | Every `tr('key')` call must have a matching entry in `en.json` and `fr.json` |
| Orphaned generated files | Warning | Every `*.gr.dart` must have a corresponding non-generated source file |
| Cubit/Bloc convention | Error | Cubits/Blocs must catch `AppFailure`, not bare `Exception` |
