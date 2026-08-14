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
  local types=(
    'model:Data model with fromJson/toJson/copyWith'
    'screen:Presentation screen widget'
    'repository:Repository with Dio error handling'
    'cubit:Cubit state manager'
    'bloc:Bloc with event class'
  )
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

compdef _flut flut
