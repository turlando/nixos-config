lib:

let
  inherit (lib.lists) imap1;
in
{
  grubMirroredBoots = drives:
    imap1
      (index: drive: {
        devices = [ (toString drive) ];
        path    = "/boot/${toString index}";
      })
      drives;
}
