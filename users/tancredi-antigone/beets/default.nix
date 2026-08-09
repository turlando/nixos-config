# beets music-library curation for tancredi@antigone.
#
# Manages the master FLAC library on the storage pool and a transcoded MP3
# export from it, following the conventions developed in the beets-config lab:
# a label-first directory layout, a canonical Vorbis tag schema, Discogs-only
# metadata, and a `beet lint` validation command. The lab's config.yaml is
# translated here into programs.beets.settings; its custom plugins are shipped
# verbatim from ./plugins and loaded via pluginpath.
#
# The Discogs plugin builds its client at load, so it is enabled with a
# placeholder token that keeps it from starting an interactive OAuth flow. The
# real personal access token is an agenix secret merged in only at import time
# with `beet -c` (see the manage-music-library skill). Everything else (lint,
# convert, queries, the manual import lane) runs against this config with no
# secret.
{ config, flake, pkgs, ... }:
let
  # Library locations come from the target host's disko layout, so the paths
  # cannot drift from the pool definition. This is the sanctioned cross-realm
  # escape hatch: the NixOS config of the host this home deploys to.
  storage = flake.nixosConfigurations.${config.environment.hostName}.config
    .disko.devices.zpool.storage.datasets;
  flacLibrary = storage."music/electronic-flac".mountpoint;
  mp3Export = storage."music/electronic-mp3".mountpoint;

  # Filename layout, shared by the master library and the MP3 export: label
  # first, catalog number leading, dates in brackets ([original, edition] for
  # reissues, [year] otherwise), track by physical record position (A1) for
  # grooved discs else the zero-padded number, and the title prefixed with the
  # track artist on multi-artist releases. $imprint/$catno/$trackpos/$tracktitle/
  # $dates come from the paths plugin.
  layout = "$imprint/$catno - $albumartist - $album [$dates]/$trackpos. $tracktitle";
in
{
  programs.beets = {
    enable = true;

    settings = {
      directory = flacLibrary;
      # The library DB is a disposable cache, kept in the user's state dir. The
      # .keep below makes the directory exist before beets opens the sqlite file
      # (sqlite does not create missing parent directories).
      library = "${config.home.homeDirectory}/.local/state/beets/library.db";

      # Discogs is the only metadata source; MusicBrainz is never listed, so it
      # is never loaded. This token is a placeholder: it keeps the plugin from
      # starting an OAuth flow at load, and is overridden by the agenix overlay
      # at import time. It is never used to query Discogs.
      discogs.user_token = "set-via-agenix-overlay-at-import";

      # Import copies into the library (never moves) and writes tags. The wipe
      # step (metaflac, in the skill) runs on the source first, so tags come
      # from a clean slate. Low-confidence matches are skipped unless the by-id
      # overlay force-applies (the Discogs id is authoritative).
      import = {
        copy = true;
        move = false;
        write = true;
        resume = false;
        quiet_fallback = "skip";
      };

      pluginpath = [ "${./plugins}" ];
      plugins = [
        "discogs"
        "populate"
        "schema"
        "paths"
        "zero"
        "edit"
        "fromfilename"
        "fetchart"
        "convert"
        "export"
        "beetlint"
      ];

      # External cover.jpg per album folder, taken from the imported dir (Discogs
      # is not a fetchart source). Never embedded in the master FLACs; the MP3
      # export embeds a shrunk copy instead.
      art_filename = "cover";
      fetchart = {
        auto = true;
        sources = [ "filesystem" ];
        cover_names = [ "cover" ];
      };

      # MP3 export mirror: 320 kbps CBR, 44.1 kHz via soxr, ID3v2.3, embedded
      # (shrunk) cover, same folder layout. -map_metadata -1 / -fflags +bitexact
      # drop the source Vorbis comments and ffmpeg's encoder tag so only beets'
      # clean tags remain. Run on demand with `beet convert -y`.
      convert = {
        dest = mp3Export;
        format = "mp3";
        embed = true;
        id3v23 = true;
        album_art_maxwidth = 500;
        formats.mp3 = {
          command = "ffmpeg -y -i $source -vn -c:a libmp3lame -b:a 320k -af aresample=44100:resampler=soxr:precision=28 -map_metadata -1 -fflags +bitexact $dest";
          extension = "mp3";
        };
        paths.default = layout;
      };

      # Master tag hygiene: on write, keep only the canonical field set; drop
      # everything else beets would emit (empty tags, MusicBrainz/AcoustID
      # residue, duplicate key variants). Native single `label` is excluded on
      # purpose: labels live in ORGANIZATION via `labels`, and `label` is used
      # only for the path and the MP3 export's TPUB.
      zero = {
        update_database = false;
        keep_fields = [
          "title"
          "artist"
          "album"
          "albumartist"
          "track"
          "tracktotal"
          "disc"
          "disctotal"
          "genre"
          "genres"
          "date"
          "year"
          "month"
          "day"
          "original_date"
          "original_year"
          "original_month"
          "original_day"
          "catalognumbers"
          "country"
          "media"
          "releasetype"
          "remixer"
          "remixers"
          "label"
          "macrogenre"
          "source"
          "series"
          "seriesnumber"
          "record_track"
          "record_size"
          "record_rpm"
          "original_label"
          "original_catalognumber"
          "labels"
          # One artwork field keeps zero from stripping embedded art, so
          # convert's embed step survives for the MP3 export.
          "images"
        ];
      };

      # Lint vocabularies: closed enum sets, enforced by `beet lint` (beets
      # cannot enforce them at write time). Grow these as new values appear.
      beetlint.enums = {
        media = [ "CD" "File" "Vinyl" "Acetate" ];
        macrogenre = [ "Hardcore, Jungle, Drum and Bass" ];
        source = [ "Collection" "Bandcamp" ];
        record_size = [ 7 10 12 ];
        record_rpm = [ 33 45 78 ];
      };

      # Release type: exactly one primary plus any subset of the modifiers. Read
      # by the populate hook (mapping Discogs' format descriptions) and enforced
      # by lint.
      releasetype = {
        primary = [ "Album" "EP" "Single" "Compilation" ];
        modifiers = [ "Reissue" ];
      };

      # Genre vocabulary: canonical spelling -> known aliases. The populate hook
      # rewrites any alias to the canonical form; lint flags genres outside the
      # vocabulary, so it grows as Discogs/Bandcamp (or you) introduce new ones.
      genres = {
        "Drum and Bass" = [ "Drum n Bass" "DnB" "Drum 'n' Bass" ];
        "Jungle" = [ ];
        "Hardcore" = [ ];
      };

      # Directory + naming for the master library (label-first, catalog leading,
      # dates in brackets). Singletons (rare here) go under Non-Album.
      paths = {
        default = layout;
        singleton = "Non-Album/$artist/$title";
      };
    };
  };

  # beets (the default package already bundles the discogs client and pillow for
  # art resizing) is added by the module above. These are the extra CLI tools
  # the workflow shells out to: ffmpeg for the MP3 transcode, flac for the
  # metaflac wipe step.
  home.packages = [ pkgs.ffmpeg pkgs.flac ];

  # Ensure the library DB's directory exists before beets opens the sqlite file.
  home.file.".local/state/beets/.keep".text = "";

  # Force-apply overlay for the Discogs import lane, loaded with `beet -c`
  # alongside the agenix token overlay (see the skill). Deployed next to the
  # config so its path is stable.
  xdg.configFile."beets/by-id.yaml".source = ./by-id.yaml;
}
