# flut-cli — Command Reference

> Complete reference for every command. Run from the **root of your Flutter project** (the directory that contains `pubspec.yaml`).

---

## Table of Contents

- [`flut init`](#flut-init)
- [`flut architecture`](#flut-architecture)
- [`flut feature`](#flut-feature-name---bloc---service)
- [`flut generate`](#flut-generate-type-feature-name)
- [`flut check`](#flut-check)
- [`flut doctor`](#flut-doctor)
- [`flut clean`](#flut-clean---rebuild)
- [`flut assets`](#flut-assets-subcommand)
- [`flut upgrade`](#flut-upgrade)
- [`flut --version`](#flut---version)
- [Exit codes](#exit-codes)

---

## `flut init`

Bootstraps a full project scaffold inside the current Flutter project.

### Synopsis

```
flut init
flut init --architecture <name>
flut init -a <name>
flut init --architecture=<name>
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--architecture` / `-a` | No | Architecture profile to scaffold (default `ntech`). Writes the project's `flut.json`. |

### What it creates

```
lib/
├── main.dart
├── main_dev.dart
├── main_staging.dart
├── main_prod.dart
├── app.dart
└── core/
    ├── bootstrap.dart
    ├── custom_transition_builders.dart
    ├── config/
    │   └── app_config.dart              ← dev / staging / prod flavor config
    ├── api/
    │   ├── api_client.dart
    │   ├── api_endpoints.dart
    │   └── interceptors/
    │       ├── auth_interceptor.dart
    │       ├── retry_interceptor.dart
    │       └── connectivity_interceptor.dart
    ├── auth/auth_guard.dart
    ├── bloc/app_bloc_observer.dart
    ├── di/service_locator.dart
    ├── error/
    │   ├── failures.dart
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
.vscode/launch.json          ← VS Code dev/staging/prod run configs
.idea/runConfigurations/     ← Android Studio / IntelliJ run configs
```

### Behaviour

- **Idempotent** — safe to run twice; existing files are not overwritten.
- Prints a checklist of next steps (add packages, run build_runner, etc.).

### Examples

```bash
# From the root of an existing Flutter project
flut init

# Scaffold with a specific architecture profile
flut init --architecture ntech
```

### Notes

- Every `flut init` writes a `flut.json` file with the chosen architecture.
- Re-running `flut init` **without** `--architecture` keeps the architecture already recorded in `flut.json`.

### Next steps after `flut init`

1. Run `flutter pub add flutter_bloc equatable get_it auto_route dio connectivity_plus pretty_dio_logger flutter_secure_storage easy_localization logger intl`
2. Run `flutter pub add --dev build_runner auto_route_generator`
3. Run `dart run build_runner build --delete-conflicting-outputs`
4. Set `easy_localization` up in `app.dart` (see printed checklist)

---

## `flut architecture`

Manages the architecture profile of the current project. The active profile is stored in `flut.json` (created by `flut init`).

### Synopsis

```
flut architecture
flut architecture list
flut architecture --set <name>
```

### Sub-commands

| Argument | Description |
|----------|-------------|
| *(none)* / `list` | List installed architecture profiles and mark the current one. |
| `--set <name>` / `-s <name>` | Set the project's architecture in `flut.json`. |

### Examples

```bash
flut architecture
# >> Architectures
#   current: ntech
#
#     * ntech  Features-first: core, shared, features (default)

flut architecture --set clean
```

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Unknown argument, unknown architecture, or missing value for `--set` |

---

## `flut feature <name> [--bloc] [--service]`

Scaffolds a complete vertical feature slice.

### Synopsis

```
flut feature <name>
flut feature <name> --bloc
flut feature <name> --service
flut feature <name> --bloc --service
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<name>` | Yes | Feature name in `snake_case`. Must start with a letter. |
| `--bloc` | No | Generate a Bloc + event class instead of a Cubit. |
| `--service` | No | Add a `services/` layer between repository and Cubit/Bloc. |

### What it creates

```
lib/features/<name>/
├── business_logic/
│   ├── <name>_state.dart           ← plain sealed class (Initial/Loading/Loaded/Error)
│   ├── <name>_cubit.dart           ← default: Cubit
│   └── <name>_bloc.dart            ← with --bloc (replaces cubit, adds event file)
│   └── <name>_event.dart           ← with --bloc
├── data/
│   ├── models/<name>_model.dart    ← fromJson / toJson / copyWith / == / hashCode
│   ├── repositories/<name>_repository.dart
│   └── services/<name>_service.dart   ← with --service only
└── presentation/
    ├── router/<name>_router_module.dart
    ├── screens/<name>_screen.dart      ← @RoutePage(), BlocProvider, BlocConsumer
    └── widgets/                         ← empty, ready for components
```

### Examples

```bash
flut feature auth               # Cubit, no service layer
flut feature payment --bloc     # Bloc + event class
flut feature order --service    # Cubit + service layer
flut feature checkout --bloc --service   # Bloc + service layer
```

### Validation

- The name must be `snake_case` (e.g., `user_profile`, not `UserProfile` or `userProfile`).
- Exits with an error if the feature already exists.

### Next steps after `flut feature`

1. Register in `lib/core/di/service_locator.dart`:
   ```dart
   sl.registerSingleton<AuthRepository>(AuthRepository(sl<Dio>()));
   sl.registerFactory<AuthCubit>(() => AuthCubit(sl<AuthRepository>()));
   ```
2. Add your endpoint in `lib/core/api/api_endpoints.dart`.
3. Add the route in `lib/core/router/app_router.dart`.
4. Add translation keys in `assets/translations/en.json` and `fr.json`.
5. Run `dart run build_runner build --delete-conflicting-outputs`.

---

## `flut generate <type> <feature> [name]`

Generates a single component into an existing feature. Use this to add a second screen, model, or repository to a feature that was already scaffolded with `flut feature`.

### Synopsis

```
flut generate model      <feature> [name]
flut generate screen     <feature> [name]
flut generate repository <feature> [name]
flut generate cubit      <feature> [name]
flut generate bloc       <feature> [name]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<type>` | Yes | One of `model`, `screen`, `repository`, `cubit`, `bloc` |
| `<feature>` | Yes | Existing feature name (the directory under `lib/features/` must exist) |
| `[name]` | No | Component name in `snake_case`. Defaults to the feature name. |

### Sub-commands

#### `flut generate model <feature> [name]`

Creates a plain Dart model in `lib/features/<feature>/data/models/<name>_model.dart`.

The generated class includes: typed constructor, `fromJson`, `toJson`, `copyWith`, `==`, `hashCode`.

```bash
flut generate model auth              # → auth_model.dart
flut generate model auth login_request  # → login_request_model.dart
```

#### `flut generate screen <feature> [name]`

Creates a screen in `lib/features/<feature>/presentation/screens/<name>_screen.dart`.

The generated file includes `@RoutePage()`, a `BlocProvider`, and a `BlocConsumer` with a state switch.

```bash
flut generate screen auth             # → auth_screen.dart
flut generate screen auth login       # → login_screen.dart
```

#### `flut generate repository <feature> [name]`

Creates a repository in `lib/features/<feature>/data/repositories/<name>_repository.dart`.

The generated file injects `Dio` and wraps calls in `try/catch → ExceptionMapper`.

```bash
flut generate repository auth         # → auth_repository.dart
flut generate repository auth token   # → token_repository.dart
```

#### `flut generate cubit <feature> [name]`

Creates a Cubit + shared sealed state in `lib/features/<feature>/business_logic/`.

```bash
flut generate cubit auth              # → auth_cubit.dart (+ auth_state.dart if missing)
flut generate cubit auth login        # → login_cubit.dart + login_state.dart
```

#### `flut generate bloc <feature> [name]`

Creates a Bloc + event file + shared sealed state.

```bash
flut generate bloc auth               # → auth_bloc.dart + auth_event.dart
flut generate bloc auth login         # → login_bloc.dart + login_event.dart + login_state.dart
```

---

## `flut check`

Audits the current project for architecture convention violations.

### Synopsis

```
flut check
```

### Checks performed

| # | Check | Severity | What it looks for |
|---|-------|----------|-------------------|
| 1 | Feature structure | Error | Each feature under `lib/features/` must have all required directories |
| 2 | Sealed states | Error | Every `*_state.dart` must declare a `sealed class` |
| 3 | Banned packages | Warning | `freezed` or `json_serializable` in `pubspec.yaml` |
| 4 | Layer boundaries | Error | No file in `presentation/` may import a path containing `data/` |
| 5 | Router registration | Warning | Every screen in `presentation/screens/` should be referenced in `app_router.dart` |
| 6 | DI registration | Warning | Every class in `service_locator.dart` must have a matching file |
| 7 | Translation keys | Warning | Every `tr('key')` call must exist in both `en.json` and `fr.json` |
| 8 | Orphaned generated files | Warning | Every `*.gr.dart` must have a corresponding source file |
| 9 | Cubit/Bloc convention | Error | Cubits/Blocs must catch `AppFailure`, not generic `Exception` |

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | All checks passed |
| `1` | One or more warnings (no errors) |
| `2` | One or more errors |

### Examples

```bash
flut check
echo $?   # 0 = clean, 1 = warnings, 2 = errors

# Use in CI
flut check || exit 1
```

---

## `flut doctor`

Analyzes overall project health and reports status.

### Synopsis

```
flut doctor
```

### Checks performed

| # | Check | What it reports |
|---|-------|-----------------|
| 1 | Flutter SDK | Version detected or "not found in PATH" |
| 2 | Project root | Package name from `pubspec.yaml`, or warns if not a Flutter project |
| 3 | Required packages | How many of the 13 expected packages are present |
| 4 | Generated code | Whether `*.gr.dart` or `*.g.dart` files exist (build_runner has been run) |
| 5 | Scaffold integrity | How many expected core directories and files are present |
| 6 | Outdated packages | Summary from `flutter pub outdated` |
| 7 | Git | Branch, uncommitted changes, or "not a git repo" |

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | No issues found |
| `1` | One or more issues detected |

### Examples

```bash
flut doctor
```

---

## `flut clean [--rebuild]`

Removes all generated files (`*.gr.dart`, `*.g.dart`) from `lib/`. Use this when generated files are stale or you want a clean rebuild.

### Synopsis

```
flut clean
flut clean --rebuild
```

### Flags

| Flag | Description |
|------|-------------|
| `--rebuild` | After removing files, run `dart run build_runner build --delete-conflicting-outputs` to regenerate immediately. |

### What it removes

All files matching `*.gr.dart` or `*.g.dart` anywhere under `lib/`.

| Pattern | Typical source |
|---------|---------------|
| `*.gr.dart` | AutoRoute code generation |
| `*.g.dart` | Any `build_runner`-based generator |

Regular `.dart` files are never touched.

### Examples

```bash
# Remove generated files and see the count
flut clean

# Remove and immediately regenerate
flut clean --rebuild
```

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success (even if no files were found) |
| `1` | `lib/` not found, or unknown flag |

---

## `flut assets <subcommand>`

Detects and removes unused Flutter assets. Scans `assets/` (excluding `assets/translations/`, which has its own validation via `flut check`) and cross-references every file against `lib/**/*.dart`.

### Synopsis

```
flut assets check
flut assets stats
flut assets clean [--all] [--dry-run]
```

### Sub-commands

#### `flut assets check`

Lists all assets not referenced in any `.dart` file under `lib/`, with their individual sizes and a wasted-space summary.

**Exit codes:**

| Code | Meaning |
|------|---------|
| `0` | All assets are referenced — nothing wasted |
| `1` | One or more unused assets found |

**Example output:**

```
>> Asset Usage Check

  Unused assets:

    assets/images/onboarding_banner.png  (84.2 KB)
    assets/icons/close_old.svg           (3.1 KB)

  2 unused asset(s) — 87.3 KB wasted
  Scanned: 12 asset(s) total
```

**Use in CI:**

```bash
flut assets check || echo "Unused assets detected — clean up before merging"
```

---

#### `flut assets stats`

Prints a statistics table broken down by category.

**Columns:** Category, Count, Size, Unused, Unused size

**Example output:**

```
>> Asset Statistics

  Category   Count        Size    Unused    Unused size
  ─────────────────────────────────────────────────────
  images         8      1.2 MB         2       87.3 KB
  icons          4     12.4 KB         0          0 B
  lottie         2    340.0 KB         1      280.0 KB
  ─────────────────────────────────────────────────────
  Total         14      1.5 MB         3      367.3 KB
```

---

#### `flut assets clean [--all] [--dry-run]`

Deletes unused assets, interactively or in bulk.

**Flags:**

| Flag | Description |
|------|-------------|
| *(none)* | One-by-one: prompts `[y/N/q]` for each unused asset. `q` quits immediately. |
| `--all` | Lists all unused assets, asks a single `[y/N]` confirmation, then deletes them all. |
| `--dry-run` | Shows what would be deleted without touching any file. Compatible with both modes. |

**End-of-operation summary (example):**

```
  ok   3 file(s) deleted — 367.3 KB freed.
```

**Examples:**

```bash
# Review and delete one by one
flut assets clean

# Preview — no files deleted
flut assets clean --dry-run

# Bulk delete with single confirmation
flut assets clean --all

# Preview bulk delete
flut assets clean --all --dry-run
```

### Detection method

The engine runs a Dart AST analysis in two passes across all files under `lib/`.

**Pass 1 — build a global identifier map**

Extracts every declaration that holds an asset path literal:

| Declaration type | Example | Registered as |
|---|---|---|
| Top-level variable | `const kLogo = 'assets/images/logo.png';` | `kLogo` |
| Class static field | `class AppAssets { static const logo = 'assets/...'; }` | `logo` and `AppAssets.logo` |
| Mixin / Extension field | Same pattern | plain name and `Type.field` |

**Pass 2 — resolve usages**

For every `.dart` file:
1. **Direct literals** — regex scan for complete `assets/…` paths.
2. **Named references** — word-boundary match (`\bAppAssets.logo\b`) against the global map built in pass 1. Qualified names (`ClassName.field`) are preferred to reduce false positives.

**Supported extensions:** `.png` `.jpg` `.jpeg` `.svg` `.webp` `.gif` `.json` `.ttf` `.otf` `.mp4` `.mp3` `.riv` `.lottie`

---

### Known limitations

The following patterns are **not detectable** by static analysis and will cause an asset to be reported as unused even if it is actually used at runtime. Review these manually before confirming a deletion.

**1. Dynamic string interpolation**

```dart
// ❌ — no complete path in source
Image.asset('assets/icons/$iconName.svg');
SvgPicture.asset('assets/images/${theme}_background.svg');
```

**2. Runtime path construction**

```dart
// ❌ — path assembled at runtime
final path = 'assets/' + category + '/' + fileName;
```

**3. `flutter_gen` / code-generated accessors**

```dart
// ❌ — no string literal anywhere; generated via flutter_gen
Assets.images.logo.path
Gen.icons.close
```

**Recommended workaround for dynamic paths:** declare the full path in a `static const` field and reference the field. The engine will track it across files.

```dart
// ✅ — engine resolves AppAssets.logo across all files
class AppAssets {
  static const logo    = 'assets/images/logo.png';
  static const bgLight = 'assets/images/bg_light.png';
  static const bgDark  = 'assets/images/bg_dark.png';
}
```

---

## `flut upgrade`

Updates the CLI to the latest version from the remote git repository.

### Synopsis

```
flut upgrade
```

### What it does

1. Reads the current version from the `VERSION` file.
2. Queries the GitHub Releases API to show the latest published version (requires `curl`; skipped gracefully if unavailable).
3. Detects the remote branch (`main` or `master`).
4. Warns if there are local uncommitted changes (they will be discarded).
5. Runs `git fetch origin <branch>`.
6. Runs `git reset --hard origin/<branch>`.
7. Restores the executable permission on `flut.sh` (`chmod +x`).
8. Prints the version change (`v0.1.0 → v0.2.0`) and the git changelog.

### Examples

```bash
flut upgrade
# Current version: v0.1.0
# Fetching from origin...
# Resetting to origin/main...
# Upgraded v0.1.0 → v0.2.0  (a1b2c3d → e4f5g6h)
# Changelog:
#   e4f5g6h feat: add flut clean command
#   d3e4f5g fix: doctor reports missing packages correctly
```

### Requirements

- Must be run from an installation that was cloned with git (the default `install.sh` path).
- If installed manually without git, re-install using the one-liner.

---

## `flut --version`

Prints the installed version.

### Synopsis

```
flut --version
flut -v
```

### Example

```bash
flut --version
# flut v0.1.0
```

---

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error (bad arguments, missing pubspec.yaml, warnings in `flut check`, unused assets in `flut assets check`) |
| `2` | Errors found by `flut check` |
