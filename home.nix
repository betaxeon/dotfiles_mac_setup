{ config, pkgs, user, ... }:

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    # CLI tools used constantly.
    ripgrep
    fd
    fzf
    jq
    lazygit
    neovim

    # The font used by terminal applications.
    nerd-fonts.hack
  ];

  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = (builtins.readFile ./.zshrc) + ''

      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Home Manager owns these links. `force` handles the one-time transition
  # from the links previously created by configuration.nix.
  home.file = {
    # programs.zsh supplies the generated source for this file.
    ".zshrc".force = true;
    ".zprofile" = {
      source = ./.zprofile;
      force = true;
    };
    ".tmux.conf" = {
      source = ./.tmux.conf;
      force = true;
    };
    ".wezterm.lua" = {
      source = ./.wezterm.lua;
      force = true;
    };
    ".gitconfig" = {
      source = ./.gitconfig;
      force = true;
    };
  };
}
