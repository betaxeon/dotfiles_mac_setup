{ pkgs, user, ... }:

let
  home = "/Users/${user}";
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

    brews = [
      "gh"
      "node@24"
      "tmux"
      "xcodes"
    ];

    casks = [
      "chatgpt"
      "codex"
      "docker-desktop"
      "google-chrome"
      "iina"
      "iterm2"
      "opensuperwhisper"
      "rectangle"
      "visual-studio-code"
      "wezterm"
    ];

    masApps = {
      "MenuBar Stats" = 714196447;
    };
  };

  # Current non-default macOS preferences captured from this Mac.
  system.defaults = {
    CustomUserPreferences.NSGlobalDomain = {
      AppleLanguages = [
        "en-AU"
        "zh-Hans-AU"
      ];
      AppleLocale = "en_AU";
    };

    NSGlobalDomain = {
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      "com.apple.swipescrolldirection" = false;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.scaling" = 0.875;
    };

    WindowManager = {
      EnableTiledWindowMargins = false;
      EnableTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTopTilingByEdgeDrag = false;
      HideDesktop = true;
    };

    controlcenter = {
      BatteryShowPercentage = false;
      Bluetooth = true;
    };

    dock = {
      autohide = true;
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

    finder.FXPreferredViewStyle = "clmv";

    menuExtraClock = {
      FlashDateSeparators = false;
      IsAnalog = false;
      ShowAMPM = true;
      ShowDate = 0;
      ShowDayOfWeek = true;
      ShowSeconds = true;
    };

    trackpad = {
      Clicking = true;
      FirstClickThreshold = 0;
      SecondClickThreshold = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
      TrackpadPinch = true;
      TrackpadRightClick = true;
      TrackpadRotate = true;
      TrackpadThreeFingerDrag = true;
      TrackpadThreeFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
      TrackpadTwoFingerDoubleTapGesture = true;
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;
    };
  };

  # Charge Limit is currently set to 90% in System Settings. macOS Tahoe
  # exposes no supported command-line interface for this setting, and
  # nix-darwin does not currently provide an option that can enforce it.

  system.stateVersion = 6;
}
