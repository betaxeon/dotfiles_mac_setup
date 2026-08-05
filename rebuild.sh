#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
EXCEPTIONS_FILE="$DIR/package-exceptions.nix"

REAL_USER="$(id -un)"
FLAKE_USER_LINES="$(
  sed -nE 's/^[[:space:]]*user = "([^"]+)";[[:space:]]*# bootstrap-managed$/\1/p' \
    "$DIR/flake.nix"
)"
FLAKE_USER_COUNT="$(
  printf '%s\n' "$FLAKE_USER_LINES" |
    sed '/^$/d' |
    wc -l |
    tr -d '[:space:]'
)"

if [[ "$FLAKE_USER_COUNT" != 1 ]]; then
  echo 'error: expected exactly one "user =" line marked # bootstrap-managed' >&2
  exit 1
fi

if [[ "$FLAKE_USER_LINES" != "$REAL_USER" ]]; then
  echo "error: flake.nix is configured for $FLAKE_USER_LINES, but this account is $REAL_USER." >&2
  echo "       Run ./bootstrap.sh and approve the username update first." >&2
  exit 1
fi

if [[ ! -e "$EXCEPTIONS_FILE" ]]; then
  cp "$DIR/package-exceptions.default.nix" "$EXCEPTIONS_FILE"
fi

exec sudo /usr/bin/env \
  DOTFILES_PACKAGE_EXCEPTIONS="$EXCEPTIONS_FILE" \
  /run/current-system/sw/bin/darwin-rebuild switch --impure --flake "$DIR#mac"
