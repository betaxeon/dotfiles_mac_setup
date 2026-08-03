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
- `app-configs/cmux/ghostty.conf`
- `app-configs/cmux/cmux.json`
- `package-catalog.nix`
- `package-exceptions.default.nix`
- `package-selection.nix`
- `bootstrap.sh`
- `rebuild.sh`

Runtime state, caches, shell history, SSH keys, editor databases, and app data are intentionally not tracked.

## Current Layout

```text
configuration.nix  -> system settings, Homebrew, and nix-homebrew
home.nix           -> packages, Zsh, Starship, and home-directory files
~/.zshrc           -> Home Manager generation
~/.config/ghostty/config -> managed cmux terminal appearance
~/.config/cmux/cmux.json -> managed cmux app appearance
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
- creates a machine-local, Git-ignored `package-exceptions.nix` file;
- detects declared applications and tools that already exist and asks whether
  to preserve them outside the Nix configuration;
- offers to rewrite the single bootstrap-managed username in `flake.nix`;
- performs the first nix-darwin switch.

`package-exceptions.default.nix` is the tracked template. Its four lists are
empty by default and contain commented examples for Nix packages, Homebrew
formulae, Homebrew casks, and Mac App Store applications. Bootstrap copies it
to `package-exceptions.nix`, then records software you choose to preserve.

The local `package-exceptions.nix` is ignored by Git because its contents can
differ on every Mac. You can edit it manually using names from
`package-catalog.nix`. Adding a name prevents nix-darwin or Home Manager from
installing and managing that item; removing it makes the item declarative on
the next rebuild. Existing software is not uninstalled when it becomes an
exception.

The username rewrite intentionally changes the tracked `flake.nix`. Review it
after bootstrapping with `git diff -- flake.nix`.

After the first switch, use the rebuild script for all later changes:

```sh
./rebuild.sh
```

The switch also runs Home Manager, which refreshes the managed home files.
cmux uses the tracked Rose Pine Moon theme after the switch; run
`cmux reload-config` to refresh an already-running app.

## Updating

Edit the source files in this checkout, run `./rebuild.sh`, then commit and push
from this repo. Home Manager's generated links point into the immutable Nix
store, so edit the checkout rather than the files in your home directory.
Never stage `package-exceptions.nix`; it is machine-local and ignored by Git.

```sh
cd ~/dotfiles
git status
git add .
git commit -m "Update dotfiles"
git push
```
