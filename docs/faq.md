# flut-cli — FAQ

> Answers to common questions about the CLI and the NTECH-SERVICES architecture.

---

## Installation & setup

### Where does `flut` get installed?

The installer clones the repo to `~/.flut-cli/` and creates a symlink at `/usr/local/bin/flut` pointing to `~/.flut-cli/flut.sh`. The symlink means `flut upgrade` takes effect immediately — you never need to reinstall.

### I get "permission denied: flut" after upgrading

This happened because git stored `flut.sh` as non-executable (`100644`). The `flut upgrade` command now runs `chmod +x` automatically after each update. If you're on an older installation, fix it once with:

```bash
chmod +x ~/.flut-cli/flut.sh
```

### Can I install flut without root access?

Yes. Change `BIN` in `install.sh` to a directory you own, or symlink manually:

```bash
git clone https://github.com/loicgeek/flut-cli.git ~/.flut-cli
chmod +x ~/.flut-cli/flut.sh
mkdir -p ~/bin
ln -s ~/.flut-cli/flut.sh ~/bin/flut
# Make sure ~/bin is in your PATH
```

### How do I check which version is installed?

```bash
flut --version
# flut v0.1.0
```

---

## Commands

### Must I run `flut` from the project root?

Yes. All commands that touch project files (`init`, `feature`, `generate`, `check`, `doctor`) expect to find `pubspec.yaml` in the current directory.

### Can I run `flut init` on an existing project?

Yes. `flut init` is idempotent — it only creates files that don't already exist. It won't overwrite anything you've edited.

### What's the difference between `flut feature` and `flut generate`?

| | `flut feature` | `flut generate` |
|-|----------------|-----------------|
| Purpose | Full vertical slice — one command per domain feature | Single component — add a second screen, model, etc. to an existing feature |
| Creates | `business_logic/`, `data/`, `presentation/` + all their files | One file in the correct sub-directory |
| Use when | Starting a new feature | Extending an existing feature |

### `flut feature` is failing with "invalid name". What's allowed?

The name must be `snake_case`: lowercase letters, digits, and underscores, starting with a letter.

```bash
flut feature auth         ✓
flut feature user_profile ✓
flut feature UserProfile  ✗  (PascalCase)
flut feature userProfile  ✗  (camelCase)
flut feature 2fa          ✗  (starts with digit)
flut feature auth feature ✗  (spaces)
```

---

## Architecture decisions

### Why no `freezed`?

Dart 3.0 introduced `sealed` classes with exhaustiveness checking built into the compiler. `freezed` solves the same problem but requires:

1. A `build_runner` dependency
2. A `*.freezed.dart` generated file per class
3. Two separate invocations of `build_runner` for every model change

For state classes — which change rarely — the overhead isn't worth it.

See [ARCHITECTURE.md — Banned packages](../ARCHITECTURE.md#11-banned-packages).

### Why no `json_serializable`?

`fromJson`/`toJson` for a typical API model takes about 2 minutes to write by hand and produces code that is immediately readable in a code review. `json_serializable` adds a generated `*.g.dart` file for each model and a `build_runner` step that slows the development loop. The convention here is to keep codegen to a minimum — AutoRoute only.

### Why Cubit instead of Bloc by default?

The majority of features (load a list, submit a form, navigate) have simple async flows where `emit()` is all you need. Cubit has no event class, which means less boilerplate for the common case. Use `--bloc` when you have multiple distinct user events that share state transitions, or when you need `transformEvents` (throttle, debounce, switchMap).

### Why manual GetIt instead of `injectable`?

`injectable` annotates your classes and generates a `*.config.dart` file that wires up the DI graph. The generated file is hard to follow during code review and hides the registration order. With manual `service_locator.dart`, the entire DI setup is one plain Dart file — readable top to bottom, no indirection.

### Why per-feature `RouterModule` instead of one big `app_router.dart`?

One flat `app_router.dart` with every route in the app becomes a merge conflict magnet and makes it easy to accidentally couple features. Each feature's `RouterModule` is self-contained: it only knows about its own screens and transitions. The root router composes them.

---

## `flut check`

### `flut check` exits with code 1. Is that a failure?

Code `1` means warnings only — no structural errors. Your CI can treat it as acceptable:

```bash
flut check
status=$?
if [[ $status -eq 2 ]]; then
  echo "Architecture errors found — blocking CI"
  exit 1
elif [[ $status -eq 1 ]]; then
  echo "Warnings present — review recommended"
fi
```

### A screen is registered in `app_router.dart` but check still warns about it

The router registration check looks for the AutoRoute-generated class name (`AuthRoute`, `HomeRoute`, etc.) in `app_router.dart`. Make sure you've run `build_runner` at least once so the class names are resolved, then double-check the `replaceInRouteName` setting in your `@AutoRouterConfig`.

### `flut check` warns about a translation key I'm sure exists

The key scanner uses a regex on `tr('...')` and `tr("...")` calls. It won't detect keys built at runtime (e.g., `tr('prefix.$variable')`). That's expected — dynamic keys can't be statically verified.

---

## `flut doctor`

### Doctor says "Required packages — N runtime package(s) missing" but they're installed

`flut doctor` checks `pubspec.yaml` directly, not the resolved package graph. It looks for the package name as a key under `dependencies:`. If you have the package under a different section (e.g., under a `flutter_test:` override), the check may miss it.

### Doctor shows scaffold integrity warnings after `flut init`

Some scaffold files reference each other (e.g., `app_router.dart` expects `*.gr.dart` to exist after code generation). Run `dart run build_runner build --delete-conflicting-outputs` and re-run `flut doctor`.

---

## Contributing

### How do I add a new check to `flut check`?

1. Add a `_check_N_my_check()` function inside `cmd_check()` in `flut.sh`.
2. Call it in the "Run all checks" block near the end of `cmd_check`.
3. Use `_check_pass`, `_check_warn`, or `_check_err` to report results — these automatically increment the counters that drive the exit code.
4. Add a test in `tests/check.bats`.

See `CONTRIBUTING.md` for the full workflow.

### How do I add a new generate sub-command?

1. Add a `cmd_generate_<type>()` function in `flut.sh`.
2. Add the type to the `case` switch inside `cmd_generate()`.
3. Add a test in `tests/generate.bats`.
4. Update the `--help` output in the `usage()` function.
5. Update `docs/commands.md`.
