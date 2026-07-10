"""Shared helpers for the config's custom plugins (schema, paths, export).

Not a beets plugin itself; imported by the others as `beetsplug._shared`.
"""

import os
from dataclasses import dataclass

import beets

# Sentinel value for a missing mandatory field.
MISSING = "none"
# How a missing record label renders in the path.
NOT_ON_LABEL = "Not on Label"


@dataclass(frozen=True)
class ExportProfile:
    """A transcoded export collection living in its own directory."""

    name: str
    root: str  # absolute directory holding this export


def _export_roots():
    """Absolute export roots by profile name, derived from the `convert` config.

    Currently the single MP3 export (`convert.dest`). `dest` may be absolute
    (the NAS library) or relative to the config directory (the lab), so it is
    resolved against config_dir either way. Add more profiles here when a second
    export format (e.g. Opus via `alternatives`) is introduced.
    """
    convert = beets.config["convert"]
    if not convert.exists() or not convert["dest"].exists():
        return {}
    dest = str(convert["dest"].get())
    base = beets.config.config_dir()
    root = os.path.abspath(os.path.join(base, os.path.expanduser(dest)))
    name = str(convert["format"].get()) if convert["format"].exists() else "mp3"
    return {name: root}


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
