"""Master tag schema: the custom, file-backed fields for the library.

Registering these makes beets read and write them as real Vorbis comments (and
MP3 TXXX frames for the export), so the metadata lives in the files, not just in
beets' database. Native fields keep beets' defaults; the allowlist in
config.yaml (the `zero` plugin) drops everything else.

`labels` uses ORGANIZATION (the Xiph-standard record-label field) and is
multi-valued, so collaboration/split releases keep every label in the FLAC. The
native `label` field (primary label) is kept out of the file allowlist and used
only for the path and the MP3 export.
"""

from dataclasses import dataclass
from enum import Enum

import mediafile
from beets.dbcore import types
from beets.plugins import BeetsPlugin

from beetsplug._shared import is_export


def _text_styles(key):
    return (mediafile.MP3DescStorageStyle(key), mediafile.StorageStyle(key))


class FieldKind(Enum):
    """The storage shape of a custom tag field: a single text value, a single
    integer value, or a multi-valued list of text (repeated Vorbis tags)."""

    TEXT = "text"
    INTEGER = "integer"
    TEXT_LIST = "text_list"

    def descriptor(self, key):
        """Build the mediafile descriptor storing this field under `key`."""
        match self:
            case FieldKind.TEXT:
                return mediafile.MediaField(*_text_styles(key))
            case FieldKind.INTEGER:
                return mediafile.MediaField(*_text_styles(key), out_type=int)
            case FieldKind.TEXT_LIST:
                return mediafile.ListMediaField(
                    mediafile.MP3ListDescStorageStyle(desc=key),
                    mediafile.ListStorageStyle(key),
                )

    def db_type(self):
        """The beets database type, so values round-trip and query correctly
        (integers as integers, lists split on `; ` rather than per character)."""
        match self:
            case FieldKind.TEXT:
                return types.STRING
            case FieldKind.INTEGER:
                return types.INTEGER
            case FieldKind.TEXT_LIST:
                return types.SEMICOLON_SPACE_DSV


@dataclass(frozen=True)
class CustomField:
    """A custom, file-backed tag: its beets field name, the physical Vorbis /
    TXXX key it is stored under, and its storage shape."""

    name: str
    key: str
    kind: FieldKind

    @property
    def descriptor(self):
        return self.kind.descriptor(self.key)


CUSTOM_FIELDS = [
    CustomField("macrogenre", "MACROGENRE", FieldKind.TEXT),
    CustomField("source", "SOURCE", FieldKind.TEXT),
    CustomField("series", "SERIES", FieldKind.TEXT),
    CustomField("seriesnumber", "SERIESNUMBER", FieldKind.INTEGER),
    CustomField("record_track", "RECORDTRACK", FieldKind.TEXT),
    CustomField("record_size", "RECORDSIZE", FieldKind.INTEGER),
    CustomField("record_rpm", "RECORDRPM", FieldKind.INTEGER),
    CustomField("original_label", "ORIGINALLABEL", FieldKind.TEXT),
    CustomField("original_catalognumber", "ORIGINALCATALOGNUMBER", FieldKind.TEXT),
    CustomField("labels", "ORGANIZATION", FieldKind.TEXT_LIST),
    CustomField("catalognumbers", "CATALOGNUMBER", FieldKind.TEXT_LIST),
    CustomField("releasetype", "RELEASETYPE", FieldKind.TEXT_LIST),
]

_ORIGINAL_DATE_FIELDS = ("original_date", "original_year", "original_month", "original_day")


def _install_native_overrides():
    """Rewrite native fields whose default mediafile mapping emits several
    duplicate Vorbis keys (e.g. TRACK + TRACKNUMBER, DATE + YEAR) down to a
    single canonical key. The MP3/MP4 styles are kept so the export still tags
    correctly; only the redundant Vorbis variants are dropped."""
    mf = mediafile.MediaFile

    mf.albumartist = mediafile.MediaField(
        mediafile.MP3StorageStyle("TPE2"),
        mediafile.MP4StorageStyle("aART"),
        mediafile.StorageStyle("ALBUMARTIST"),
    )
    mf.track = mediafile.MediaField(
        mediafile.MP3SlashPackStorageStyle("TRCK", pack_pos=0),
        mediafile.MP4TupleStorageStyle("trkn", index=0),
        mediafile.StorageStyle("TRACKNUMBER"),
        out_type=int,
    )
    mf.tracktotal = mediafile.MediaField(
        mediafile.MP3SlashPackStorageStyle("TRCK", pack_pos=1),
        mediafile.MP4TupleStorageStyle("trkn", index=1),
        mediafile.StorageStyle("TRACKTOTAL"),
        out_type=int,
    )
    mf.disc = mediafile.MediaField(
        mediafile.MP3SlashPackStorageStyle("TPOS", pack_pos=0),
        mediafile.MP4TupleStorageStyle("disk", index=0),
        mediafile.StorageStyle("DISCNUMBER"),
        out_type=int,
    )
    mf.disctotal = mediafile.MediaField(
        mediafile.MP3SlashPackStorageStyle("TPOS", pack_pos=1),
        mediafile.MP4TupleStorageStyle("disk", index=1),
        mediafile.StorageStyle("DISCTOTAL"),
        out_type=int,
    )

    date = mediafile.DateField(
        mediafile.MP3StorageStyle("TDRC"),
        mediafile.MP4StorageStyle("\xa9day"),
        mediafile.StorageStyle("DATE"),
    )
    mf.date = date
    mf.year = date.year_field()
    mf.month = date.month_field()
    mf.day = date.day_field()

    # beets' own catalog fields are unusable here: the single `catalognum`
    # clobbers on write, and the multi `catalognums` is not typed as a list and
    # never writes. Disable both and let the custom `catalognumbers` (a proper
    # DSV list, like `labels`) own CATALOGNUMBER, so split releases keep every
    # catalog number.
    mf.catalognum = mediafile.MediaField()
    mf.catalognums = mediafile.MediaField()

    # Release type is our own multi-valued item field (`releasetype` ->
    # RELEASETYPE), so it is written per file and can hold "Single" + "Reissue".
    # Disable beets' album-level albumtype/albumtypes so they do not also write
    # RELEASETYPE (and so it does not stay stuck in the DB, unwritten).
    mf.albumtype = mediafile.MediaField()
    mf.albumtypes = mediafile.MediaField()

    # The record label is written only to the MP3 export's TPUB frame (what DJ
    # software reads). The master keeps the label in ORGANIZATION via `labels`,
    # so native `label` gets no Vorbis style and writes nothing to the FLAC.
    mf.label = mediafile.MediaField(mediafile.MP3StorageStyle("TPUB"))


class SchemaPlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()
        self.item_types = {field.name: field.kind.db_type() for field in CUSTOM_FIELDS}
        for field in CUSTOM_FIELDS:
            self.add_media_field(field.name, field.descriptor)
        _install_native_overrides()
        self.register_listener("write", self._on_write)

    def _on_write(self, item, path, tags):
        # Never write an empty custom field (unset text, 0 integers, empty list).
        for field in CUSTOM_FIELDS:
            if not item.get(field.name):
                tags[field.name] = None
        # A non-reissue must not carry an empty ORIGINALDATE (e.g. 0000).
        if not item.get("original_year"):
            for field in _ORIGINAL_DATE_FIELDS:
                tags[field] = None
        # The master FLAC never carries embedded art (only the external
        # cover.jpg); only the MP3 export embeds it. Strip art from any
        # non-export write so a stray embedded picture cannot enter the master.
        if not is_export(path):
            tags["images"] = None
