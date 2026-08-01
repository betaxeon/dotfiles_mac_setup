#!/usr/bin/env bash
# Takes a fresh Mac from nothing to a built nix-darwin configuration.
# Run this once. After it finishes, use ./rebuild.sh for later changes.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd -P)"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "error: run this script as your normal user, without sudo" >&2
  exit 1
fi

echo "==> Step 1: Determinate Nix"
if command -v nix >/dev/null 2>&1 || [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
  echo "    Nix is already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm

  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi

if command -v nix >/dev/null 2>&1; then
  NIX_BIN="$(command -v nix)"
elif [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
  NIX_BIN=/nix/var/nix/profiles/default/bin/nix
else
  echo "error: Nix was not found after installation" >&2
  echo "       Open a new terminal and run ./bootstrap.sh again." >&2
  exit 1
fi

echo "==> Step 2: personalize the configured username"
REAL_USER="$(id -un)"
if [[ ! "$REAL_USER" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "error: unsupported macOS short username: $REAL_USER" >&2
  exit 1
fi

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
  echo "       Edit $DIR/flake.nix before continuing." >&2
  exit 1
fi

FLAKE_USER="$FLAKE_USER_LINES"
if [[ "$FLAKE_USER" == "$REAL_USER" ]]; then
  echo "    flake.nix already matches $REAL_USER"
else
  echo "    flake.nix is configured for $FLAKE_USER, but you are $REAL_USER."
  read -r -p "    Rewrite it for $REAL_USER? [y/N] " REPLY
  if [[ "$REPLY" != "y" && "$REPLY" != "Y" ]]; then
    echo "error: update flake.nix before continuing" >&2
    exit 1
  fi

  sed -i '' -E \
    "s/^([[:space:]]*user = \")[^\"]+(\";[[:space:]]*# bootstrap-managed)$/\1$REAL_USER\2/" \
    "$DIR/flake.nix"
  echo "    Updated. Review it with: git diff -- flake.nix"
fi

echo "==> Step 3: first nix-darwin switch"
sudo "$NIX_BIN" run \
  github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake "$DIR#mac"

echo "==> Done. Use ./rebuild.sh for future changes."
