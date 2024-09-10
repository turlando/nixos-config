{
  defaults = import ./defaults.nix;
  ephemeral = import ./ephemeral.nix;
  slskd = import ./slskd.nix;
  state = import ./state.nix;
  zpools = import ./zpools.nix;
}
