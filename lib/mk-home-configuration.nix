# Constructor for a home: wires the flake specialArg, records the target
# host in environment.hostName, and evaluates the module list with
# home-manager's homeManagerConfiguration. User configurations call this
# from their default.nix and never touch extraSpecialArgs themselves.
{ flake
, host
, system ? "x86_64-linux"
, allowUnfree ? []
, modules
}:

flake.inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import flake.inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = pkg:
      builtins.elem (flake.inputs.nixpkgs.lib.getName pkg) allowUnfree;
  };

  extraSpecialArgs = { inherit flake; };

  modules = modules ++ [ { environment.hostName = host; } ];
}
