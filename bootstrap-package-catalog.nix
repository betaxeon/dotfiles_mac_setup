let
  catalog = import ./package-catalog.nix;
  join = builtins.concatStringsSep ":";
  line = category: item: values:
    "${category}\t${item.name}\t${join values}";
  lines =
    map (item: line "brews" item item.commands) catalog.brews
    ++ map (item: line "casks" item item.appPaths) catalog.casks
    ++ map (item: line "masApps" item item.appPaths) catalog.masApps
    ++ map (item: line "nixPackages" item item.commands) catalog.nixPackages;
in
builtins.concatStringsSep "\n" lines
