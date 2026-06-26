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
| `tests/check.bats` | `flut check` — feature structure, sealed states, banned packages, layer boundaries, translation keys | 9 |
| `tests/doctor.bats` | `flut doctor` — Flutter SDK, project root, required packages, scaffold integrity, git | 10 |
| `tests/generate.bats` | `flut generate` — all sub-commands, file content, next-steps output | 13 |
| `tests/completions.bats` | Shell completions — file existence, sourcing, completion suggestions, dynamic features | 15 |
| `tests/helpers.bash` | Shared utilities — sandbox, assertions (`assert_file_exists`, `assert_file_contains`, etc.) | — |
| **Total** | | **109 tests — all passing** |

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

All jobs run on `ubuntu-latest` with path filters (`*.sh`, `tests/**`, `completions/**`, `VERSION`).

**Workflow: `.github/workflows/release.yml`** *(added in Phase 3)*

Triggered by `v*.*.*` tag pushes. Runs the full test suite, then creates a GitHub Release with auto-generated notes. Verifies the tag matches the `VERSION` file before releasing.

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

## ✅ Phase 2 — New Commands *(Completed)*

### ✅ 2.1 `flut check` — Architecture Audit

Validates that a Flutter project still follows the NTECH-SERVICES clean architecture conventions after manual edits.

**9 checks implemented:** feature structure, sealed states, banned codegen, layer boundaries, router registration, DI registration, translation keys, orphaned generated files, cubit convention.

**Exit codes:** `0` = all clear, `1` = warnings, `2` = errors

---

### ✅ 2.2 `flut doctor` — Project Health

Analyzes the current Flutter project and reports its health status.

**7 checks implemented:** Flutter SDK, project root, required packages, generated code, scaffold integrity, outdated packages, git.

---

### ✅ 2.3 `flut generate` Sub-commands

Reusable generators for individual components (not full feature slices).

| Sub-command | Arguments | What it creates |
|---|---|---|
| `flut generate model <feature> <name>` | feature, name | Plain Dart model with `fromJson`/`toJson`/`copyWith`/`==`/`hashCode` |
| `flut generate screen <feature> <name>` | feature, name | Screen with `BlocProvider`/`BlocConsumer`, route-ready |
| `flut generate repository <feature> <name>` | feature, name | Repository with Dio injection + error handling |
| `flut generate cubit <feature> <name>` | feature, name | Cubit + state + sealed class |
| `flut generate bloc <feature> <name>` | feature, name | Bloc + events + state + sealed class |

Each sub-command places the file in the correct feature directory and prints the registration instructions.

---

## ✅ Phase 3 — Developer Experience & Documentation *(Completed)*

### ✅ 3.1 Shell Completions

Tab-completion for `flut` commands and flags in bash and zsh.

**Files:**
- `completions/flut.bash` — bash completion
- `completions/flut.zsh` — zsh completion (with descriptions via `_describe`)

**Completion targets:**
- Top-level: `init`, `feature`, `upgrade`, `check`, `doctor`, `generate`, `assets`
- `feature` flags: `--bloc`, `--service`
- `generate` types: `model`, `screen`, `repository`, `cubit`, `bloc`
- `assets` sub-commands: `check`, `stats`, `clean`; `clean` flags: `--all`, `--dry-run`
- Dynamic: `--feature` argument suggests existing feature names from `lib/features/`

**Install (printed by `install.sh` after install):**
```bash
# bash — add to ~/.bashrc
source ~/.flut-cli/completions/flut.bash

# zsh — add to ~/.zshrc
source ~/.flut-cli/completions/flut.zsh
```

---

### ✅ 3.2 Versioning & `flut upgrade` improvements

**`VERSION` file** — single source of truth for the current version, tracked in the repo.

**`flut --version`** — new flag that prints `flut v0.1.0`.

**`flut upgrade` improvements:**
- Displays current version before pulling (`Current version: v0.1.0`)
- Displays new version after pulling (`Upgraded v0.1.0 → v0.2.0`)
- Shows git changelog between commits (`git log --oneline`)
- Reports "Already up to date" when nothing changed
- `chmod +x` after `git reset --hard` — fixes "permission denied: flut" on macOS/Linux
- `flut.sh` now tracked in git as `100755` (executable) so the mode survives `git reset --hard`
- Fixed stale repo URL in error message (`kehitaa` → `loicgeek`)

**Release workflow (`.github/workflows/release.yml`):**

To cut a new release:
```bash
echo "0.2.0" > VERSION
git add VERSION && git commit -m "chore: bump version to 0.2.0"
git tag v0.2.0 && git push origin main --tags
```
The workflow runs the full test suite, verifies the tag matches `VERSION`, then creates a GitHub Release with auto-generated notes.

---

### ✅ 3.3 Documentation *(Completed)*

| File | Description |
|---|---|
| **README.md** | Added CI/Release/Version/License badges; shell completions section; links to ARCHITECTURE.md and docs/commands.md; improved Contributing section |
| **ARCHITECTURE.md** | Deep dive: guiding principles, folder structure, layer rules, state management, data modeling, error handling, DI, navigation, service layer, translation keys, banned packages, full `flut check` rule table |
| **docs/commands.md** | Full command reference — every flag, argument, example, exit code, and next-steps checklist |
| **docs/faq.md** | 20+ Q&A covering installation, architecture decisions, check/doctor behavior, and contribution how-tos |

---

## ✅ Phase 4 — Advanced Features *(Completed)*

### ✅ 4.1 `flut upgrade` — GitHub API version check

Before pulling, `flut upgrade` now queries `api.github.com/repos/loicgeek/flut-cli/releases/latest` (requires `curl`, skipped gracefully if unavailable) and reports whether the user is already on the latest published release or whether a newer one exists.

```
Current version:  v0.1.0
Latest release:   v0.2.0 — upgrade available
Fetching from origin...
```

---

### ✅ 4.2 `flut clean [--rebuild]`

Removes all `*.gr.dart` and `*.g.dart` files from `lib/`. Accepts `--rebuild` to immediately re-run `dart run build_runner build --delete-conflicting-outputs`.

```bash
flut clean            # remove generated files
flut clean --rebuild  # remove then regenerate
```

10 BATS tests added in `tests/clean.bats`.

---

### ✅ 4.3 GitHub Pages documentation site

Live at **[loicgeek.github.io/flut-cli](https://loicgeek.github.io/flut-cli/)** (once GitHub Pages is enabled in repo settings).

| File | Purpose |
|---|---|
| `docs/index.md` | Landing page — install, quick start, links to all docs |
| `docs/_config.yml` | Jekyll Cayman theme config |
| `docs/commands.md` | Full command reference (updated with `flut clean`) |
| `docs/faq.md` | FAQ |
| `.github/workflows/pages.yml` | Builds & deploys on every push to `main` that touches `docs/` or `ARCHITECTURE.md` |

**Enable:** repo Settings → Pages → Source → **GitHub Actions**.

---

## ✅ Phase 5 — Asset Analysis & Cleanup *(Completed)*

### ✅ 5.1 `flut assets` — Unused asset detection and removal

Detects Flutter assets that are never referenced in Dart code and lets the developer remove them interactively or in bulk.

**New file:** `commands/cmd_assets.sh` (sourced by `flut.sh` — keeps the main file manageable)

**Sub-commands:**

| Sub-command | Exit code | Description |
|---|---|---|
| `flut assets check` | `0` = clean, `1` = unused found | Lists unused assets with sizes and wasted-space summary |
| `flut assets stats` | `0` | Statistics table by category (images / icons / lottie / other) |
| `flut assets clean` | `0` | Interactive one-by-one deletion (`[y/N/q]`) |
| `flut assets clean --all` | `0` | Bulk deletion with a single confirmation |
| `flut assets clean --dry-run` | `0` | Preview without touching any file |

**Detection:** `grep -rqE "(basename|full/path)" --include='*.dart' lib/` — same pattern family as the existing translation-key scanner.

**Translations excluded** — `assets/translations/` is handled separately by `flut check`.

**20 BATS tests** added in `tests/assets.bats`.

**Completions updated** — bash and zsh completions now suggest `check`, `stats`, `clean`, `--all`, `--dry-run`.

---

## Implementation Order

```
✅ Phase 1 (Foundation)           ← COMPLETED
   ├── BATS test suite (109 tests)
   ├── GitHub CI (lint + test + integration)
   └── CONTRIBUTING.md

✅ Phase 2 (Commands)             ← COMPLETED
   ├── flut check  — architecture audit
   ├── flut doctor — project health
   └── flut generate sub-commands

✅ Phase 3 (DX & Docs)            ← COMPLETED
   ├── Shell completions (bash + zsh)
   ├── Versioning (VERSION file, --version flag, release workflow)
   ├── flut upgrade improvements (chmod fix, version display, changelog)
   └── Documentation (README badges, ARCHITECTURE.md, docs/commands.md, docs/faq.md)

✅ Phase 4 (Advanced)             ← COMPLETED
   ├── flut upgrade — GitHub API version check
   ├── flut clean (+ --rebuild flag, 10 tests)
   └── GitHub Pages docs site

✅ Phase 5 (Asset Management)     ← COMPLETED
   └── flut assets (check / stats / clean) — 20 tests
```

---

## How to Contribute

1. Open an issue for a new feature or bug fix
2. Create a branch: `git checkout -b feat/your-change`
3. Implement the feature
4. Add/update tests in `tests/`
5. Run `bats tests/` — all tests must pass
6. Open a PR against `main`

See `CONTRIBUTING.md` for full guidelines.
