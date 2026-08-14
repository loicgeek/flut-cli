# ==============================================================================
#  COMMAND: architecture
# ==============================================================================
cmd_architecture() {
  local sub="${1:-}"
  local current
  current="$(_arch_current)"

  case "$sub" in
    ""|list|-l|--list)
      log_section "Architectures"
      echo -e "${BOLD}  current:${RESET} $current"
      echo ""
      local a
      for a in $(_arch_list); do
        _arch_manifest "$a"
        if [[ "$a" == "$current" ]]; then
          echo -e "  ${GREEN}* $a${RESET}  $ARCH_DESCRIPTION"
        else
          echo -e "    $a  $ARCH_DESCRIPTION"
        fi
      done
      ;;
    --set|-s)
      local target="${2:-}"
      if [[ -z "$target" ]]; then
        log_error "Usage: flut architecture --set <name>"
        exit 1
      fi
      if ! _arch_exists "$target"; then
        log_error "Unknown architecture: $target"
        echo "  Installed: $(_arch_list)"
        exit 1
      fi
      _arch_write "$target"
      log_success "Architecture set to '$target'"
      ;;
    *)
      log_error "Unknown argument: $sub"
      echo "  Usage: flut architecture [list] [--set <name>]"
      exit 1
      ;;
  esac
}
