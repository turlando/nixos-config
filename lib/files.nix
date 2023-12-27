lib:

rec {
  # type: path -> path
  getFile = path: ../files + path;

  # type: path -> string
  readFile = path: builtins.readFile (getFile path);

  # type: string -> path
  getSshKey = x: getFile (/ssh-keys + "/${x}.pub");

  # type: string -> string
  readSshKey = x: builtins.readFile (getSshKey x);

  # type: string -> string
  readPassword = x: readFile (/hashed-passwords + "/${x}.txt");
}
