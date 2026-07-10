"""Populate/normalize fields from Discogs at import time.

At `import_task_apply` (before files move), fill the item-level custom fields so
a release lands in the right label folder immediately instead of "Not on Label":

    labels          <- native `label`      (unless "Not On Label*")
    catalognumbers  <- native `catalognum`  (unless "none")
    releasetype     <- Discogs' albumtype / format descriptions, mapped to one
                       primary type plus any modifiers (per `releasetype` config)

At `album_imported`, canonicalize the album's genres to the preferred spelling
(per the `genres` config aliases). Genres are a beets album-level field, so this
has to happen once the album exists, not per item at apply time.

Fields Discogs cannot provide (`source`, `macrogenre`) and overrides (a real
catalog number when Discogs says "none") stay manual.
"""

import beets
from beets.plugins import BeetsPlugin


class PopulatePlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()
        self.register_listener("import_task_apply", self._populate)
        self.register_listener("album_imported", self._canonicalize_genres)

    def _populate(self, session, task):
        primary, modifiers = self._release_types()
        for item in task.imported_items():
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

    def _canonicalize_genres(self, lib, album):
        aliases = self._genre_aliases()
        original = list(album.genres or [])
        canonical = [aliases.get(g.lower(), g) for g in original]
        if canonical != original:
            album.genres = canonical
            album.store()
            for item in album.items():
                item.try_write()

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
