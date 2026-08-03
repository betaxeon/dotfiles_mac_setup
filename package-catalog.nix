{
  brews = [
    { name = "gh"; commands = [ "gh" ]; }
    { name = "node@24"; commands = [ "node" ]; }
    { name = "tmux"; commands = [ "tmux" ]; }
    { name = "xcodes"; commands = [ "xcodes" ]; }
  ];

  casks = [
    { name = "chatgpt"; appPaths = [ "/Applications/ChatGPT.app" ]; }
    { name = "codex"; appPaths = [ "/Applications/Codex.app" ]; }
    { name = "docker-desktop"; appPaths = [ "/Applications/Docker.app" ]; }
    { name = "google-chrome"; appPaths = [ "/Applications/Google Chrome.app" ]; }
    { name = "iina"; appPaths = [ "/Applications/IINA.app" ]; }
    { name = "iterm2"; appPaths = [ "/Applications/iTerm.app" ]; }
    { name = "opensuperwhisper"; appPaths = [ "/Applications/OpenSuperWhisper.app" ]; }
    { name = "rectangle"; appPaths = [ "/Applications/Rectangle.app" ]; }
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
    { name = "ripgrep"; commands = [ "rg" ]; }
    { name = "fd"; commands = [ "fd" ]; }
    { name = "fzf"; commands = [ "fzf" ]; }
    { name = "jq"; commands = [ "jq" ]; }
    { name = "lazygit"; commands = [ "lazygit" ]; }
    { name = "neovim"; commands = [ "nvim" ]; }
  ];
}
