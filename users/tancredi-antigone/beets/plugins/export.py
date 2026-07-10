"""Export-only tag transforms, applied when writing export copies (never the
master FLACs). The write path is matched to an export profile; each profile has
its own rules, so future formats (e.g. Opus) get their own handler.

MP3 (DJ-oriented):
    - GENRE is lowered to the track's single MACROGENRE instead of the granular
      multi-genre list.
    - The record label goes into TPUB (native `label`), which Traktor/Rekordbox
      read, rather than ORGANIZATION.
    - An untitled grooved-disc track gets its position appended to the title
      (e.g. "Untitled (A1)"); the master keeps verbatim "Untitled" and the file
      name is unaffected.
    - Master-only fields (schema extras, reissue detail, ORGANIZATION) dropped.
"""

from beets.plugins import BeetsPlugin

from beetsplug._shared import export_profile

UNTITLED = "Untitled"

# Master-only fields dropped from the DJ-oriented MP3 export. `macrogenre` is
# folded into GENRE, and `labels` (ORGANIZATION) is replaced by the TPUB label.
MASTER_ONLY = (
    "macrogenre",
    "source",
    "series",
    "seriesnumber",
    "record_track",
    "record_size",
    "record_rpm",
    "original_label",
    "original_catalognumber",
    "original_date",
    "original_year",
    "original_month",
    "original_day",
    "labels",
    "releasetype",
    "media",
    "country",
)


class ExportPlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()
        self._rules = {"mp3": self._mp3_rules}
        self.register_listener("write", self._on_write)

    def _on_write(self, item, path, tags):
        profile = export_profile(path)
        if profile and profile.name in self._rules:
            self._rules[profile.name](item, tags)

    def _mp3_rules(self, item, tags):
        macrogenre = item.get("macrogenre")
        if macrogenre:
            tags["genre"] = macrogenre
            tags["genres"] = [macrogenre]

        record_track = item.get("record_track")
        if record_track and item.get("title") == UNTITLED:
            tags["title"] = f"{UNTITLED} ({record_track})"

        labels = item.get("labels")
        tags["label"] = labels[0] if labels else None

        for field in MASTER_ONLY:
            tags[field] = None
