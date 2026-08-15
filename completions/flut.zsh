#compdef flut
# flut-cli zsh completion
# Source this file in your ~/.zshrc:
#   source ~/.flut-cli/completions/flut.zsh

_flut_list_features() {
  local features=()
  if [[ -d "lib/features" ]]; then
    for d in lib/features/*/; do
      [[ -d "$d" ]] && features+=("$(basename "$d")")
    done
  fi
  echo "${features[@]}"
}

_flut() {
  local context state line
  typeset -A opt_args

  _arguments -C \
    '(-h --help)'{-h,--help}'[Show help]' \
    '1: :_flut_commands' \
    '*:: :->args'

  case $state in
    args)
      case ${words[1]} in
        init)
          _arguments \
            '--architecture[Architecture profile to use]:architecture:_flut_architectures' \
            '-a[Architecture profile to use]:architecture:_flut_architectures'
          ;;
        architecture)
          _arguments -C \
            '1: :_flut_arch_subcmds' \
            '*:: :->arch_args'
          case $state in
            arch_args)
              _arguments \
                '--set[Set the project architecture]:architecture:_flut_architectures' \
                '-s[Set the project architecture]:architecture:_flut_architectures'
              ;;
          esac
          ;;
        feature)
          _arguments \
            '--bloc[Use Bloc instead of Cubit]' \
            '--service[Add a service layer]' \
            ':feature name: '
          ;;
        generate)
          _arguments -C \
            '1: :_flut_generate_types' \
            '*:: :->generate_args'
          case $state in
            generate_args)
              _arguments \
                '--feature[Feature name]:feature:_flut_features'
              ;;
          esac
          ;;
        assets)
          _arguments -C \
            '1: :_flut_asset_subcmds' \
            '*:: :->asset_args'
          case $state in
            asset_args)
              case ${words[1]} in
                clean)
                  _arguments \
                    '--all[Delete all unused without per-file prompts]' \
                    '--dry-run[Show what would be deleted without deleting]'
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;
  esac
}

_flut_commands() {
  local commands=(
    'init:Initialize project scaffold'
    'feature:Generate a new feature module'
    'architecture:List installed architectures or set the project one'
    'upgrade:Upgrade flut-cli to the latest version'
    'check:Audit project architecture'
    'doctor:Check project health'
    'generate:Generate a code artifact within a feature'
    'assets:Analyze and clean up unused Flutter assets'
  )
  _describe 'command' commands
}

_flut_arch_subcmds() {
  local subcmds=(
    'list:Show installed architectures and current'
    '--set:Set the project architecture'
  )
  _describe 'subcommand' subcmds
}

_flut_architectures() {
  local file dir archs=() d
  file="${funcsourcetrace[1]%:*}"
  dir="${file:h:h}/architectures"
  for d in "$dir"/*/; do
    [[ -d "$d" ]] && archs+=("${d:t}")
  done
  if [[ ${#archs[@]} -gt 0 ]]; then
    _values 'architecture' "${archs[@]}"
  fi
}

_flut_generate_types() {
  local -A descriptions=(
    model      'Data model with fromJson/toJson'
    screen     'Presentation screen widget'
    repository 'Repository with Dio error handling'
    cubit      'Cubit state manager'
    bloc       'Bloc with event class'
    entity     'Domain entity (pure Dart)'
    usecase    'Use case built on a repository interface'
    datasource 'Remote data source for the data layer'
  )

  # The available types come from the architecture the project uses
  local file dir arch=ntech layout raw t
  file="${funcsourcetrace[1]%:*}"
  dir="${file:h:h}"
  if [[ -f flut.json ]]; then
    arch="${$(sed -nE 's/.*"architecture"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' flut.json):-ntech}"
  fi
  layout="$dir/architectures/$arch/layout.sh"
  if [[ -f "$layout" ]]; then
    raw="$(sed -nE 's/^ARCH_GENERATE_TYPES=\((.*)\)/\1/p' "$layout" | head -n 1)"
  fi
  [[ -n "$raw" ]] || raw='model screen repository cubit bloc'

  local types=()
  for t in ${=raw}; do
    types+=("${t}:${descriptions[$t]:-Generate a ${t}}")
  done
  _describe 'type' types
}

_flut_features() {
  local features
  features=($(_flut_list_features))
  if [[ ${#features[@]} -gt 0 ]]; then
    _values 'feature' "${features[@]}"
  fi
}

_flut_asset_subcmds() {
  local subcmds=(
    'check:List unused assets with sizes'
    'stats:Full statistics by category'
    'clean:Delete unused assets interactively'
  )
  _describe 'subcommand' subcmds
}

# `compdef` only exists once compinit has run. Sourcing this file before that
# (or in a non-interactive shell) should not error, so register lazily.
if (( $+functions[compdef] )); then
  compdef _flut flut
else
  # compinit has not run yet — register as soon as it does.
  autoload -Uz add-zsh-hook 2>/dev/null
  _flut_register_completion() {
    if (( $+functions[compdef] )); then
      compdef _flut flut
      add-zsh-hook -d precmd _flut_register_completion 2>/dev/null
    fi
  }
  if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook precmd _flut_register_completion
  fi
fi
