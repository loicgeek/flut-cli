# ==============================================================================
#  COMMAND: clean — Remove generated files
# ==============================================================================

cmd_clean() {
  local do_rebuild=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --rebuild) do_rebuild=true; shift ;;
      *) log_error "Unknown flag: $1"; usage; exit 1 ;;
    esac
  done

  log_section "Clean Generated Files"
  echo ""

  if [[ ! -d "lib" ]]; then
    log_error "lib/ directory not found — run flut clean from the project root."
    exit 1
  fi

  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find lib/ \( -name '*.gr.dart' -o -name '*.g.dart' \) -print0 2>/dev/null)

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No generated files found."
    echo ""
    log_info "Run 'dart run build_runner build --delete-conflicting-outputs' to generate them."
    echo ""
    return
  fi

  for f in "${files[@]}"; do
    rm "$f"
    log_info "Removed ${f#lib/}"
  done

  echo ""
  log_success "${#files[@]} generated file(s) removed."
  echo ""

  if [[ "$do_rebuild" == true ]]; then
    log_info "Running build_runner..."
    echo ""
    dart run build_runner build --delete-conflicting-outputs
  else
    log_info "Run 'dart run build_runner build --delete-conflicting-outputs' to regenerate."
  fi
  echo ""
}
