# Changelog

All notable changes to `flut-cli` are documented here.

This project follows [Semantic Versioning](https://semver.org/). While the
major version is `0`, minor releases may change generated output.

## [0.3.0] — 2026-08-15

The `flut assets` command was built for this version but never tagged, so
everything below is new since `v0.2.3`.

### Added

- **Architecture profiles.** The feature layout is now a per-project choice
  recorded in `flut.json`:
  - `flut init --architecture <name>` selects one at scaffold time.
  - `flut architecture` lists the installed profiles and shows the current one;
    `flut architecture --set <name>` switches it.
  - Projects without a `flut.json` behave exactly as before.
- **Clean Architecture profile** (`clean`). A feature becomes a vertical cut
  through `domain/` (entities, repository interfaces, use cases), `data/`
  (models, data sources, repository implementations) and `presentation/`.
  Dependencies point inwards only. It shares the `ntech` core scaffold and adds
  `lib/core/usecase/usecase.dart`.
- **New generators for `clean`:** `flut generate entity|usecase|datasource`.
  Every generator now creates the pieces it depends on when they are missing,
  so generated code always resolves.
- **Architecture-aware `flut check`.** Required feature directories, banned
  packages and package-provided DI classes come from the active profile, and a
  profile can contribute its own rules. `clean` adds four: entities free of
  Flutter, Dio and JSON; nothing in `domain/` importing `data/`; use cases
  depending on repository interfaces rather than implementations; and
  repository implementations declaring the contract they satisfy.
- **`flut assets`** — analyze and clean up unused Flutter assets, backed by a
  Dart AST engine:
  - `flut assets check` lists unused assets by wasted size, exiting `1` when
    any are found so it can gate CI.
  - `flut assets stats` breaks usage down by category.
  - `flut assets audit` compares `pubspec.yaml` declarations against code.
  - `flut assets clean [--all] [--dry-run]` removes them, interactively or in
    bulk.
- `flut feature` and the repository/data source generators now register the
  feature's REST collection in `lib/core/api/api_endpoints.dart`, so a new
  feature compiles without a manual edit.
- Shell completions cover `--architecture` and derive the valid `generate`
  types from the project's profile.

### Changed

- `flut.sh` is now an entrypoint; each command lives in `commands/cmd_*.sh` and
  each profile in `architectures/<name>/`. Scaffold templates are files rather
  than inline heredocs, so they can be reviewed and diffed.
- `flut assets clean --all` now shows what it is about to remove and asks for
  confirmation once, instead of deleting immediately.
- `flut check` no longer treats every `*_state.dart` as a bloc state; only
  files under `lib/features/` are audited, so presentation widgets such as
  `shared/widgets/empty_state.dart` are left alone.
- The `flut feature` checklist reports the endpoint that was registered rather
  than asking you to add it.
- `shellcheck` in CI covers every shell file, and the integration job scaffolds
  both profiles, runs `build_runner` and requires `flutter analyze` to be clean.

### Fixed

- **Generated projects now analyze clean.** A scaffolded project previously
  reported 16 analyzer issues, 9 of them errors:
  - Feature router modules declared `part '<name>_router_module.g.dart'`, but
    auto_route generates `<name>_router_module.gr.dart` as a standalone
    library, so every generated router module failed to compile.
  - A `--bloc` screen referenced `<Name>Load`/`<Name>Refresh` without importing
    the event file; the bloc now re-exports its events.
  - `service_locator.dart` passed `encryptedSharedPreferences`, removed in
    `flutter_secure_storage` 11 where AES-GCM is already the default.
  - Screens cast `state` inside switch arms that already promote it.
  - `AppBlocObserver` parameter names did not match the methods they override.
- **Generated state managers type-checked incorrectly.** `flut generate
  cubit|bloc` emitted into the feature's shared state while reading a
  component-named repository, producing `List<XModel>` where `List<YModel>` was
  required. They now read the feature's repository (`ntech`) or use case
  (`clean`).
- `flut generate screen` always wired a Cubit, so it referenced a missing class
  on a `--bloc` feature. It now binds to whichever state manager the feature
  uses.
- `flut generate repository` imported a model it never created.
- **`flut assets` did not work outside the author's machine.** The engine's
  `package_config.json` was committed with absolute paths into a specific
  `~/.pub-cache`; the engine is now resolved locally on first use.
- `flut assets` reported every file as `0 B` on Linux (`stat -f%z` is BSD-only),
  `assets check` never exited non-zero, and `assets stats` aborted silently
  when nothing matched.
- The asset analyzer ignored bare filename references such as `'logo.png'`, so
  assets used through a runtime-built path were reported unused — and
  `assets clean` would delete them.
- The interactive asset prompt read `/dev/tty` and so failed wherever there was
  no terminal, including CI and piped input.
- `flut assets <unknown>` printed usage and exited `0`; the git guard reported a
  dirty tree when there was no repository at all.
- `flut doctor` reported a `[[: 0` error instead of "All packages up to date"
  whenever no package was upgradable.
- `flut check` reported every DI registration as missing, because it looked for
  a PascalCase filename when `flut` writes snake_case, and it counted
  commented-out registrations.
- `completions/flut.zsh` called `compdef` at load time and exited `127` when
  sourced before `compinit`.
- A `flut.sh` copied without its `commands/` directory failed with
  `cmd_upgrade: command not found`; it now reports a partial install.

## [0.2.3] and earlier

See the [GitHub releases](https://github.com/loicgeek/flut-cli/releases).

[0.3.0]: https://github.com/loicgeek/flut-cli/releases/tag/v0.3.0
[0.2.3]: https://github.com/loicgeek/flut-cli/releases/tag/v0.2.3
