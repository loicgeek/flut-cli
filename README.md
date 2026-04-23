# flut-cli

> Flutter project scaffold CLI — by [NTECH-SERVICES](https://github.com/loicgeek)

`flut` is an opinionated bash CLI that bootstraps Flutter projects and features
following the NTECH-SERVICES architecture standard:

- **Features-first** folder structure
- **Plain Dart** models — no `json_serializable`, no codegen for data classes
- **Plain sealed classes** for state — no `freezed`
- **AutoRoute only** for navigation — one codegen dependency, nothing else
- **Manual GetIt** registration — no `injectable`
- **Cubit by default**, Bloc on demand
- Per-feature `RouterModule` with a shared custom transition builder

---

## Requirements

| Tool | Version |
|------|---------|
| bash | 4+ |
| git  | any     |
| flutter | any stable |

---

## Installation

### One-line (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/loicgeek/flut-cli/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/loicgeek/flut-cli.git ~/.flut-cli
chmod +x ~/.flut-cli/flut.sh
sudo ln -s ~/.flut-cli/flut.sh /usr/local/bin/flut
```

---

## Update

```bash
cd ~/.flut-cli && git pull
```

No reinstall needed — the symlink picks up changes immediately.

---

## Uninstall

```bash
sudo rm /usr/local/bin/flut
rm -rf ~/.flut-cli
```

---

## Usage

```
flut init                    Init full lib/ scaffold + install packages
flut feature <name>          Add a feature (Cubit)
flut feature <name> --bloc   Add a feature (Bloc)
flut --help                  Show this help
```

> **Important:** always run `flut` from the **root of your Flutter project**
> (the directory that contains `pubspec.yaml`).

---

## Commands

### `flut init`

Bootstraps a full `lib/` scaffold from scratch inside the current project.

**Creates:**

```
lib/
├── main_dev.dart
├── main_staging.dart
├── main_prod.dart
├── app.dart
└── core/
    ├── bootstrap.dart
    ├── custom_transition_builders.dart   ← shared fade transition
    ├── config/app_config.dart            ← dev / staging / prod flavors
    ├── api/
    │   ├── api_client.dart               ← Dio builder
    │   ├── api_endpoints.dart
    │   └── interceptors/
    │       ├── auth_interceptor.dart     ← token injection + silent refresh
    │       ├── retry_interceptor.dart    ← exponential back-off
    │       └── connectivity_interceptor.dart
    ├── auth/auth_guard.dart
    ├── bloc/app_bloc_observer.dart
    ├── di/service_locator.dart           ← GetIt setup
    ├── error/
    │   ├── failures.dart                 ← AppFailure sealed class
    │   └── exception_mapper.dart
    ├── router/app_router.dart
    ├── storage/secure_storage.dart
    └── theme/app_theme.dart
assets/
├── translations/fr.json
├── translations/en.json
├── images/
├── icons/
└── lottie/
```

**Installs packages:**

```
flutter_bloc  equatable  get_it  auto_route
dio  connectivity_plus  pretty_dio_logger
flutter_secure_storage  easy_localization  logger  intl

dev: build_runner  auto_route_generator
```

---

### `flut feature <name> [--bloc]`

Scaffolds a complete feature slice under `lib/features/<name>/`.

```
lib/features/<name>/
├── business_logic/
│   ├── <name>_state.dart         ← plain sealed class
│   ├── <name>_cubit.dart         ← default
│   └── <name>_bloc.dart          ← with --bloc (+ <name>_event.dart)
├── data/
│   ├── models/<name>_model.dart  ← plain Dart class, manual fromJson/toJson
│   └── repositories/<name>_repository.dart
└── presentation/
    ├── router/
    │   └── <name>_router_module.dart   ← per-feature AutoRouterConfig
    ├── screens/<name>_screen.dart      ← @RoutePage(), BlocProvider, BlocConsumer
    └── widgets/                        ← empty, ready for components
```

**After generation, follow the printed checklist:**

1. Register in `lib/core/di/service_locator.dart` (repo → service if used → Cubit/Bloc)
2. Add endpoint in `lib/core/api/api_endpoints.dart`
3. Add route in `lib/core/router/app_router.dart`
4. Add translation keys in `assets/translations/fr.json` & `en.json`
5. Wire `<Name>RouterModule` into the root router if using sub-navigation
6. Run `dart run build_runner build --delete-conflicting-outputs`

---


### Service layer (`--service`)

When passed, a `services/` folder is created inside the feature with a `<n>_service.dart` file.
The generated Cubit/Bloc injects the **service** instead of the repository directly.

```
Repository  →  Service  →  Cubit / Bloc  →  Screen
```

Use the service for:
- Combining data from multiple repositories
- Business rules / transformations before the state layer sees them
- Caching, deduplication, or enrichment logic

Without `--service`, the Cubit/Bloc injects the repository directly — keeping simple features lean.

---
## Architecture overview

```
lib/
├── core/          shared infrastructure (DI, router, API, theme, error…)
├── features/      one folder per domain feature
│   └── <name>/
│       ├── business_logic/   Cubit or Bloc + sealed State
│       ├── data/             Model + Repository
│       └── presentation/     Screen + per-feature RouterModule + Widgets
└── shared/        cross-feature widgets, models, utils
```

### State management pattern

```dart
// State — plain sealed class (no freezed)
sealed class AuthState { const AuthState(); }
final class AuthInitial  extends AuthState { const AuthInitial(); }
final class AuthLoading  extends AuthState { const AuthLoading(); }
final class AuthLoaded   extends AuthState { const AuthLoaded(this.user); final UserModel user; }
final class AuthError    extends AuthState { const AuthError(this.message); final String message; }

// Cubit — try/catch on AppFailure only
class AuthCubit extends Cubit<AuthState> {
  Future<void> login(...) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.login(...);
      if (!isClosed) emit(AuthLoaded(user));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AuthError(f.userMessage));
    }
  }
}
```

### Transitions

`lib/core/custom_transition_builders.dart` defines a single `RouteTransitionsBuilder`
used by every `<Feature>RouterModule`. To change the global transition, edit one file:

```dart
// Fade (default)
return FadeTransition(opacity: animation, child: child);

// Slide from right
return SlideTransition(
  position: Tween(begin: const Offset(1, 0), end: Offset.zero)
      .animate(animation),
  child: child,
);

// No transition
return child;
```

---

## Contributing

This CLI is maintained by the NTECH-SERVICES team. PRs and issues welcome.

1. Fork the repo
2. Create a branch: `git checkout -b feat/my-change`
3. Test locally: `bash flut.sh --help`
4. Open a PR

---

## License

MIT © NTECH-SERVICES SARL