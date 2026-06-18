#!/usr/bin/env bash
# flut-cli bash completion
# Source this file in your ~/.bashrc:
#   source ~/.flut-cli/completions/flut.bash

_flut_list_features() {
  local features=()
  if [[ -d "lib/features" ]]; then
    for d in lib/features/*/; do
      [[ -d "$d" ]] && features+=("$(basename "$d")")
    done
  fi
  echo "${features[*]}"
}

_flut_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local cmd=""
  if [[ ${COMP_CWORD} -ge 2 ]]; then
    cmd="${COMP_WORDS[1]}"
  fi

  COMPREPLY=()

  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=($(compgen -W "init feature upgrade check doctor generate --help -h" -- "$cur"))
    return
  fi

  case "$cmd" in
    feature)
      COMPREPLY=($(compgen -W "--bloc --service" -- "$cur"))
      ;;
    generate)
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "model screen repository cubit bloc" -- "$cur"))
      elif [[ "$prev" == "--feature" || "$prev" == "-f" ]]; then
        local features
        features=$(_flut_list_features)
        COMPREPLY=($(compgen -W "$features" -- "$cur"))
      else
        COMPREPLY=($(compgen -W "--feature" -- "$cur"))
      fi
      ;;
  esac
}

complete -F _flut_complete flut
