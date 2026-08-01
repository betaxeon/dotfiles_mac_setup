# MenuBar Stats preferences

`preferences.plist` is the declarative source for MenuBar Stats' shared-group
preferences. Volatile launch/version fields, public-IP state, and Bluetooth
device identifiers are intentionally excluded.

Home Manager links this file to:

```text
~/Library/Group Containers/3EYN7PPTPF.com.fabriceleyne.menubarstats/Library/Preferences/3EYN7PPTPF.com.fabriceleyne.menubarstats.plist
```

Quit MenuBar Stats before rebuilding so macOS does not retain an older cached
copy. On a new Mac the link is installed with the Home Manager generation and
MenuBar Stats reads it on first launch.

The managed target is a link into the immutable Nix store. Treat the plist in
this repository as the source of truth; settings changed through the app may
not persist across rebuilds.
