---
title: flut-cli
---

# flut-cli

**Flutter project scaffold CLI by NTECH-SERVICES**

`flut` is an opinionated bash CLI that bootstraps Flutter projects and features following the NTECH-SERVICES architecture standard — features-first folder structure, plain sealed-class state, AutoRoute navigation, and manual GetIt DI.

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/loicgeek/flut-cli/main/install.sh | bash
```

Then add shell completions (printed by the installer, or manually):

```bash
# bash — add to ~/.bashrc
source ~/.flut-cli/completions/flut.bash

# zsh — add to ~/.zshrc
source ~/.flut-cli/completions/flut.zsh
```

---

## Quick start

```bash
# 1. Bootstrap a new Flutter project
cd my_flutter_app
flut init

# 2. Add a feature
flut feature auth
flut feature payment --bloc
flut feature order --service

# 3. Generate individual components into an existing feature
flut generate screen auth login
flut generate model auth login_request

# 4. Audit architecture conventions
flut check

# 5. Check project health
flut doctor

# 6. Keep the CLI up to date
flut upgrade
```

---

## Documentation

| Page | Description |
|------|-------------|
| [Command Reference](commands) | Every flag, argument, example, and exit code |
| [Architecture Guide](architecture) | Folder structure, layer rules, state, DI, navigation, and all conventions |
| [FAQ](faq) | Installation, architecture decisions, troubleshooting |
| [Contributing](https://github.com/loicgeek/flut-cli/blob/main/CONTRIBUTING.md) | Development setup, testing, PR workflow |

---

## Why this CLI?

| Principle | How `flut` enforces it |
|-----------|----------------------|
| **Features-first** | `flut feature` creates a self-contained vertical slice with `business_logic/`, `data/`, and `presentation/` |
| **No codegen bloat** | Plain Dart models and sealed state — `freezed` and `json_serializable` are banned |
| **One navigation tool** | AutoRoute only, with a per-feature `RouterModule` pattern |
| **Explicit DI** | Manual GetIt registration in one file — no `injectable` annotation scanning |
| **Compile-time exhaustiveness** | Sealed state classes force every variant to be handled at compile time |

---

## Source

[github.com/loicgeek/flut-cli](https://github.com/loicgeek/flut-cli)
