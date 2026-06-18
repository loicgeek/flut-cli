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
| **Total** | | **97 tests — all passing** |

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

## ✅ Phase 2 — New Commands *(In progress)*

### ✅ 2.1 `flut check` — Architecture Audit *(Completed)*

Validates that a Flutter project still follows the NTECH-SERVICES clean architecture conventions after manual edits.

**9 checks implemented:** feature structure, sealed states, banned codegen, layer boundaries, router registration, DI registration, translation keys, orphaned generated files, cubit convention.

**Exit codes:** `0` = all clear, `1` = warnings, `2` = errors

---

### ✅ 2.2 `flut doctor` — Project Health *(Completed)*

Analyzes the current Flutter project and reports its health status.

**7 checks implemented:** Flutter SDK, project root, required packages, generated code, scaffold integrity, outdated packages, git.

---

### ✅ 2.3 `flut generate` Sub-commands *(Completed)*

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
   ├── BATS test suite (97 tests)
   ├── GitHub CI (lint + test + integration)
   └── CONTRIBUTING.md

✅ Phase 2 (Unique Value)        ← COMPLETED
   ├── ✅ flut check  — architecture audit
   ├── ✅ flut doctor — project health
   ├── ✅ flut generate sub-commands
   └── 📋 GitHub Release workflow

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
