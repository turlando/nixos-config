"""Populate/normalize fields from Discogs at import time.

At `import_task_apply` (before files move), fill the item-level custom fields so
a release lands in the right label folder immediately instead of "Not on Label":

    labels          <- native `label`      (unless "Not On Label*")
    catalognumbers  <- native `catalognum`  (unless "none")
    releasetype     <- Discogs' albumtype / format descriptions, mapped to one
                       primary type plus any modifiers (per `releasetype` config)
    multiartist     <- 1 when the album artist is not one of the track artists
                       (a compilation or split), so the paths plugin prefixes
                       every track with its own artist; DB-only, never written

Every imported field is also NFC-normalized first, so the database (and the
paths and tags derived from it) carries the library's canonical Unicode form
regardless of what Discogs served.

The Discogs plugin stashes its release/artist IDs into the native MusicBrainz
`mb_*` fields; the library is Discogs-only and wants no MusicBrainz residue, so
those are cleared at apply (items) and `album_imported` (the album entity). The
files never carry them anyway (the zero plugin's keep_fields excludes `mb_*`).

At `album_imported`, canonicalize the album's genres to the preferred spelling
(per the `genres` config aliases). Genres are a beets album-level field, so this
has to happen once the album exists, not per item at apply time.

Fields Discogs cannot provide (`source`, `macrogenre`) and overrides (a real
catalog number when Discogs says "none") stay manual.
"""

import beets
from beets.dbcore import types
from beets.plugins import BeetsPlugin

from beetsplug._shared import nfc

# MusicBrainz ID fields the Discogs plugin populates at match time. The library
# is Discogs-only, so these are stripped at import (see module docstring).
_MB_ID_FIELDS = (
    "mb_albumid", "mb_artistid", "mb_albumartistid",
    "mb_trackid", "mb_releasetrackid", "mb_releasegroupid", "mb_workid",
)
_MB_ID_LIST_FIELDS = ("mb_artistids", "mb_albumartistids")


def _strip_musicbrainz(obj):
    """Clear every MusicBrainz ID field on an item or album; True if any changed."""
    changed = False
    for field in _MB_ID_FIELDS:
        if obj.get(field):
            obj[field] = ""
            changed = True
    for field in _MB_ID_LIST_FIELDS:
        if obj.get(field):
            obj[field] = []
            changed = True
    return changed


def _multiartist(items):
    """1 when the release is multi-artist (a compilation or split), else 0.

    A release is multi-artist when its album artist is not one of the track
    artists: a synthetic "Various" or "X / Y" join rather than a single
    performer. A solo album, even one with a guest track, keeps its album artist
    as one of the track artists, so it stays single-artist.
    """
    artists = {(it.get("artist") or "").strip() for it in items}
    albumartist = (items[0].get("albumartist") or "").strip() if items else ""
    return 1 if albumartist and albumartist not in artists else 0


class PopulatePlugin(BeetsPlugin):
    # DB-only marker (no media field, so it is never written to the files); read
    # by the paths plugin's $tracktitle to prefix each track with its artist.
    item_types = {"multiartist": types.INTEGER}

    def __init__(self):
        super().__init__()
        self.register_listener("import_task_apply", self._populate)
        self.register_listener("album_imported", self._finalize_album)

    def _populate(self, session, task):
        primary, modifiers = self._release_types()
        items = task.imported_items()
        multiartist = _multiartist(items)
        for item in items:
            # Canonical Unicode form first, so the fields derived below (and
            # the paths and tags derived from them later) start from NFC.
            for key, value in list(item.items()):
                normalized = nfc(value)
                if normalized != value:
                    item[key] = normalized

            _strip_musicbrainz(item)

            item.multiartist = multiartist

            label = (item.get("label") or "").strip()
            item.labels = [label] if label and not label.startswith("Not On Label") else ["none"]

            catno = (item.get("catalognum") or "").strip()
            item.catalognumbers = [catno] if catno and catno.lower() != "none" else ["none"]

            # Discogs may join the format descriptions into one comma value
            # ("FLAC, Single, Reissue"), so split on commas and match each token.
            tokens = [
                part.strip().lower()
                for value in (item.get("albumtypes") or [])
                for part in value.split(",")
            ]
            types = [primary[t] for t in tokens if t in primary][:1]
            types += [modifiers[t] for t in tokens if t in modifiers]
            if types:
                item.releasetype = types

    def _finalize_album(self, lib, album):
        # Canonicalize genres to the preferred spelling.
        aliases = self._genre_aliases()
        original = list(album.genres or [])
        canonical = [aliases.get(g.lower(), g) for g in original]
        changed = False
        if canonical != original:
            album.genres = canonical
            changed = True
            for item in album.items():
                item.try_write()
        # The album entity carries its own mb_* copies (items are handled at
        # apply); strip them too. DB-only, so no file rewrite.
        if _strip_musicbrainz(album):
            changed = True
        if changed:
            album.store()

    def _release_types(self):
        cfg = beets.config["releasetype"]
        return (
            {t.lower(): t for t in cfg["primary"].get(list)},
            {t.lower(): t for t in cfg["modifiers"].get(list)},
        )

    def _genre_aliases(self):
        view = beets.config["genres"]
        mapping = {}
        for canonical in view.keys():
            mapping[canonical.lower()] = canonical
            for alias in view[canonical].get(list):
                mapping[alias.lower()] = canonical
        return mapping
