{ ... }:

let
  user = "garyg";
  home = "/Users/${user}";
  dotfiles = "${home}/.dotfiles";
in

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    inherit home;
  };

  system.activationScripts.dotfiles.text = ''
    ln -sfn "${dotfiles}/.zshrc" "${home}/.zshrc"
    ln -sfn "${dotfiles}/.zprofile" "${home}/.zprofile"
    ln -sfn "${dotfiles}/.tmux.conf" "${home}/.tmux.conf"
    ln -sfn "${dotfiles}/.wezterm.lua" "${home}/.wezterm.lua"
    ln -sfn "${dotfiles}/.gitconfig" "${home}/.gitconfig"
  '';

  system.stateVersion = 6;
}
