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
      esac
      ;;
  esac
}

_flut_commands() {
  local commands=(
    'init:Initialize project scaffold'
    'feature:Generate a new feature module'
    'upgrade:Upgrade flut-cli to the latest version'
    'check:Audit project architecture'
    'doctor:Check project health'
    'generate:Generate a code artifact within a feature'
  )
  _describe 'command' commands
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

_flut
