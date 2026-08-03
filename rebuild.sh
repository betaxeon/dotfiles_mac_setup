#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
EXCEPTIONS_FILE="$DIR/package-exceptions.nix"

if [[ ! -e "$EXCEPTIONS_FILE" ]]; then
  cp "$DIR/package-exceptions.default.nix" "$EXCEPTIONS_FILE"
fi

exec sudo /usr/bin/env \
  DOTFILES_PACKAGE_EXCEPTIONS="$EXCEPTIONS_FILE" \
  /run/current-system/sw/bin/darwin-rebuild switch --impure --flake "$DIR#mac"
