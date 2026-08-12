
eval "$(/opt/homebrew/bin/brew shellenv)"

# Prefer packages managed by Home Manager (including the OpenCV Python
# environment) over same-named Homebrew executables.
if [ -d "/etc/profiles/per-user/${USER}/bin" ]; then
  export PATH="/etc/profiles/per-user/${USER}/bin:$PATH"
fi

# Hugin is installed manually; expose its bundled calibration/stitching tools.
export PATH="/Applications/Hugin/Hugin.app/Contents/MacOS:/Applications/Hugin/PTBatcherGUI.app/Contents/MacOS:$PATH"

# >>> Codex installer >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< Codex installer <<<
