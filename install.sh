#!/usr/bin/env bash
# =============================================================================
#  flut-cli installer
#  Usage: curl -fsSL https://raw.githubusercontent.com/loicgeek/flut-cli/main/install.sh | bash
# =============================================================================

set -euo pipefail

REPO="https://github.com/loicgeek/flut-cli.git"
DEST="$HOME/.flut-cli"
BIN="/usr/local/bin/flut"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

echo ""
echo -e "${BOLD}${CYAN}flut-cli installer${RESET}"
echo ""

# ── Dependencies check ────────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  echo -e "${RED}  xx  git is required but not found in PATH.${RESET}"
  exit 1
fi

# ── Clone or update ───────────────────────────────────────────────────────────
if [[ -d "$DEST/.git" ]]; then
  echo -e "${CYAN}  ->  ${RESET}Updating existing installation at $DEST ..."
  git -C "$DEST" pull --ff-only
else
  echo -e "${CYAN}  ->  ${RESET}Cloning flut-cli into $DEST ..."
  git clone "$REPO" "$DEST"
fi

chmod +x "$DEST/flut.sh"

# ── Symlink ───────────────────────────────────────────────────────────────────
if [[ -w "$(dirname "$BIN")" ]]; then
  ln -sf "$DEST/flut.sh" "$BIN"
else
  echo -e "${YELLOW}  !!  ${RESET}Need sudo to write to $(dirname "$BIN") ..."
  sudo ln -sf "$DEST/flut.sh" "$BIN"
fi

# ── Verify ────────────────────────────────────────────────────────────────────
if command -v flut &>/dev/null; then
  echo ""
  echo -e "${GREEN}${BOLD}  flut-cli installed successfully.${RESET}"
  echo ""
  echo -e "  Run ${CYAN}flut --help${RESET} to get started."
else
  echo ""
  echo -e "${YELLOW}  !!  flut not found in PATH after install.${RESET}"
  echo "      Add /usr/local/bin to your PATH, or run flut directly:"
  echo "      $DEST/flut.sh --help"
fi

echo ""