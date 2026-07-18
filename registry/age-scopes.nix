# Secret scopes: the realms a secret is filtered for by lib/age.nix's
# mkSecrets (each entry in secrets/secrets.nix lists the scopes it belongs
# to). Surfaced by the environment.age.scopes accessor; the age profiles
# select theirs as config.environment.age.scopes.<realm>.
{
  # Scope for secrets used by OpenTofu.
  #
  infra = "infra";

  # Scope for secrets to be available at the host level and exposed
  # through the Agenix NixOS module.
  #
  nixos = "nixos";

  # Scope for secrets to be available at the user level and exposed
  # through the Agenix home-manager module.
  #
  tancredi = "tancredi";
  luminovo = "luminovo";
}
