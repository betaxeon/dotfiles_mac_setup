{ pkgs, user, packageExceptions, ... }:

let
  home = "/Users/${user}";
  packageSelection = import ./package-selection.nix {
    catalog = import ./package-catalog.nix;
    exceptions = packageExceptions;
  };
  preferences = builtins.fromJSON (builtins.readFile ./macos-preferences.json);
in

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  time.timeZone = "Australia/Sydney";

  system.primaryUser = user;
  users.users.${user} = {
    inherit home;
  };

  fonts.packages = [
    pkgs.nerd-fonts.hack
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    inherit user;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    # OpenSuperWhisper is provided by the my-monkeys tap rather than the
    # default Homebrew cask tap.
    taps = [ "my-monkeys/tap" ];

    inherit (packageSelection) brews casks masApps;
  };

  # Current non-default macOS preferences captured from this Mac.
  system.defaults = {
    # The same user preferences are applied without Nix by work mode.
    CustomUserPreferences = (builtins.removeAttrs preferences [ "com.apple.controlcenter" ]) // {
      "com.apple.driver.AppleBluetoothMultitouch.trackpad" =
        preferences."com.apple.AppleMultitouchTrackpad";
    };

    controlcenter = {
      BatteryShowPercentage = preferences."com.apple.controlcenter".BatteryShowPercentage;
      Bluetooth = preferences."com.apple.controlcenter".Bluetooth == 18;
    };

    dock = {
      persistent-apps = [
        "/System/Applications/Messages.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Reminders.app"
        "/System/Applications/Notes.app"
      ];
      persistent-others = [
        {
          folder = {
            path = "${home}/Downloads";
            arrangement = "date-added";
            displayas = "stack";
            showas = "fan";
          };
        }
      ];
    };
  };

  # Charge Limit is currently set to 90% in System Settings. macOS Tahoe
  # exposes no supported command-line interface for this setting, and
  # nix-darwin does not currently provide an option that can enforce it.

  system.stateVersion = 6;
}
