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

_flut_list_architectures() {
  local cli_dir archs=() d
  cli_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
  if [[ -n "$cli_dir" && -d "$cli_dir/architectures" ]]; then
    for d in "$cli_dir/architectures"/*/; do
      [[ -d "$d" ]] && archs+=("$(basename "$d")")
    done
  fi
  echo "${archs[*]}"
}

# Generate types depend on the architecture the current project uses
_flut_list_generate_types() {
  local cli_dir arch="ntech" layout types
  if [[ -f "flut.json" ]]; then
    arch="$(sed -nE 's/.*"architecture"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' flut.json | head -n 1)"
    [[ -n "$arch" ]] || arch="ntech"
  fi
  cli_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
  layout="$cli_dir/architectures/$arch/layout.sh"
  if [[ -f "$layout" ]]; then
    types="$(sed -nE 's/^ARCH_GENERATE_TYPES=\((.*)\)/\1/p' "$layout" | head -n 1)"
  fi
  echo "${types:-model screen repository cubit bloc}"
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
    COMPREPLY=($(compgen -W "init feature architecture upgrade check doctor generate assets clean --help -h" -- "$cur"))
    return
  fi

  case "$cmd" in
    feature)
      COMPREPLY=($(compgen -W "--bloc --service" -- "$cur"))
      ;;
    init)
      if [[ "$prev" == "--architecture" || "$prev" == "-a" ]]; then
        local archs
        archs=$(_flut_list_architectures)
        COMPREPLY=($(compgen -W "$archs" -- "$cur"))
      else
        COMPREPLY=($(compgen -W "--architecture" -- "$cur"))
      fi
      ;;
    architecture)
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "list --set" -- "$cur"))
      elif [[ "$prev" == "--set" || "$prev" == "-s" ]]; then
        local archs
        archs=$(_flut_list_architectures)
        COMPREPLY=($(compgen -W "$archs" -- "$cur"))
      fi
      ;;
    generate)
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$(_flut_list_generate_types)" -- "$cur"))
      elif [[ "$prev" == "--feature" || "$prev" == "-f" ]]; then
        local features
        features=$(_flut_list_features)
        COMPREPLY=($(compgen -W "$features" -- "$cur"))
      else
        COMPREPLY=($(compgen -W "--feature" -- "$cur"))
      fi
      ;;
    assets)
      if [[ ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "check stats clean" -- "$cur"))
      elif [[ "${COMP_WORDS[2]}" == "clean" ]]; then
        COMPREPLY=($(compgen -W "--all --dry-run" -- "$cur"))
      fi
      ;;
  esac
}

complete -F _flut_complete flut
