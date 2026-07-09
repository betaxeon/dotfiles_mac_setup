# dotfiles_mac_setup

Personal macOS dotfiles managed from `~/.dotfiles`.

The files in this repo are symlinked back into the home directory so apps and shells keep reading them from their normal locations while Git tracks the source copies here.

This repo also includes a starter nix-darwin configuration for use with Determinate Nix. Determinate manages the Nix daemon, so the nix-darwin config leaves `nix.enable = false`.

## Tracked Files

- `.zshrc`
- `.zprofile`
- `.tmux.conf`
- `.wezterm.lua`
- `.gitconfig`
- `flake.nix`
- `configuration.nix`

Runtime state, caches, shell history, SSH keys, editor databases, and app data are intentionally not tracked.

## Current Layout

```text
~/.zshrc        -> ~/.dotfiles/.zshrc
~/.zprofile     -> ~/.dotfiles/.zprofile
~/.tmux.conf    -> ~/.dotfiles/.tmux.conf
~/.wezterm.lua  -> ~/.dotfiles/.wezterm.lua
~/.gitconfig    -> ~/.dotfiles/.gitconfig
```

## Restore On A New Mac

Clone the repo into the home directory:

```sh
git clone git@github.com:betaxeon/dotfiles_mac_setup.git ~/.dotfiles
```

Create or refresh the symlinks:

```sh
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.zprofile ~/.zprofile
ln -sf ~/.dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/.dotfiles/.wezterm.lua ~/.wezterm.lua
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
```

Reload the shell configuration:

```sh
source ~/.zshrc
```

## Apply With Nix

After installing Determinate Nix, apply the nix-darwin configuration from this repo:

```sh
cd ~/.dotfiles
nix run nix-darwin -- switch --flake ~/.dotfiles#Garys-MacBook
```

The nix-darwin activation also refreshes the dotfile symlinks listed above.

## Updating

Edit files either through the home directory symlink or directly inside `~/.dotfiles`, then commit and push from this repo:

```sh
cd ~/.dotfiles
git status
git add .
git commit -m "Update dotfiles"
git push
```
