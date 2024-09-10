{ lib, ... }:

let
  inherit (lib) mkOption types;
in

{
  options.environment.state = mkOption {
    type = types.path;
    default = /var/state;
    description = "Path to state directory";
  };
}
