# dotfiles_mac_setup

Shared macOS dotfiles with `personal` and `work` setup modes.

Personal mode uses Home Manager for dotfiles and user tools, and nix-darwin for
machine-wide macOS and Homebrew settings. Work mode uses existing workplace
Homebrew and applies user preferences without Nix or sudo. The checkout can
live anywhere; there is no required `~/.dotfiles` link.

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
- `macos-preferences.json`
- `work-packages.txt`
- `scripts/`

Runtime state, caches, shell history, SSH keys, editor databases, and app data are intentionally not tracked.

## Personal Layout

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

## Restore On A Personal Mac

Clone the repository, then run the one-time bootstrap as your normal user:

```sh
git clone https://github.com/betaxeon/dotfiles_mac_setup.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh --mode personal
```

The public repository can be cloned over HTTPS without an SSH key or GitHub
sign-in. Pushing changes still requires write access and authentication.

These bootstrap instructions require administrator access. For a corporate
Mac without it, use the work instructions below.

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

## Set Up A Work Mac

| Mode | Package management | Scope |
| --- | --- | --- |
| `personal` | Nix, nix-darwin, and Homebrew | Personal Mac with administrator access |
| `work` | Existing workplace-provisioned Homebrew | CLI tools and user configuration without sudo or Nix |

```sh
git clone https://github.com/betaxeon/dotfiles_mac_setup.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh --mode work --dry-run
./bootstrap.sh --mode work
```

If the checkout already exists, update it and run the work bootstrap there.
The mode is saved in Git-ignored `.setup-mode`. Subsequent runs use:

```sh
./rebuild.sh
```

The first invocation requires an explicit mode, including for existing
personal installations: use `./rebuild.sh --mode personal` once. Neither
script guesses whether it should request administrator privileges.

Both modes use the same tracked shell, terminal, prompt, and macOS preference
sources. Home Manager installs files in personal mode. Work mode links missing
configuration files and retains existing app and agent configurations, reporting
the shared source so differences can be reviewed. It appends source lines to
regular Zsh startup files after backing them up; externally managed symlinks
are retained and the required source line is printed instead. Existing Git
configuration and work identity are left untouched.

Work mode respects `ZDOTDIR` and `XDG_CONFIG_HOME` under your home directory.
Use `~/.zshrc.local` for shell overrides. An existing `STARSHIP_CONFIG` is
respected. Keep the checkout in place because work links reference it.

Work mode assumes Homebrew is already installed. Installing formulae also
requires that the workplace has allowed your account to write to the Homebrew
installation. If it is read-only for your account, IT must install packages;
the dotfiles and preferences can still be applied with `--skip-packages`.
Work mode does not install Homebrew, change its ownership, install Nix, or
invoke nix-darwin. It preserves existing commands and installed formulae;
automatic Brew updates, install upgrades, and cleanup are disabled. Installing
a missing formula can still install or update dependencies required by it.

Work mode applies the following:

| Component | Without administrator access |
| --- | --- |
| Zsh, aliases, PATH, Starship, shell plugins | User configuration and Homebrew formulae |
| Git configuration | Existing identity, authentication, signing, and other settings retained |
| tmux, WezTerm, cmux/Ghostty configuration | Shared configuration linked when no file already exists |
| Agent instruction files | Shared instructions linked when no file already exists |
| gh, Node, tmux, ripgrep, fd, fzf, jq, LazyGit, Neovim | Missing tools installed from `work-packages.txt` |
| Hack Nerd Font | Install for the current user in `~/Library/Fonts` |
| Dock and Finder | Auto-hide, App Expose gesture, column view; existing Dock pins retained |
| Keyboard and trackpad | Repeat speed, tap-to-click, tracking speed, scrolling, click pressure, gestures |
| Window management | Personal tiling and desktop visibility preferences |
| Language and input | Australian locale, Australian/Pinyin input sources; existing languages and input sources retained |
| Menu bar | Clock formatting, battery percentage visibility, Bluetooth icon visibility (not radio state) |

`macos-preferences.json` is the shared source of user preferences. Work mode
uses macOS Core Foundation preferences APIs and checks whether each key is
managed before writing it. Only listed keys are changed, under the current
user. Existing array entries are retained. It does not restart applications;
open a new terminal after setup and log out and back in for all macOS settings
to refresh. macOS versions can differ in which preference keys they honor.

Company profiles, security policies, VPN/proxy/network configuration, login
items, services, system timezone, credentials, and runtime app data are not
modified. GUI apps, Docker/Xcode components, MenuBar Stats preferences, and
optional project tools such as Ollama, ffmpeg, mpv, and Python/OpenCV are not
installed or configured automatically. Add permitted CLI formulae to
`work-packages.txt` as needed; use company tooling for application installation.

Workplace management restrictions are separate from root access and may lock
otherwise user-configurable settings or block applications. Managed keys are
reported as skipped; setup does not try to bypass them.

Work-only options can be combined on either entry point:

```sh
./rebuild.sh --dry-run           # Preview, including managed-key checks
./rebuild.sh --skip-packages     # Apply files and preferences only
./rebuild.sh --skip-preferences  # Apply packages and files only
```

Backups are stored in `~/.local/state/dotfiles/backups/work.*`; the path is
printed during setup. To undo a preference application, pass its backup file:

```sh
osascript -l JavaScript scripts/work-preferences.js --restore /path/to/preferences.json
```

Restoration skips managed keys and keys changed since that application. Shell
backups contain the original startup files. No package removal is performed.

Homebrew documents [routine installation without sudo](https://docs.brew.sh/Installation#running-without-sudo),
including `HOMEBREW_NO_SUDO=1` and a user-writable destination for compatible
casks. Application support still needs checking individually; see
[Docker Desktop permissions](https://docs.docker.com/desktop/setup/install/mac-permission-requirements/).

## Updating

Edit the source files in this checkout, run `./rebuild.sh`, then commit and push
from this repo. Edit the checkout rather than Home Manager's immutable files
or work-mode symlink targets in your home directory. Never stage
`package-exceptions.nix` or `.setup-mode`; both are machine-local and ignored
by Git.

```sh
cd ~/dotfiles
git status
git add .
git commit -m "Update dotfiles"
git push
```

## Verification

```sh
node --test tests/work-setup.test.mjs
bash -n bootstrap.sh rebuild.sh scripts/setup-options.sh scripts/work-setup.sh
```

Tests exercise bootstrap and rebuild in temporary home directories with
package/preference tools replaced by fixtures, plus managed-key handling,
array preservation, dry runs, and preference restoration. They do not change
the current user's settings or install software.
