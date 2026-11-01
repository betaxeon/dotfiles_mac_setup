# Sourced by bootstrap.sh and rebuild.sh after setup-options.sh.
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'error: work setup supports macOS only' >&2
  exit 1
fi

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHELL_HOME="${ZDOTDIR:-$HOME}"
case "$CONFIG_HOME/" in "$HOME/"*) ;; *) echo 'error: XDG_CONFIG_HOME must be under HOME' >&2; exit 1 ;; esac
case "$SHELL_HOME/" in "$HOME/"*) ;; *) echo 'error: ZDOTDIR must be under HOME' >&2; exit 1 ;; esac

BREW_BIN="$(command -v brew || true)"
if [[ -z "$BREW_BIN" ]]; then
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$candidate" ]]; then BREW_BIN="$candidate"; break; fi
  done
fi
if ! $SKIP_PACKAGES && [[ -z "$BREW_BIN" ]]; then
  echo 'error: work mode requires workplace-provisioned Homebrew, or --skip-packages' >&2
  exit 1
fi

BACKUP_DIR=""
backup_dir() {
  if [[ -z "$BACKUP_DIR" ]]; then
    mkdir -p "$HOME/.local/state/dotfiles/backups"
    BACKUP_DIR="$(mktemp -d "$HOME/.local/state/dotfiles/backups/work.XXXXXX")"
    echo "Backups: $BACKUP_DIR"
  fi
}

if ! $SKIP_PACKAGES; then
  echo '==> Work CLI tools (preserving existing installations)'
  # Do not update, upgrade, clean up, or change the workplace Brew installation.
  export HOMEBREW_NO_SUDO=1 HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
  export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1 HOMEBREW_NO_INSTALL_UPGRADE=1
  while read -r formula executable; do
    [[ -n "$formula" && "$formula" != \#* ]] || continue
    if [[ "$executable" != - ]] && command -v "$executable" >/dev/null 2>&1; then
      echo "Keep existing $executable"
    elif "$BREW_BIN" list --versions "$formula" >/dev/null 2>&1; then
      echo "Keep installed $formula"
    elif $DRY_RUN; then
      echo "Would install Homebrew formula: $formula"
    else
      "$BREW_BIN" install --formula "$formula"
    fi
  done < "$DIR/work-packages.txt"

  font_present=false
  for font in "$HOME"/Library/Fonts/Hack*Nerd* /Library/Fonts/Hack*Nerd*; do
    if [[ -e "$font" ]]; then font_present=true; break; fi
  done
  if $font_present || "$BREW_BIN" list --cask --versions font-hack-nerd-font >/dev/null 2>&1; then
    echo 'Keep existing Hack Nerd Font'
  elif $DRY_RUN; then
    echo "Would install Hack Nerd Font in $HOME/Library/Fonts"
  else
    "$BREW_BIN" install --cask --fontdir="$HOME/Library/Fonts" font-hack-nerd-font
  fi
fi

echo '==> Shared dotfiles'

link_file() {
  local source="$1" target="$2"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then return; fi
  # Existing work configuration can contain company rules. Keep it active.
  if [[ -e "$target" || -L "$target" ]]; then
    echo "Keep existing configuration: $target (shared version: $source)"
    return
  fi
  if $DRY_RUN; then
    echo "Would link $target -> $source"
  else
    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
  fi
}

append_source() {
  local source="$1" target="$2" line
  # %q produces a shell-safe path even if the checkout contains spaces.
  printf -v line 'source %q # dotfiles-work' "$source"
  if [[ -f "$target" ]] && grep -Fqx "$line" "$target"; then return; fi
  if [[ -L "$target" ]]; then
    echo "Keep externally managed shell file: $target"
    echo "Add this to its source configuration: $line"
    return
  fi
  if $DRY_RUN; then
    echo "Would append to $target: $line"
    return
  fi
  if [[ -e "$target" ]]; then
    backup_dir
    cp -p "$target" "$BACKUP_DIR/$(basename "$target")"
  fi
  mkdir -p "$(dirname "$target")"
  printf '\n%s\n' "$line" >> "$target"
}

append_source "$DIR/.zprofile" "$SHELL_HOME/.zprofile"
append_source "$DIR/app-configs/shell/work.zsh" "$SHELL_HOME/.zshrc"
link_file "$DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DIR/.wezterm.lua" "$HOME/.wezterm.lua"
link_file "$DIR/app-configs/cmux/ghostty.conf" "$CONFIG_HOME/ghostty/config"
link_file "$DIR/app-configs/cmux/cmux.json" "$CONFIG_HOME/cmux/cmux.json"
link_file "$DIR/home/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link_file "$DIR/home/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_file "$DIR/home/AGENTS.md" "$CONFIG_HOME/opencode/AGENTS.md"
echo 'Preserved Git configuration, credentials, and existing app/agent configuration.'

if ! $SKIP_PREFERENCES; then
  echo '==> Personal macOS preferences (managed keys are skipped)'
  if $DRY_RUN; then
    osascript -l JavaScript "$DIR/scripts/work-preferences.js" --dry-run "$DIR/macos-preferences.json"
  else
    backup_dir
    osascript -l JavaScript "$DIR/scripts/work-preferences.js" --apply \
      "$DIR/macos-preferences.json" "$BACKUP_DIR/preferences.json"
  fi
fi

echo 'Existing Dock pins are retained. GUI apps and optional project tools are not installed automatically.'
if $DRY_RUN; then
  echo 'Dry run complete. No configuration, preferences, packages, or mode selection were written.'
else
  echo 'Work setup complete. Open a new terminal; log out and back in to refresh macOS preferences.'
  echo 'Use ./rebuild.sh for subsequent changes.'
fi
