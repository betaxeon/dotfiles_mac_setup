
if ! command -v brew >/dev/null 2>&1; then
  for _dotfiles_brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$_dotfiles_brew" ]; then
      eval "$("$_dotfiles_brew" shellenv)"
      break
    fi
  done
  unset _dotfiles_brew
fi

# Prefer packages managed by Home Manager (including the OpenCV Python
# environment) over same-named Homebrew executables.
if [ -d "/etc/profiles/per-user/${USER}/bin" ]; then
  export PATH="/etc/profiles/per-user/${USER}/bin:$PATH"
fi

# Hugin is installed manually; expose its bundled calibration/stitching tools.
for _dotfiles_bin in /Applications/Hugin/Hugin.app/Contents/MacOS \
  /Applications/Hugin/PTBatcherGUI.app/Contents/MacOS "$HOME/.local/bin"; do
  if [ -d "$_dotfiles_bin" ]; then
    case ":$PATH:" in
      *":$_dotfiles_bin:"*) ;;
      *) export PATH="$PATH:$_dotfiles_bin" ;;
    esac
  fi
done
unset _dotfiles_bin
