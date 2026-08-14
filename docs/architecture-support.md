# Architecture Support for flut-cli

> Design doc — multi-architecture support for `flut`. Not yet implemented.

## Goal

Make architecture a first-class concept. Default stays **NTECH** (zero behavior
change for existing users), and **Clean Architecture** ships as the first
alternative. Everything is opt-in via one flag.

## Core design

**Config file** — each generated project gets a `flut.json`:

```json
{ "architecture": "clean" }
```

- `flut init --architecture <name>` writes it; defaults to `ntech` when absent
  (fully backward compatible).
- `flut feature` / `flut generate` / `flut check` / `flut doctor` all read the
  active architecture from `flut.json`.
- New command `flut architecture` — lists installed profiles, shows current,
  `--set <name>`.

**Template registry** — templates move out of the 2667-line `flut.sh` into
per-architecture folders:

```
architectures/
├── ntech/                 # current default — behavior unchanged
│   ├── manifest.sh        # packages, required dirs/files, check rules, naming
│   ├── lib/               # core scaffold templates (token-based)
│   └── feature/           # feature slice templates
└── clean/                 # new
    ├── manifest.sh
    ├── lib/
    └── feature/
```

`flut.sh` becomes a thin dispatch engine (same pattern already proven by
`commands/cmd_assets.sh`).

**Templating** — static files with `{{name}}`/`{{Pascal}}`/`{{pkg}}` tokens,
substituted at generation time (`sed`), replacing today's inline heredocs.
Easier to review, lint, and diff in PRs.

## Implementation phases

- **M0 — Config plumbing**: `flut.json` read/write helpers, `--architecture`
  flag on `init`, `flut architecture` command. No template changes.
- **M1 — Extract NTECH templates**: move all `cmd_init`/`cmd_feature`/
  `cmd_generate` templates into `architectures/ntech/` with tokens; extract
  package lists and `check`/`doctor` data into `manifest.sh`.
  **Success gate: all existing BATS tests pass unchanged.**
- **M2 — Clean Architecture profile**: manifest + templates. Feature slice
  becomes:
  - `domain/entities/`, `domain/repositories/<name>_repository.dart`
    (abstract interface), `domain/usecases/<name>_usecase.dart`
  - `data/models/`, `data/datasources/`, `data/repositories/<name>_repository_impl.dart`
  - `presentation/` screens + Cubit + router module
  - New `generate` types for clean: `entity`, `usecase`, `datasource`.
- **M3 — Architecture-aware `check`/`doctor`**: rules become manifest-driven.
  Clean's checks add: domain layer integrity, presentation→data import ban,
  use cases depend on interfaces not concrete repos, entities have no
  Flutter/Dio imports. `doctor`'s required dirs/files/packages come from the
  manifest.
- **M4 — Completions, tests, docs**: `--architecture` in completions; new
  `architectures.bats` + clean-specific fixtures (NTECH tests stay untouched as
  regression net); update README/`docs/commands.md`/`ARCHITECTURE.md`.
- **M5 — Release**: version bump to 0.4.0, changelog.

## Impact

### Positive

- No breaking change — existing projects and CI keep working.
- Adding future profiles (Riverpod, GetX) becomes "drop a folder + manifest",
  no `flut.sh` edits.
- `check`/`doctor` finally report truthfully per project.
- Templates as files = cleaner PRs and easier community contributions.

### Risks

- The template-extraction refactor (heredoc → file/tokens) is the riskiest
  step — whitespace/quoting bugs are possible. Mitigated by keeping the full
  NTECH BATS suite green as the gate before any Clean work starts.
- `check` must be re-expressed as data; Clean needs new rule types (use cases,
  interfaces). Scope creep is the main threat — v1 must be capped at
  **ntech + clean**.

## Sequencing

1. M0 — config plumbing + `flut architecture` command
2. M1 — ntech template extraction, all tests green, zero behavior change
3. M2 — clean manifest + templates (init/feature/generate)
4. M3 — clean check/doctor rules
5. M4 — docs + completions + CI
6. M5 — version bump + release notes
