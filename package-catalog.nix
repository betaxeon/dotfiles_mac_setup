{
  brews = [
    # Optional Mac package; required by the project's H.264 cropping workflow.
    { name = "ffmpeg"; commands = [ "ffmpeg" ]; }
    { name = "gh"; commands = [ "gh" ]; }
    # Optional Mac package; useful for frame-accurate project preview.
    { name = "mpv"; commands = [ "mpv" ]; }
    { name = "node@24"; commands = [ "node" ]; }
    { name = "tmux"; commands = [ "tmux" ]; }
    { name = "xcodes"; commands = [ "xcodes" ]; }
  ];

  # All catalog entries are optional to the base Mac setup. ffmpeg-full is
  # intentionally not installed; this project needs only standard ffmpeg.

  casks = [
    { name = "chatgpt"; appPaths = [ "/Applications/ChatGPT.app" ]; }
    { name = "cmux"; appPaths = [ "/Applications/cmux.app" ]; }
    # Codex is distributed by Homebrew as a CLI cask, not a GUI app bundle.
    { name = "codex"; appPaths = [ "/opt/homebrew/bin/codex" "/usr/local/bin/codex" ]; }
    { name = "docker-desktop"; appPaths = [ "/Applications/Docker.app" ]; }
    { name = "google-chrome"; appPaths = [ "/Applications/Google Chrome.app" ]; }
    { name = "iina"; appPaths = [ "/Applications/IINA.app" ]; }
    { name = "iterm2"; appPaths = [ "/Applications/iTerm.app" ]; }
    { name = "opensuperwhisper"; appPaths = [ "/Applications/OpenSuperWhisper.app" ]; }
    { name = "ollama-app"; appPaths = [ "/Applications/Ollama.app" ]; }
    { name = "pearcleaner"; appPaths = [ "/Applications/Pearcleaner.app" ]; }
    { name = "rectangle"; appPaths = [ "/Applications/Rectangle.app" ]; }
    { name = "shutter-encoder"; appPaths = [ "/Applications/Shutter Encoder.app" ]; }
    { name = "visual-studio-code"; appPaths = [ "/Applications/Visual Studio Code.app" ]; }
    { name = "wechat"; appPaths = [ "/Applications/WeChat.app" ]; }
    { name = "wezterm"; appPaths = [ "/Applications/WezTerm.app" ]; }
    { name = "localsend"; appPaths = [ "/Applications/LocalSend.app" ]; }
  ];

  masApps = [
    {
      name = "MenuBar Stats";
      id = 714196447;
      appPaths = [ "/Applications/MenuBar Stats.app" ];
    }
  ];

  nixPackages = [
    { name = "ollama"; commands = [ "ollama" ]; }
    # Optional project tooling: a Python environment with cv2 available.
    { name = "opencv-python"; commands = [ ]; }
    { name = "ripgrep"; commands = [ "rg" ]; }
    { name = "fd"; commands = [ "fd" ]; }
    { name = "fzf"; commands = [ "fzf" ]; }
    { name = "jq"; commands = [ "jq" ]; }
    { name = "lazygit"; commands = [ "lazygit" ]; }
    { name = "neovim"; commands = [ "nvim" ]; }
  ];

  # Hugin is not listed here because the pinned nixpkgs package is Linux-only
  # and cannot be evaluated for this Apple Silicon macOS configuration.
}
