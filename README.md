# flut-cli

[![CI](https://github.com/loicgeek/flut-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/loicgeek/flut-cli/actions/workflows/ci.yml)
[![Release](https://github.com/loicgeek/flut-cli/actions/workflows/release.yml/badge.svg)](https://github.com/loicgeek/flut-cli/actions/workflows/release.yml)
[![Version](https://img.shields.io/github/v/release/loicgeek/flut-cli?label=version)](https://github.com/loicgeek/flut-cli/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> Flutter project scaffold CLI — by [NTECH-SERVICES](https://github.com/loicgeek)

`flut` is an opinionated bash CLI that bootstraps Flutter projects and features.
Whichever architecture you pick, the same principles hold:

- **Plain Dart** models — no `json_serializable`, no codegen for data classes
- **Plain sealed classes** for state — no `freezed`
- **AutoRoute only** for navigation — one codegen dependency, nothing else
- **Manual GetIt** registration — no `injectable`
- **Cubit by default**, Bloc on demand
- Per-feature `RouterModule` with a shared custom transition builder

### Choose an architecture

The feature layout is a per-project choice, stored in `flut.json`:

| Profile | Feature slice | Pick it when |
|---------|---------------|--------------|
| **`ntech`** *(default)* | `business_logic/` · `data/` · `presentation/` | You want the NTECH-SERVICES standard — the leanest path from screen to API |
| **`clean`** | `domain/` · `data/` · `presentation/` | You want entities, repository interfaces and use cases, and a domain layer that never sees Dio or JSON |

```bash
flut init                        # ntech (default)
flut init --architecture clean   # Clean Architecture
flut architecture                # show installed profiles and the current one
```

Existing projects are unaffected: with no `flut.json`, `flut` behaves exactly
as it always has. Both profiles share the same core scaffold (API client, DI,
router, theme, storage, error handling) and the same commands — only the
feature layout and the available `generate` types differ.

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
flut upgrade
```

No reinstall needed — the symlink picks up changes immediately.

---

## Shell Completions

Tab-completion for bash and zsh. The installer prints the exact lines; you can also add them manually:

**bash** — add to `~/.bashrc`:
```bash
source ~/.flut-cli/completions/flut.bash
```

**zsh** — add to `~/.zshrc`:
```zsh
source ~/.flut-cli/completions/flut.zsh
```

Completions cover all commands, `--bloc`/`--service` flags, `generate` types, `assets` sub-commands (`check`, `stats`, `clean`), `--all`/`--dry-run` flags, and feature names from `lib/features/`.

---

## Uninstall

```bash
sudo rm /usr/local/bin/flut
rm -rf ~/.flut-cli
```

---

## Usage

```
flut init                               Init full lib/ scaffold + install packages
flut init --architecture <name>         Init with a specific architecture
flut architecture                       List installed architectures / show current
flut architecture --set <name>          Switch the project's architecture
flut feature <name>                     Add a feature (Cubit)
flut feature <name> --bloc              Add a feature (Bloc)
flut feature <name> --service           Add a feature with Service layer
flut feature <name> --bloc --service    Add a feature (Bloc + Service)
flut generate model <feat> [name]       Generate a model into an existing feature
flut generate screen <feat> [name]      Generate a screen into an existing feature
flut generate repository <feat> [name]  Generate a repository
flut generate cubit <feat> [name]       Generate a Cubit + state
flut generate bloc <feat> [name]        Generate a Bloc + events + state
flut generate entity <feat> [name]      Domain entity            (clean only)
flut generate usecase <feat> [name]     Use case                 (clean only)
flut generate datasource <feat> [name]  Remote data source       (clean only)
flut check                              Audit architecture conventions
flut doctor                             Check project health
flut assets check                       Detect unused Flutter assets
flut assets stats                       Statistics by category (images, icons, lottie)
flut assets clean [--all] [--dry-run]   Delete unused assets
flut upgrade                            Update flut-cli to latest version
flut --version                          Print the installed version
flut --help                             Show this help
```

> For a complete reference with all flags and examples, see [docs/commands.md](docs/commands.md).

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

### `flut feature <name> [--bloc] [--service]`

Scaffolds a complete feature slice under `lib/features/<name>/`. The layout
depends on the project's architecture.

**`ntech` (default):**

```
lib/features/<name>/
├── business_logic/
│   ├── <name>_state.dart         ← plain sealed class
│   ├── <name>_cubit.dart         ← default
│   └── <name>_bloc.dart          ← with --bloc (+ <name>_event.dart)
├── data/
│   ├── models/<name>_model.dart  ← plain Dart class, manual fromJson/toJson
│   ├── repositories/<name>_repository.dart
│   └── services/<name>_service.dart  ← with --service
└── presentation/
    ├── router/
    │   └── <name>_router_module.dart   ← per-feature AutoRouterConfig
    ├── screens/<name>_screen.dart      ← @RoutePage(), BlocProvider, BlocConsumer
    └── widgets/                        ← empty, ready for components
```

**`clean`:**

```
lib/features/<name>/
├── domain/                             ← pure Dart: no Flutter, no Dio, no JSON
│   ├── entities/<name>.dart
│   ├── repositories/<name>_repository.dart      ← abstract interface
│   └── usecases/<name>_usecase.dart             ← depends on the interface
├── data/
│   ├── models/<name>_model.dart                 ← extends the entity, adds JSON
│   ├── datasources/<name>_remote_datasource.dart
│   └── repositories/<name>_repository_impl.dart ← implements the interface
└── presentation/
    ├── bloc/                                    ← state + cubit (or bloc + events)
    ├── router/<name>_router_module.dart
    ├── screens/<name>_screen.dart               ← depends on the use case
    └── widgets/
```

Dependencies point inwards only — `presentation -> domain <- data` — and
`flut check` enforces it. `--service` is ignored in `clean`, since
`data/datasources/` already isolates data access.

**After generation, follow the printed checklist:**

1. Register in `lib/core/di/service_locator.dart` (repo → service if used → Cubit/Bloc)
2. Add endpoint in `lib/core/api/api_endpoints.dart`
3. Add route in `lib/core/router/app_router.dart`
4. Add translation keys in `assets/translations/fr.json` & `en.json`
5. Wire `<Name>RouterModule` into the root router if using sub-navigation
6. Run `dart run build_runner build --delete-conflicting-outputs`

---

### `flut generate`

Generates individual components into an existing feature (not full feature slices).

| Sub-command | Example | Creates |
|---|---|---|
| `model` | `flut generate model auth login_request` | `login_request_model.dart` with `fromJson`/`toJson`/`copyWith` |
| `screen` | `flut generate screen auth login` | `login_screen.dart` with `BlocProvider`, `BlocConsumer`, `@RoutePage()` |
| `repository` | `flut generate repository auth custom` | `custom_repository.dart` with Dio + AppFailure |
| `cubit` | `flut generate cubit auth login` | `login_cubit.dart` + shared state |
| `bloc` | `flut generate bloc auth login` | `login_bloc.dart` + `login_event.dart` + shared state |

If the name is omitted, it defaults to the feature name (e.g., `flut generate model auth` creates `auth_model.dart`).

**Clean Architecture adds three more:**

| Sub-command | Example | Creates |
|---|---|---|
| `entity` | `flut generate entity product category` | `domain/entities/category.dart` — pure Dart |
| `usecase` | `flut generate usecase product category` | `domain/usecases/category_usecase.dart`, plus the entity and repository interface it needs |
| `datasource` | `flut generate datasource product category` | `data/datasources/category_remote_datasource.dart`, plus the model and entity |

Each generator creates the pieces it depends on when they are missing, so
generated code always resolves.

---

### `flut assets <check|stats|clean>`

Detects and removes unused assets (images, icons, lottie files — translations excluded).

| Sub-command | What it does |
|---|---|
| `flut assets check` | Lists every asset not referenced in `lib/**/*.dart`, with its size. Exit `1` if any found (CI-friendly). |
| `flut assets stats` | Prints a statistics table by category (images / icons / lottie / other) — count, total size, unused count, unused size. |
| `flut assets clean` | Interactive deletion: prompts `[y/N/q]` for each unused asset, then prints a summary (files deleted, bytes freed). |
| `flut assets clean --all` | Shows all unused assets, asks for a single global confirmation, then deletes them all. |
| `flut assets clean --dry-run` | Simulates deletion without touching any file. |

**Detection method:** searches `lib/` for any `.dart` file containing the asset's filename or full relative path. Dynamic string interpolation (e.g. `'assets/images/$name'`) is not detectable — that's an accepted limitation.

```bash
# Spot unused assets
flut assets check

# Summary table
flut assets stats

# Delete one by one
flut assets clean

# Delete all at once
flut assets clean --all

# Preview without deleting
flut assets clean --dry-run
```

---

### `flut check`

Audits the Flutter project for architecture convention violations.

**Exit codes:** `0` = all clear, `1` = warnings, `2` = errors

**Checks performed:**
1. Feature structure completeness — against the project's architecture
2. State classes are sealed
3. No banned codegen packages (`freezed`, `json_serializable`)
4. Layer boundaries (presentation doesn't import data/ directly)
5. Router registration (screens referenced in app_router.dart)
6. DI registration (registered classes are declared somewhere in lib/)
7. Translation keys (tr() calls exist in both en.json and fr.json)
8. No orphaned generated files
9. Cubit/Bloc convention (uses AppFailure, not generic Exception)

**With `clean`, four more rules enforce the dependency rule:**

10. Domain entities are pure — no Flutter, no Dio, no JSON
11. Nothing under `domain/` imports the data layer
12. Use cases depend on repository interfaces, not implementations
13. Each `*_repository_impl.dart` declares the contract it implements

---

### `flut doctor`

Analyzes project health and reports status.

**Checks performed:**
1. Flutter SDK availability and version
2. Project root (valid pubspec.yaml)
3. Required packages (11 runtime + 2 dev dependencies)
4. Generated code (build runner has been run)
5. Scaffold integrity (expected dirs and files exist)
6. Outdated packages (flutter pub outdated summary)
7. Git initialization status

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

> For a deep dive into the rationale and all conventions, see [ARCHITECTURE.md](ARCHITECTURE.md).

```
lib/
├── core/          shared infrastructure (DI, router, API, theme, error…)
├── features/      one folder per domain feature — layout set by flut.json
│   └── <name>/
│       ├── business_logic/   ntech: Cubit or Bloc + sealed State
│       ├── domain/           clean: entities, repository interfaces, use cases
│       ├── data/             Models + Repositories (+ data sources in clean)
│       └── presentation/     Screens + per-feature RouterModule + Widgets
└── shared/        cross-feature widgets, models, utils
```

`core/` and `shared/` are identical in both profiles; only `features/<name>/`
differs. `clean` also adds `core/usecase/usecase.dart`, the contract every use
case implements.

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

```bash
git clone https://github.com/loicgeek/flut-cli.git
cd flut-cli
bats tests/          # run the test suite
bash flut.sh --help  # smoke-test
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow, code style, and testing guidelines.

---

## License

MIT © NTECH-SERVICES SARL