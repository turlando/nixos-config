"""Shared helpers for the config's custom plugins (schema, paths, export,
populate, beetlint).

Not a beets plugin itself; imported by the others as `beetsplug._shared`.
"""

import os
import unicodedata
from dataclasses import dataclass

import beets

# Sentinel value for a missing mandatory field.
MISSING = "none"
# How a missing record label renders in the path.
NOT_ON_LABEL = "Not on Label"


def nfc(value):
    """NFC-normalize a tag value (a string, or a list of strings); any other
    type passes through unchanged.

    NFC is the library's canonical Unicode form for tags and, since file names
    derive from tag values, for paths: it is what Linux input methods, the web,
    syncthing, and rekordbox all expect. The ZFS `normalization` property only
    affects name comparison, so the stored form is whatever we write."""
    if isinstance(value, str):
        return unicodedata.normalize("NFC", value)
    if isinstance(value, list):
        return [nfc(v) for v in value]
    return value


@dataclass(frozen=True)
class ExportProfile:
    """A transcoded export collection living in its own directory."""

    name: str
    root: str  # absolute directory holding this export


def _export_roots():
    """Absolute export roots by collection name, from the `alternatives` config.

    Each alternatives collection (e.g. the mp3 DJ export) declares the directory
    it maintains; a second profile (e.g. Opus for the phone) becomes a new
    collection and is picked up here automatically. Directories may be absolute
    (the NAS datasets) or relative to the config directory (the lab), so both
    resolve against config_dir.
    """
    alternatives = beets.config["alternatives"]
    if not alternatives.exists():
        return {}
    base = beets.config.config_dir()
    roots = {}
    for name in alternatives.keys():
        directory = alternatives[name]["directory"]
        if directory.exists():
            path = os.path.expanduser(str(directory.get()))
            roots[str(name)] = os.path.abspath(os.path.join(base, path))
    return roots


def export_profile(path):
    """The ExportProfile whose directory contains `path`, or None for the master
    library. Location-based, so it stays correct for any export format instead of
    being tied to a file extension."""
    name = path.decode("utf-8", "replace") if isinstance(path, bytes) else path
    target = os.path.abspath(name)
    for profile_name, root in _export_roots().items():
        try:
            if os.path.commonpath([root, target]) == root:
                return ExportProfile(profile_name, root)
        except ValueError:
            pass
    return None


def is_export(path):
    """True when `path` is an export copy (any profile), false for the master."""
    return export_profile(path) is not None
