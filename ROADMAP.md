# flut-cli Roadmap

> A prioritized plan for improving the Flutter project scaffold CLI.
>
> ✅ = Completed   🔜 = Next up   📋 = Planned

---

## ✅ Phase 1 — Foundation & Quality *(Completed)*

### 1.1 BATS Test Suite

[BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) tests that verify the CLI works correctly.

**Goal:** Every contributor can run `bats tests/` and get immediate confidence nothing is broken.

**Test files:**

| File | Scope | Tests |
|---|---|---|
| `tests/commands.bats` | CLI arg parsing, help output, error handling, feature name validation | 14 |
| `tests/feature.bats` | `flut feature` — Cubit/Bloc/Service flags, file content, duplicates | 18 |
| `tests/init.bats` | `flut init` — directory structure, all files, IDE settings, idempotency | 27 |
| `tests/upgrade.bats` | `flut upgrade` — help mention, git detection, fetch failure | 3 |
| `tests/helpers.bash` | Shared utilities — sandbox, assertions (`assert_file_exists`, `assert_file_contains`, etc.) | — |
| **Total** | | **64 tests — all passing** |

**Run with:**
```bash
bats tests/
```

If BATS is not installed:
```bash
npm install -g bats          # via npm
sudo apt-get install bats    # via apt
brew install bats            # via brew
```

---

### 1.2 GitHub CI/CD

**Workflow: `.github/workflows/ci.yml`**

| Job | Trigger | What it does |
|---|---|---|
| `lint` | Push/PR to main | `shellcheck` on `flut.sh` and `install.sh` |
| `test` | Push/PR to main | `bats` test suite (no Flutter needed) |
| `integration` | Push/PR (main repo only) | Creates real Flutter project, runs `flut init` + `flut feature`, verifies output |

All jobs run on `ubuntu-latest` with path filters to skip irrelevant changes.

**Planned (not yet implemented):**
- `.github/workflows/release.yml` — automated GitHub releases on tags

---

### 1.3 CONTRIBUTING.md

A comprehensive contributing guide covering:
- Development setup and prerequisites
- Running tests and linters
- Code style conventions (shell, log functions, templates)
- Commit message format (Conventional Commits)
- PR workflow and review process
- Guide for adding a new command
- Testing guidelines

---

## 🔜 Phase 2 — New Commands *(Next up)*

### 2.1 `flut check` — Architecture Audit

Validates that a Flutter project still follows the NTECH-SERVICES clean architecture conventions after manual edits. **The unique differentiator of this CLI.**

**Checks to implement:**

| # | Check | Implementation |
|---|---|---|
| 1 | **Feature structure** | Every dir under `lib/features/<x>/` must have `business_logic/`, `data/`, `presentation/` with required sub-dirs |
| 2 | **State is sealed** | Every `*_state.dart` must declare a `sealed class` |
| 3 | **No banned codegen** | Warn if `freezed` or `json_serializable` in `pubspec.yaml` |
| 4 | **Layer boundaries** | Files in `presentation/` should not import `data/` directly (only `business_logic/`) |
| 5 | **Router registration** | Screens in `features/*/presentation/screens/` referenced in `app_router.dart` |
| 6 | **DI registration** | Repos/Services registered in `service_locator.dart` have corresponding files |
| 7 | **Translation keys** | Keys used in `tr()` calls exist in both `en.json` and `fr.json` |
| 8 | **No orphaned generated files** | `.gr.dart` files whose source has been deleted |
| 9 | **Cubit/Bloc convention** | Cubit files use `try/catch` with `AppFailure`, not generic `Exception` |

**Output format:**
```
$ flut check
  ok  Feature structure (9 features)
  ok  Sealed states (9/9 valid)
  xx  auth — imports data/ directly from presentation/login_screen.dart
  ok  No banned packages
  !!  Translation key "order.empty" missing from en.json
  ok  Router registration (12/12 screens)
  ok  DI registration (18/18 registrations)

  1 warning, 1 error — see details above
```

**Exit codes:**
- `0` — all clear
- `1` — warnings only
- `2` — errors found

---

### 2.2 `flut doctor` — Project Health

Analyzes the current Flutter project and reports its health status.

**Checks:**

| Check | What it validates |
|---|---|
| Flutter SDK | `flutter --version` available, meets min version |
| Project root | `pubspec.yaml` exists and is valid |
| Required packages | All expected dependencies are in `pubspec.yaml` |
| Generated code | `build_runner` has been run (`.gr.dart` files exist) |
| Scaffold integrity | Expected `lib/` structure from `flut init` is intact |
| Outdated packages | `flutter pub outdated` summary |
| Git | Whether project is initialized with git |

**Example:**
```
$ flut doctor
  ✓ Flutter SDK 3.24.0
  ✓ Project root detected
  ✓ Required packages (14/14)
  !! Build runner not run — dart run build_runner build --delete-conflicting-outputs
  ✓ Scaffold structure intact
  ✓ Git initialized
  - 3 packages have updates available (flutter pub outdated)
```

---

### 2.3 `flut generate` Sub-commands

Reusable generators for individual components (not full feature slices).

| Sub-command | What it creates |
|---|---|
| `flut generate model <name>` | Plain Dart model with `fromJson`/`toJson`/`copyWith`/`==`/`hashCode` |
| `flut generate screen <name>` | Screen with `BlocProvider`/`BlocConsumer`, route-ready |
| `flut generate repository <name>` | Repository with Dio injection + error handling |
| `flut generate cubit <name>` | Cubit + state + sealed class |
| `flut generate bloc <name>` | Bloc + events + state + sealed class |

Each sub-command places the file in the correct location and prints the registration instructions.

---

### 2.4 `flut clean` — Un-Scaffold

Removes everything `flut init` created.

- Deletes generated `lib/` directories
- Removes added packages from `pubspec.yaml`
- Deletes `.vscode/launch.json` and `.idea/runConfigurations/`
- Interactive confirmation before any destructive action

---

## 📋 Phase 3 — Developer Experience *(Planned)*

### 3.1 Shell Completions

Tab-completion for `flut` commands and flags in bash and zsh.

**Files:**
- `completions/flut.bash` — bash completion
- `completions/flut.zsh` — zsh completion

**Install commands printed by `install.sh`:**
```bash
# bash
source completions/flut.bash

# zsh
source completions/flut.zsh
```

**Completion targets:**
- Top-level: `init`, `feature`, `upgrade`, `check`, `doctor`, `generate`, `clean`
- Flags: `--bloc`, `--service`
- Dynamic: suggest feature names from `lib/features/`

---

### 3.2 Improved `flut upgrade`

**Current issues:**
- Hardcodes repo URL instead of detecting from git remote
- Doesn't check current version before upgrading
- No version comparison (always pulls even if up to date)

**Improvements:**
1. Auto-detect remote from `git -C "$INSTALL_DIR" remote get-url origin`
2. Add a local version file `VERSION` tracked in repo
3. Check latest tag on GitHub API before pulling
4. Show changelog diffs between versions

---

### 3.3 Documentation

| Item | Description |
|---|---|
| **README.md** | Add badge section (CI, license, version) |
| **ARCHITECTURE.md** | Deep dive into the clean architecture conventions enforced by this CLI |
| **docs/commands.md** | Full reference for every command with examples |
| **docs/faq.md** | Common questions and troubleshooting |
| **GitHub Pages site** | Optional: deploy docs as a site via `docs/` dir or Jekyll |

---

## 📋 Phase 4 — Polish *(Planned)*

- **`.github/workflows/release.yml`** — automated GitHub releases on version tags
- **`flut upgrade` improvements** — version checking, changelog diff, remote auto-detection
- **ARCHITECTURE.md** — deep-dive into NTECH-SERVICES clean architecture conventions
- **Documentation site** — GitHub Pages with full command reference

---

## Implementation Order

```
✅ Phase 1 (Foundation)           ← COMPLETED
   ├── BATS test suite (64 tests)
   ├── GitHub CI (lint + test + integration)
   └── CONTRIBUTING.md

🔜 Phase 2 (Unique Value)        ← NEXT
   ├── flut check  — architecture audit
   ├── flut doctor — project health
   ├── flut generate sub-commands
   ├── flut clean
   └── GitHub Release workflow

📋 Phase 3 (DX)
   ├── Shell completions
   ├── flut upgrade improvements
   └── More documentation

📋 Phase 4 (Polish)
   └── Release workflow, ARCHITECTURE.md, docs site
```

---

## How to Contribute

1. Pick an item from **Phase 2** above
2. Create a branch: `git checkout -b feat/your-change`
3. Implement the feature
4. Add/update tests in `tests/`
5. Run `bats tests/` — all tests must pass
6. Open a PR against `main`

See `CONTRIBUTING.md` for full guidelines.
