{ config, pkgs, lib, user, packageExceptions, ... }:

let
  packageSelection = import ./package-selection.nix {
    catalog = import ./package-catalog.nix;
    exceptions = packageExceptions;
  };
  nixPackages = {
    inherit (pkgs) ollama ripgrep fd fzf jq lazygit neovim;
    "opencv-python" = pkgs.python3.withPackages (pythonPackages: [
      pythonPackages.opencv4
    ]);
  };
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "26.05";
  xdg.enable = true;

  # CLI tools used constantly, except those kept outside Nix in the exceptions.
  home.packages = map (name: nixPackages.${name}) packageSelection.nixPackages;

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
      # Current supported low-friction mode; this CLI no longer has on-failure.
      co = "codex --sandbox workspace-write --ask-for-approval on-request";
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

  # cmux uses Ghostty for terminal rendering and its own JSON file for app
  # chrome. These settings mirror the Rose Pine Moon WezTerm theme.
  xdg.configFile = {
    "ghostty/config" = {
      source = ./app-configs/cmux/ghostty.conf;
      force = true;
    };
    "cmux/cmux.json" = {
      source = ./app-configs/cmux/cmux.json;
      force = true;
    };
  };

  # MenuBar Stats owns this preferences file at runtime. Seed it from Nix
  # only when it does not exist; do not link it into the immutable store or
  # overwrite settings changed through the app.
  home.activation.menuBarStatsPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/Library/Group Containers/3EYN7PPTPF.com.fabriceleyne.menubarstats/Library/Preferences/3EYN7PPTPF.com.fabriceleyne.menubarstats.plist"

    # Migrate the former Home Manager-managed Nix-store symlink.
    if [ -L "$target" ]; then
      $DRY_RUN_CMD rm "$target"
    fi

    if [ ! -e "$target" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
      $DRY_RUN_CMD cp ${./app-configs/menubar-stats/preferences.plist} "$target"
    fi
  '';

  # Home Manager owns these links. `force` handles the one-time transition
  # from the links previously created by configuration.nix.
  home.file = {
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
