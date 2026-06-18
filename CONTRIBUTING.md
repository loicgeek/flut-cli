# Contributing to flut-cli

Thanks for your interest in contributing! 🎉

This document provides guidelines for contributing to the project. Following these helps maintain a high-quality, consistent codebase.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Code Style](#code-style)
- [Commit Messages](#commit-messages)
- [Pull Request Workflow](#pull-request-workflow)
- [Adding a New Command](#adding-a-new-command)
- [Testing Guidelines](#testing-guidelines)

---

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/loicgeek/flut-cli.git
   cd flut-cli
   ```
3. Create a branch for your changes:
   ```bash
   git checkout -b feat/my-change
   ```

---

## Development Setup

### Prerequisites

| Tool   | Required for             |
|--------|--------------------------|
| bash   | Running the CLI (4+)     |
| git    | Version control          |
| bats   | Running tests (optional) |

### Install bats

**Linux (apt):**
```bash
sudo apt-get install bats
```

**macOS (brew):**
```bash
brew install bats-core/bats-core/bats
```

**npm (any platform):**
```bash
npm install -g bats
```

### Install shellcheck (for linting)

**Linux (apt):**
```bash
sudo apt-get install shellcheck
```

**macOS (brew):**
```bash
brew install shellcheck
```

### Verify your setup

```bash
# Run the CLI directly
bash flut.sh --help

# Run tests
bats tests/

# Lint shell scripts
shellcheck flut.sh install.sh
```

---

## Running Tests

We use [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) for testing.

```bash
# Run all tests
bats tests/

# Run a single test file
bats tests/commands.bats

# Run tests with verbose output
bats --print-output-on-failure tests/

# Run a specific test by name pattern
bats --filter "flut feature" tests/
```

### Test organization

```
tests/
├── helpers.bash        # Shared utilities (sandbox, assertions)
├── commands.bats       # CLI arg parsing, help, error handling
├── feature.bats        # `flut feature` command
└── init.bats           # `flut init` command
```

### Writing tests

All tests create a temporary sandbox with a minimal `pubspec.yaml` so they can run without Flutter SDK installed. Use the helper functions:

```bash
load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

@test "my test" {
  run bash "$FLUT_SCRIPT" feature my_feature
  [ "$status" -eq 0 ]
  assert_dir_exists "lib/features/my_feature"
  assert_file_contains "lib/features/my_feature/..." "..."
}
```

**Available assertion helpers:**
- `assert_file_exists` / `assert_file_not_exists`
- `assert_dir_exists` / `assert_dir_not_exists`
- `assert_file_contains` / `assert_file_not_contains`
- `assert_feature_structure`

---

## Code Style

### Shell scripting

- Run `shellcheck flut.sh install.sh` before committing
- Use `set -euo pipefail` at the top of all scripts
- Use `local` for all function-scoped variables
- Use `snake_case` for variable and function names
- Prefix helper functions with `_` (e.g., `_print_pub_cmds`)
- Use `[[ ]]` for conditionals (bash-native, more robust)
- Prefer `printf` over `echo` for dynamic content
- Keep functions single-purpose and under ~50 lines when possible

### File generation templates

- Generated Dart files must follow the NTECH-SERVICES architecture conventions:
  - Plain Dart models — no codegen for data classes
  - Plain sealed classes for state — no `freezed`
  - AutoRoute only — one codegen dependency
  - Manual GetIt registration — no `injectable`
- Template variables use `$pascal` and `$name` consistently
- All `mkf` and `mkd` helpers use the logger functions (`log_info`, `log_success`, etc.)

### Logging conventions

| Function       | When to use                          |
|----------------|--------------------------------------|
| `log_info`     | Describing an action about to happen |
| `log_success`  | Action completed successfully        |
| `log_warning`  | Non-fatal issue (e.g., existing file) |
| `log_error`    | Fatal error, exit follows            |
| `log_section`  | Major heading in output              |

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

<body>
```

**Types:**
- `feat` — new command or feature
- `fix` — bug fix
- `test` — adding or updating tests
- `docs` — documentation only
- `refactor` — code change that neither fixes nor adds
- `chore` — maintenance, CI, tooling

**Examples:**
```
feat(check): add architecture audit command
test(init): add tests for core file generation
fix(feature): handle edge case in snake_case validation
docs: add contributing guide
chore(ci): add shellcheck workflow
```

---

## Pull Request Workflow

1. **Branch naming**: `feat/`, `fix/`, `docs/`, `chore/` prefix
2. **Before opening a PR**:
   - `shellcheck flut.sh install.sh` — no warnings
   - `bats tests/` — all tests pass
   - If you added a new command, add tests for it
3. **PR title**: Use conventional commit format (e.g., `feat(check): add architecture audit command`)
4. **PR description**: Describe what the change does, why it's needed, and how to test it
5. **CI checks**: PR must pass all CI checks before merging
6. **Review**: PRs need at least one approval from a maintainer

---

## Adding a New Command

1. Add the command function in `flut.sh` (e.g., `cmd_mysubcommand()`)
2. Add the command case in the entrypoint `case` block
3. Add the command to the `usage()` function
4. Add tests in a new file under `tests/` (e.g., `tests/mysubcommand.bats`)
5. Update `ROADMAP.md` if the command was planned
6. Update `.github/workflows/ci.yml` if the command needs integration tests

### Command function structure

```bash
cmd_mysubcommand() {
  # 1. Parse arguments
  # 2. Validate preconditions (exit 1 with log_error on failure)
  # 3. Execute logic using mkf/mkd helpers
  # 4. Print success output / checklist
}
```

---

## Testing Guidelines

- **Every new command needs tests** — at minimum:
  - Success path (default behavior)
  - Error paths (invalid input, missing preconditions)
  - Flag variations if applicable
- **Tests should not require Flutter SDK** — use the sandbox with a mock `pubspec.yaml`
- **Integration tests** that need Flutter go in `.github/workflows/ci.yml` (separate job)
- **Test for file content**, not just file existence — verify the generated templates are correct

---

## Getting Help

- Open a [GitHub Issue](https://github.com/loicgeek/flut-cli/issues) for bugs or feature requests
- Check the [README.md](README.md) for usage documentation
- Review [ROADMAP.md](ROADMAP.md) for the project's development plan

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
