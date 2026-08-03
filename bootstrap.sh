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

EXCEPTIONS_FILE="$DIR/package-exceptions.nix"
EXCEPTIONS_TEMPLATE="$DIR/package-exceptions.default.nix"

if [[ ! -e "$EXCEPTIONS_FILE" ]]; then
  cp "$EXCEPTIONS_TEMPLATE" "$EXCEPTIONS_FILE"
  echo "    Created machine-local package-exceptions.nix"
fi

exception_has() {
  local category="$1"
  local item="$2"

  awk -v category="$category" -v item="\"$item\"" '
    $1 == category && $2 == "=" && $3 == "[" {
      in_section = 1
      next
    }
    in_section && $0 ~ /^[[:space:]]*];/ {
      exit
    }
    in_section {
      line = $0
      sub(/[[:space:]]*#.*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == item) {
        found = 1
      }
    }
    END { exit found ? 0 : 1 }
  ' "$EXCEPTIONS_FILE"
}

exception_add() {
  local category="$1"
  local item="$2"
  local marker="# bootstrap-insert:$category"

  if [[ ! "$item" =~ ^[A-Za-z0-9@+._-]+$ ]]; then
    echo "error: refusing unsafe exception item: $item" >&2
    exit 1
  fi

  if exception_has "$category" "$item"; then
    return
  fi

  if ! grep -Fq "$marker" "$EXCEPTIONS_FILE"; then
    echo "error: missing $marker in $EXCEPTIONS_FILE" >&2
    exit 1
  fi

  sed -i '' "/$marker/i\\
    \"$item\"
" "$EXCEPTIONS_FILE"
  echo "    Added $item to $category in package-exceptions.nix"
}

keep_existing_prompt() {
  local category="$1"
  local item="$2"
  local evidence="$3"
  local reply

  echo
  echo "    Found existing $item at $evidence"
  while true; do
    read -r -p "    Keep it outside this Nix configuration? [Y/n/q] " reply
    case "$reply" in
      ""|y|Y)
        exception_add "$category" "$item"
        return
        ;;
      n|N)
        echo "    $item will be managed by this configuration"
        return
        ;;
      q|Q)
        echo "error: bootstrap cancelled before making system changes" >&2
        exit 1
        ;;
      *)
        echo "    Enter y to keep it external, n to let Nix manage it, or q to quit."
        ;;
    esac
  done
}

command_outside_nix() {
  local command_name="$1"
  local command_path
  local resolved_path

  command_path="$(command -v "$command_name" 2>/dev/null || true)"
  if [[ -z "$command_path" ]]; then
    return 1
  fi

  resolved_path="$command_path"
  if [[ -e "$command_path" ]]; then
    resolved_path="$(cd "$(dirname "$command_path")" && pwd -P)/$(basename "$command_path")"
  fi

  if [[ "$resolved_path" == /nix/store/* ]]; then
    return 1
  fi

  printf '%s\n' "$command_path"
}

echo "==> Step 2: preserve pre-existing software"
if [[ ! -r "$EXCEPTIONS_FILE" ]]; then
  echo "error: missing $EXCEPTIONS_FILE" >&2
  exit 1
fi

if ! PACKAGE_CATALOG="$("$NIX_BIN" eval --raw --file "$DIR/bootstrap-package-catalog.nix")"; then
  echo "error: could not read the bootstrap package catalog" >&2
  exit 1
fi

while IFS=$'\t' read -r category item checks; do
  [[ -n "$category" && -n "$item" && -n "$checks" ]] || continue
  if exception_has "$category" "$item"; then
    continue
  fi

  evidence=""
  IFS=':' read -r -a candidates <<< "$checks"
  for candidate in "${candidates[@]}"; do
    case "$category" in
      casks|masApps)
        if [[ -e "$candidate" ]]; then
          evidence="$candidate"
          break
        fi
        ;;
      brews|nixPackages)
        evidence="$(command_outside_nix "$candidate" || true)"
        if [[ -n "$evidence" ]]; then
          break
        fi
        ;;
    esac
  done

  if [[ -n "$evidence" ]]; then
    keep_existing_prompt "$category" "$item" "$evidence"
  fi
done <<< "$PACKAGE_CATALOG"

echo "==> Step 3: personalize the configured username"
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

echo "==> Step 4: first nix-darwin switch"
sudo /usr/bin/env DOTFILES_PACKAGE_EXCEPTIONS="$EXCEPTIONS_FILE" "$NIX_BIN" run \
  github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --impure --flake "$DIR#mac"

echo "==> Done. Use ./rebuild.sh for future changes."
