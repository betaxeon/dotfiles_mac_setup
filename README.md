# dotfiles_mac_setup

Personal macOS dotfiles managed with nix-darwin and Home Manager.

Home Manager installs the tracked dotfiles and user tools, while nix-darwin manages machine-wide macOS and Homebrew settings. The checkout can live anywhere; there is no required `~/.dotfiles` link.

This repo also includes a starter nix-darwin configuration for use with Determinate Nix. Determinate manages the Nix daemon, so the nix-darwin config leaves `nix.enable = false`.

## Tracked Files

- `.zshrc`
- `.zprofile`
- `.tmux.conf`
- `.wezterm.lua`
- `.gitconfig`
- `flake.nix`
- `flake.lock`
- `configuration.nix`
- `home.nix`
- `bootstrap.sh`
- `rebuild.sh`

Runtime state, caches, shell history, SSH keys, editor databases, and app data are intentionally not tracked.

## Current Layout

```text
configuration.nix  -> system settings, Homebrew, and nix-homebrew
home.nix           -> packages, Zsh, Starship, and home-directory files
~/.zshrc           -> Home Manager generation
~/.zprofile        -> Home Manager generation
~/.tmux.conf       -> Home Manager generation
~/.wezterm.lua     -> Home Manager generation
~/.gitconfig       -> Home Manager generation
```

## Restore On A New Mac

Clone the repository, then run the one-time bootstrap as your normal user:

```sh
git clone git@github.com:betaxeon/dotfiles_mac_setup.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

The bootstrap:

- installs Determinate Nix when necessary;
- offers to rewrite the single bootstrap-managed username in `flake.nix`;
- performs the first nix-darwin switch.

The username rewrite intentionally changes the tracked `flake.nix`. Review it
after bootstrapping with `git diff -- flake.nix`.

After the first switch, use the rebuild script for all later changes:

```sh
./rebuild.sh
```

The switch also runs Home Manager, which refreshes the managed home files.

## Updating

Edit the source files in this checkout, run `./rebuild.sh`, then commit and push from this repo. Home Manager's generated links point into the immutable Nix store, so edit the checkout rather than the files in your home directory.

```sh
cd ~/dotfiles
git status
git add .
git commit -m "Update dotfiles"
git push
```
