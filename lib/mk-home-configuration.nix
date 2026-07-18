# Constructor for a home: wires the flake specialArg and evaluates the
# module list with home-manager's homeManagerConfiguration. User
# configurations call this from their default.nix and never touch
# extraSpecialArgs themselves.
{ flake
, host
, system ? "x86_64-linux"
, allowUnfree ? []
, allowUnfreeUnstable ? []
, modules
}:

let
  inherit (flake.inputs.nixpkgs) lib;

  mkPkgs = input: allowed: import input {
    inherit system;
    config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) allowed;
  };
in
flake.inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = mkPkgs flake.inputs.nixpkgs allowUnfree;

  extraSpecialArgs = {
    inherit flake;
    # Transitional args; consumers still on the old names.
    lib-age = flake.lib.age;
    nixosConfiguration = flake.nixosConfigurations.${host}.config;
    packages = flake.packages.${system};
    pkgs-unstable = mkPkgs flake.inputs.nixpkgs-unstable allowUnfreeUnstable;
  };

  inherit modules;
}
