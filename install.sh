#!/usr/bin/env bash
#
# Symlinks every file under home/ into the real $HOME, at the same
# relative path. Existing real files are backed up (not overwritten).
#
# Usage: ./install.sh
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$DOTFILES_DIR/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

if [[ ! -d "$SRC_ROOT" ]]; then
  echo "error: $SRC_ROOT not found" >&2
  exit 1
fi

backed_up=0

while IFS= read -r -d '' src; do
  rel="${src#"$SRC_ROOT"/}"
  target="$HOME/$rel"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    # already a symlink; replace it (covers re-runs / pointing elsewhere)
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$target" "$BACKUP_DIR/$rel"
    backed_up=1
  fi

  ln -s "$src" "$target"
  echo "linked $rel"
done < <(find "$SRC_ROOT" -type f -print0)

if [[ "$backed_up" -eq 1 ]]; then
  echo
  echo "Existing files were backed up to: $BACKUP_DIR"
fi

echo
echo "Done. Reference README.md for the packages this config expects."
