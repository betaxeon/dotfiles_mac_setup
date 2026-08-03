{ catalog, exceptions }:

let
  enabled = category: item:
    !(builtins.elem item.name (exceptions.${category} or [ ]));
  selected = category: builtins.filter (enabled category) catalog.${category};
in
{
  brews = map (item: item.name) (selected "brews");
  casks = map (item: item.name) (selected "casks");
  masApps = builtins.listToAttrs (map
    (item: {
      inherit (item) name;
      value = item.id;
    })
    (selected "masApps"));
  nixPackages = map (item: item.name) (selected "nixPackages");
}
