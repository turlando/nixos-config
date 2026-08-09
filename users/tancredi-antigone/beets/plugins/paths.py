"""Path template fields derived from the schema, for use in `paths`.

    $imprint    primary label (first of labels), rendered as "Not on Label" when
                it is missing (the "none" sentinel, or empty). Used instead of
                native `label`, whose value lives in the ORGANIZATION tag via our
                `labels` field.
    $catno      primary catalog number (first of catalognumbers), or "none"
                when the release has none (matching Discogs' own convention),
                since the native single `catalognum` is disabled by the schema
                plugin.
    $trackpos   physical track position for the filename: the record side+index
                (e.g. A1) for grooved discs, otherwise the zero-padded track
                number, disc-prefixed when the release has more than one disc.
    $tracktitle track filename body: "Artist - Title" on a multi-artist release
                (a compilation or split, flagged `multiartist` by the populate
                plugin), else just "Title", since a single-artist folder already
                names the album artist.
    $dates      release dates for the bracket: "original, edition" for reissues,
                "year" otherwise (wrap as [$dates] in the path). Computed here
                because beets' `%if` cannot carry the literal comma.
"""

from beets.plugins import BeetsPlugin

from beetsplug._shared import MISSING, NOT_ON_LABEL


def _imprint(item):
    labels = item.get("labels")
    primary = labels[0] if labels else MISSING
    return NOT_ON_LABEL if primary == MISSING else primary


def _primary_catno(item):
    catalogs = item.get("catalognumbers")
    return catalogs[0] if catalogs else MISSING


def _track_position(item):
    record_track = item.get("record_track")
    if record_track:
        return record_track
    track = item.get("track") or 0
    if (item.get("disctotal") or 1) > 1:
        return f"{item.get('disc') or 0}-{track:02d}"
    return f"{track:02d}"


def _track_title(item):
    # On a multi-artist release (a compilation or split, flagged `multiartist`
    # by the populate plugin) the folder is named for a synthetic album artist
    # ("Various", or an "X / Y" join), so prefix each track with its own artist:
    # "01. Artist - Title". A single-artist release keeps just the title (even
    # one with a guest track: it is still that artist's album), since the folder
    # already names the album artist. The decision is album-level, so a release
    # is never a mix of prefixed and unprefixed tracks.
    title = item.get("title") or ""
    if item.get("multiartist"):
        artist = (item.get("artist") or "").strip()
        if artist:
            return f"{artist} - {title}"
    return title


def _dates(item):
    year = item.get("year") or ""
    original = item.get("original_year")
    if original and original != item.get("year"):
        return f"{original}, {year}"
    return f"{year}"


class PathsPlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()
        self.template_fields = {
            "imprint": _imprint,
            "catno": _primary_catno,
            "trackpos": _track_position,
            "tracktitle": _track_title,
            "dates": _dates,
        }
