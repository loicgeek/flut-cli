#!/usr/bin/env bash
# =============================================================================
#  flut assets — Analyse et nettoyage des assets Flutter inutilisés (Ultra Fast)
#  Sourcé par flut.sh ; hérite de tous les globals et fonctions de log.
# =============================================================================

# Convertit les octets en format lisible (B / KB / MB).
_assets_human_size() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    if (b < 1024)         { printf "%d B\n",    b }
    else if (b < 1048576) { printf "%.1f KB\n", b/1024 }
    else                  { printf "%.1f MB\n", b/1048576 }
  }'
}

# Retourne la taille en octets d'un fichier (portable et rapide).
_assets_file_size() {
  wc -c < "$1" | tr -d ' '
}

# --- MOTEUR D'OPTIMISATION ULTRA-RAPIDE (ANTI-DOUBLONS) ---

declare -A _ASSET_MATCHES

# Pré-scanne le dossier lib/ en UNE SEULE PASSE via grep pour charger le cache.
_assets_preload_cache() {
  _ASSET_MATCHES=()
  
  # 1. On extrait un chemin partiel unique discriminant (ex: "images/logo.png")
  # au lieu du simple "logo.png" pour gérer parfaitement les fichiers de même nom.
  local patterns_file
  patterns_file="$(mktemp)"
  
  while IFS= read -r asset; do
    echo "${asset#assets/}" >> "$patterns_file"
  done < <(_assets_list_files)
  
  [[ ! -s "$patterns_file" ]] && { rm -f "$patterns_file"; return 0; }

  # 2. On cherche ces patterns uniques en une seule passe globale sur lib/
  local file line content pattern
  while IFS=: read -r file line content; do
    # On ignore les commentaires de type '//'
    [[ "$content" =~ ^[[:space:]]*// ]] && continue

    while IFS= read -r pattern; do
      if [[ "$content" == *"$pattern"* ]]; then
        _ASSET_MATCHES["$pattern"]+="$file:$line:$content"$'\n'
      fi
    done < "$patterns_file"

  done < <(grep -rnFf "$patterns_file" lib/ 2>/dev/null)

  rm -f "$patterns_file"
}

# Vérification instantanée via notre index en mémoire
_assets_is_used() {
  local asset_path="$1"
  local pattern="${asset_path#assets/}"

  local matches="${_ASSET_MATCHES["$pattern"]:-}"
  [[ -z "$matches" ]] && return 1

  # Analyse uniquement les lignes de code liées à cet asset précis
  while IFS=: read -r file line codeline; do
    [[ -z "$codeline" ]] && continue

    # Phase (b) : Si c'est une affectation de variable de type chaîne
    if [[ "$codeline" =~ (const|final|var|String)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*= ]]; then
      local var_name="${BASH_REMATCH[2]}"
      local ref_count
      # On compte les références de la variable de manière ciblée
      ref_count="$(grep -rnw --include='*.dart' "$var_name" lib/ 2>/dev/null | wc -l | tr -d ' ')"
      
      [[ "$ref_count" -gt 1 ]] && return 0
    else
      # Phase (a) : Utilisation directe (ex: Image.asset)
      return 0
    fi
  done <<< "$matches"

  return 1
}

# --- FIN DU MOTEUR ---

# Liste tous les fichiers d'assets sauf les traductions.
_assets_list_files() {
  find assets/ \
    -not -path 'assets/translations/*' \
    -type f \
    -print 2>/dev/null \
  | sort
}

# Compte total des fichiers d'assets.
_assets_count_files() {
  _assets_list_files | wc -l | tr -d ' '
}

# Affiche la barre de progression sur stderr.
_assets_progress() {
  [[ -t 2 ]] || return 0
  printf "\r  ${CYAN}->  ${RESET} [%d/%d] Checking %-55s" "$1" "$2" "$3" >&2
}

# Efface la barre de progression.
_assets_clear_progress() {
  [[ -t 2 ]] || return 0
  printf "\r%80s\r" "" >&2
}

# Catégorise les fichiers d'assets.
_assets_category() {
  case "$1" in
    assets/images/*) echo "images" ;;
    assets/icons/*)  echo "icons"  ;;
    assets/lottie/*) echo "lottie" ;;
    *)               echo "other"  ;;
  esac
}

# ==============================================================================
#  flut assets check
# ==============================================================================
_assets_cmd_check() {
  log_section "Asset Usage Check"
  echo ""

  if [[ ! -d "assets" ]]; then
    log_error "No assets/ directory found. Run from the project root."
    exit 1
  fi

  log_info "Indexing project files (Optimized Anti-Collision)..."
  _assets_preload_cache

  local unused_paths=()
  local unused_sizes=()
  local total_count=0
  local total_bytes=0
  local _total_files _scan_idx
  _total_files="$(_assets_count_files)"
  _scan_idx=0

  while IFS= read -r asset; do
    [[ -z "$asset" ]] && continue
    _scan_idx=$((_scan_idx + 1))
    _assets_progress "$_scan_idx" "$_total_files" "$asset"
    total_count=$((total_count + 1))
    local size
    size="$(_assets_file_size "$asset")"
    total_bytes=$((total_bytes + size))

    if ! _assets_is_used "$asset"; then
      unused_paths+=("$asset")
      unused_sizes+=("$size")
    fi
  done < <(_assets_list_files)
  _assets_clear_progress

  if [[ $total_count -eq 0 ]]; then
    log_info "No assets found (excluding translations)."
    echo ""
    return 0
  fi

  if [[ ${#unused_paths[@]} -eq 0 ]]; then
    log_success "All $total_count asset(s) are referenced in Dart code."
    echo ""
    return 0
  fi

  echo -e "  ${YELLOW}Unused assets:${RESET}"
  echo ""
  local total_unused_bytes=0
  local i=0
  while [[ $i -lt ${#unused_paths[@]} ]]; do
    local sz_human
    sz_human="$(_assets_human_size "${unused_sizes[$i]}")"
    echo -e "    ${YELLOW}${unused_paths[$i]}${RESET}  (${sz_human})"
    total_unused_bytes=$((total_unused_bytes + unused_sizes[i]))
    i=$((i + 1))
  done

  echo ""
  local wasted_human
  wasted_human="$(_assets_human_size "$total_unused_bytes")"
  echo -e "  ${YELLOW}${#unused_paths[@]} unused asset(s) — ${wasted_human} wasted${RESET}"
  echo -e "  Scanned: $total_count asset(s) total"
  echo ""
  return 1
}

# ==============================================================================
#  flut assets stats
# ==============================================================================
_assets_cmd_stats() {
  log_section "Asset Statistics"
  echo ""

  if [[ ! -d "assets" ]]; then
    log_error "No assets/ directory found. Run from the project root."
    exit 1
  fi

  log_info "Indexing project files (Optimized Anti-Collision)..."
  _assets_preload_cache

  local count_images=0 bytes_images=0 uc_images=0 ub_images=0
  local count_icons=0  bytes_icons=0  uc_icons=0  ub_icons=0
  local count_lottie=0 bytes_lottie=0 uc_lottie=0 ub_lottie=0
  local count_other=0  bytes_other=0  uc_other=0  ub_other=0
  local grand_total=0  grand_bytes=0  grand_uc=0   grand_ub=0
  local _total_files _scan_idx
  _total_files="$(_assets_count_files)"
  _scan_idx=0

  while IFS= read -r asset; do
    [[ -z "$asset" ]] && continue
    _scan_idx=$((_scan_idx + 1))
    _assets_progress "$_scan_idx" "$_total_files" "$asset"
    local size cat used
    size="$(_assets_file_size "$asset")"
    cat="$(_assets_category "$asset")"
    if _assets_is_used "$asset"; then used=1; else used=0; fi

    grand_total=$((grand_total + 1))
    grand_bytes=$((grand_bytes + size))
    if [[ $used -eq 0 ]]; then
      grand_uc=$((grand_uc + 1))
      grand_ub=$((grand_ub + size))
    fi

    case "$cat" in
      images)
        count_images=$((count_images + 1)); bytes_images=$((bytes_images + size))
        [[ $used -eq 0 ]] && { uc_images=$((uc_images + 1)); ub_images=$((ub_images + size)); }
        ;;
      icons)
        count_icons=$((count_icons + 1)); bytes_icons=$((bytes_icons + size))
        [[ $used -eq 0 ]] && { uc_icons=$((uc_icons + 1)); ub_icons=$((ub_icons + size)); }
        ;;
      lottie)
        count_lottie=$((count_lottie + 1)); bytes_lottie=$((bytes_lottie + size))
        [[ $used -eq 0 ]] && { uc_lottie=$((uc_lottie + 1)); ub_lottie=$((ub_lottie + size)); }
        ;;
      other)
        count_other=$((count_other + 1)); bytes_other=$((bytes_other + size))
        [[ $used -eq 0 ]] && { uc_other=$((uc_other + 1)); ub_other=$((ub_other + size)); }
        ;;
    esac
  done < <(_assets_list_files)
  _assets_clear_progress

  if [[ $grand_total -eq 0 ]]; then
    log_info "No assets found (excluding translations)."
    echo ""
    return 0
  fi

  local sep="  ─────────────────────────────────────────────────────"
  printf "  ${BOLD}%-10s  %6s  %10s  %8s  %12s${RESET}\n" \
    "Category" "Count" "Size" "Unused" "Unused size"
  echo "$sep"

  _assets_print_row() {
    local cat="$1" count="$2" bytes="$3" uc="$4" ub="$5"
    [[ $count -eq 0 ]] && return
    local sz_h ub_h
    sz_h="$(_assets_human_size "$bytes")"
    ub_h="$(_assets_human_size "$ub")"
    local unused_display="$uc"
    [[ $uc -eq 0 ]] && unused_display="${GREEN}${uc}${RESET}" || unused_display="${YELLOW}${uc}${RESET}"
    printf "  %-10s  %6d  %10s  " "$cat" "$count" "$sz_h"
    echo -ne "${unused_display}"
    printf "  %12s\n" "$ub_h"
  }

  _assets_print_row "images" "$count_images" "$bytes_images" "$uc_images" "$ub_images"
  _assets_print_row "icons"  "$count_icons"  "$bytes_icons"  "$uc_icons"  "$ub_icons"
  _assets_print_row "lottie" "$count_lottie" "$bytes_lottie" "$uc_lottie" "$ub_lottie"
  _assets_print_row "other"  "$count_other"  "$bytes_other"  "$uc_other"  "$ub_other"

  echo "$sep"
  local gtotal_sz grand_ub_h
  gtotal_sz="$(_assets_human_size "$grand_bytes")"
  grand_ub_h="$(_assets_human_size "$grand_ub")"
  local uc_display
  [[ $grand_uc -eq 0 ]] && uc_display="${GREEN}${grand_uc}${RESET}" || uc_display="${YELLOW}${grand_uc}${RESET}"
  printf "  ${BOLD}%-10s  %6d  %10s  ${RESET}" "Total" "$grand_total" "$gtotal_sz"
  echo -ne "${uc_display}"
  printf "  ${BOLD}%12s${RESET}\n" "$grand_ub_h"
  echo ""
}

# ==============================================================================
#  flut assets clean [--all] [--dry-run]
# ==============================================================================
_assets_cmd_clean() {
  local do_all=false dry_run=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)     do_all=true;  shift ;;
      --dry-run) dry_run=true; shift ;;
      *)
        log_error "Unknown flag: $1"
        echo "  Usage: flut assets clean [--all] [--dry-run]"
        exit 1
        ;;
    esac
  done

  local section_label="Asset Cleanup"
  [[ "$dry_run" == true ]] && section_label="Asset Cleanup (dry run)"
  log_section "$section_label"
  echo ""

  if [[ ! -d "assets" ]]; then
    log_error "No assets/ directory found. Run from the project root."
    exit 1
  fi

  log_info "Indexing project files (Optimized Anti-Collision)..."
  _assets_preload_cache

  local unused_paths=()
  local unused_sizes=()
  local _total_files _scan_idx
  _total_files="$(_assets_count_files)"
  _scan_idx=0

  while IFS= read -r asset; do
    [[ -z "$asset" ]] && continue
    _scan_idx=$((_scan_idx + 1))
    _assets_progress "$_scan_idx" "$_total_files" "$asset"
    if ! _assets_is_used "$asset"; then
      unused_paths+=("$asset")
      unused_sizes+=("$(_assets_file_size "$asset")")
    fi
  done < <(_assets_list_files)
  _assets_clear_progress

  if [[ ${#unused_paths[@]} -eq 0 ]]; then
    log_success "No unused assets found."
    echo ""
    return 0
  fi

  local deleted_count=0
  local deleted_bytes=0

  if [[ "$do_all" == true ]]; then
    echo -e "  ${YELLOW}The following ${#unused_paths[@]} asset(s) will be deleted:${RESET}"
    echo ""
    for p in "${unused_paths[@]}"; do
      echo "    $p"
    done
    echo ""

    local confirm
    read -r -p "  Delete all? [y/N] " confirm
    echo ""

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      local i=0
      while [[ $i -lt ${#unused_paths[@]} ]]; do
        if [[ "$dry_run" == false ]]; then
          rm -- "${unused_paths[$i]}"
        fi
        log_info "Deleted: ${unused_paths[$i]}"
        deleted_count=$((deleted_count + 1))
        deleted_bytes=$((deleted_bytes + unused_sizes[i]))
        i=$((i + 1))
      done
    else
      log_info "Aborted."
      echo ""
      return 0
    fi

  else
    local i=0
    while [[ $i -lt ${#unused_paths[@]} ]]; do
      local sz_human
      sz_human="$(_assets_human_size "${unused_sizes[$i]}")"
      echo ""
      echo -e "  ${YELLOW}${unused_paths[$i]}${RESET}  (${sz_human})"
      local choice
      read -r -p "  Delete? [y/N/q] " choice
      case "$choice" in
        [Yy])
          if [[ "$dry_run" == false ]]; then
            rm -- "${unused_paths[$i]}"
          fi
          log_success "Deleted: ${unused_paths[$i]}"
          deleted_count=$((deleted_count + 1))
          deleted_bytes=$((deleted_bytes + unused_sizes[i]))
          ;;
        [Qq])
          log_info "Quit."
          break
          ;;
        *)
          log_info "Skipped."
          ;;
      esac
      i=$((i + 1))
    done
  fi

  echo ""
  local freed_human
  freed_human="$(_assets_human_size "$deleted_bytes")"
  if [[ "$dry_run" == true ]]; then
    log_info "Dry run — $deleted_count file(s) would be deleted (${freed_human})."
  else
    log_success "$deleted_count file(s) deleted — ${freed_human} freed."
  fi
  echo ""
}

_assets_usage() {
  echo ""
  echo -e "  ${BOLD}flut assets${RESET} — Detect and remove unused Flutter assets"
  echo ""
  echo -e "  ${CYAN}flut assets check${RESET}               List unused assets with sizes"
  echo -e "  ${CYAN}flut assets stats${RESET}               Statistics table by category"
  echo -e "  ${CYAN}flut assets clean${RESET}               Delete unused assets one by one"
  echo -e "  ${CYAN}flut assets clean --all${RESET}         Delete all unused (single confirmation)"
  echo -e "  ${CYAN}flut assets clean --dry-run${RESET}     Show what would be deleted"
  echo ""
}

# ==============================================================================
#  flut assets — dispatcher (Calcul automatique de la durée)
# ==============================================================================
cmd_assets() {
  local start_time=$SECONDS
  local subcmd="${1:-}"
  [[ $# -gt 0 ]] && shift || true

  case "$subcmd" in
    check)        _assets_cmd_check ;;
    stats)        _assets_cmd_stats ;;
    clean)        _assets_cmd_clean "$@" ;;
    -h|--help|"") _assets_usage ;;
    *)
      log_error "Unknown assets subcommand: $subcmd"
      echo "  Usage: flut assets <check|stats|clean>"
      exit 1
      ;;
  esac

  # Calcul et affichage de la durée d'exécution globale
  local duration=$((SECONDS - start_time))
  echo -e "  ${CYAN}Execution time:${RESET} ${duration}s"
  echo ""
}