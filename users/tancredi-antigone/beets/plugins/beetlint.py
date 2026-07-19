"""Custom lint command: validate the library against the collection's rules.

  - Required fields must be present (a value, or the "none" sentinel where that
    is valid); grooved-disc releases also require the record position/size/rpm.
  - Closed-enum fields (config `beetlint.enums`) must hold an allowed value.
  - `releasetype` (config `releasetype`): exactly one primary type plus any
    subset of the modifiers.
  - Every genre must be in the vocabulary (config `genres`).
  - Album-shared fields must agree across every track of a release.

Failures are reported as typed `Violation`s, each of which renders its own
message.
"""

from collections import defaultdict
from dataclasses import dataclass

import beets
from beets import ui
from beets.plugins import BeetsPlugin
from beets.ui import Subcommand

# Media whose releases carry a physical record position/size/rpm.
GROOVED_MEDIA = {"Vinyl", "Acetate"}

# Single-valued fields every track must carry. `source` is deliberately not
# here: it is optional (validated against its enum only when present), since the
# provenance of a rip is not always known or relevant.
REQUIRED = (
    "title", "artist", "albumartist", "album",
    "track", "tracktotal", "disc", "disctotal",
    "year", "media", "macrogenre",
)
# Multi-valued fields that must be non-empty ("none" counts as present).
REQUIRED_MULTI = ("genres", "labels", "catalognumbers", "releasetype")
# Required only when the medium is a grooved disc.
REQUIRED_GROOVED = ("record_track", "record_size", "record_rpm")

# Fields that must be identical across every track of a release.
ALBUM_SHARED = (
    "albumartist", "album", "year", "original_year", "releasetype",
    "macrogenre", "source", "labels", "catalognumbers", "country",
    "media", "record_size", "genres", "tracktotal", "disctotal",
)


@dataclass(frozen=True)
class Violation:
    """A lint failure at a location (`where`); subclasses render the specifics."""

    where: str

    @property
    def message(self):
        raise NotImplementedError


@dataclass(frozen=True)
class MissingField(Violation):
    field: str

    @property
    def message(self):
        return f"{self.where}: missing {self.field}"


@dataclass(frozen=True)
class NotAllowed(Violation):
    field: str
    value: object
    allowed: tuple

    @property
    def message(self):
        return f"{self.where}: {self.field}={self.value!r} not in {list(self.allowed)}"


@dataclass(frozen=True)
class ReleaseTypeCount(Violation):
    count: int
    primary: tuple

    @property
    def message(self):
        return f"{self.where}: releasetype needs exactly one of {list(self.primary)} (has {self.count})"


@dataclass(frozen=True)
class Inconsistent(Violation):
    field: str
    values: frozenset

    @property
    def message(self):
        return f"{self.where}: {self.field} differs across tracks {set(self.values)}"


def _hashable(value):
    return tuple(value) if isinstance(value, list) else value


class BeetLintPlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()
        self.config.add({"enums": {}})

    def _enums(self):
        view = self.config["enums"]
        return {field: view[field].get(list) for field in view.keys()}

    def _release_types(self):
        cfg = beets.config["releasetype"]
        return set(cfg["primary"].get(list)), set(cfg["modifiers"].get(list))

    def _genre_vocab(self):
        return set(beets.config["genres"].keys())

    def _item_violations(self, item, enums, primary, allowed_types, genre_vocab):
        where = f"{item.albumartist} - {item.album} / {item.title}"

        for field in REQUIRED:
            if not item.get(field):
                yield MissingField(where, field)
        for field in REQUIRED_MULTI:
            if not (item.get(field) or []):
                yield MissingField(where, field)
        if item.get("media") in GROOVED_MEDIA:
            for field in REQUIRED_GROOVED:
                if not item.get(field):
                    yield MissingField(where, field)

        for field, allowed in enums.items():
            value = item.get(field)
            if value and value not in allowed:
                yield NotAllowed(where, field, value, tuple(allowed))

        types = item.get("releasetype") or []
        for value in types:
            if value not in allowed_types:
                yield NotAllowed(where, "releasetype", value, tuple(sorted(allowed_types)))
        n_primary = sum(1 for t in types if t in primary)
        if n_primary != 1:
            yield ReleaseTypeCount(where, n_primary, tuple(sorted(primary)))

        for genre in item.get("genres") or []:
            if genre not in genre_vocab:
                yield NotAllowed(where, "genre", genre, tuple(sorted(genre_vocab)))

    def _consistency_violations(self, items):
        albums = defaultdict(list)
        for item in items:
            albums[item.album_id].append(item)
        for group in albums.values():
            where = f"{group[0].albumartist} - {group[0].album}"
            for field in ALBUM_SHARED:
                values = frozenset(_hashable(i.get(field)) for i in group)
                if len(values) > 1:
                    yield Inconsistent(where, field, values)

    def commands(self):
        cmd = Subcommand(
            "lint",
            help="validate the library against the collection's rules",
        )

        def run(lib, opts, args):
            enums = self._enums()
            primary, modifiers = self._release_types()
            allowed_types = primary | modifiers
            genre_vocab = self._genre_vocab()

            items = list(lib.items(args))
            violations = [
                v
                for item in items
                for v in self._item_violations(item, enums, primary, allowed_types, genre_vocab)
            ]
            violations += list(self._consistency_violations(items))

            for violation in violations:
                ui.print_(violation.message)
            ui.print_(f"{len(violations)} violation(s)" if violations else "lint: clean")

        cmd.func = run
        return [cmd]
