{ flake, lib, ... }:

{
  options.environment.hostName = lib.mkOption {
    type = lib.types.enum (builtins.attrNames flake.nixosConfigurations);
    description = ''
      Name of the NixOS host this home configuration deploys to. Set by
      the mkHomeConfiguration constructor from its host argument; typed
      against the flake's nixosConfigurations so an unknown host fails
      at evaluation.
    '';
  };
}
