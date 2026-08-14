---
name: manage-music-library
description: >-
  Import, tag, validate, and export releases in Tancredi's beets music library
  on the antigone NAS (a FLAC master library plus a transcoded MP3 export). Use
  whenever asked to add music, retag or fix a release, run the library lint, or
  refresh the MP3 export. Operates on antigone over SSH.
---

# Manage the music library (beets on antigone)

The library lives on the **antigone** NAS and is driven by beets. There are two
collections, both on the storage pool:

- **Master, lossless:** `/srv/music/electronic-flac` (beets `directory`). Clean
  canonical Vorbis tags, one external `cover.jpg` per album, never embedded art.
- **MP3 export:** `/srv/music/electronic-mp3` (the `alternatives.mp3`
  collection). 320 kbps CBR, 44.1 kHz, ID3v2.3, embedded shrunk cover, a
  trimmed DJ tag set. Kept in sync from the master with `beet alt update mp3`;
  syncthing replicates it.

beets runs **on antigone**. From medea, connect with `ssh antigone` and run
every command there (e.g. `ssh antigone 'beet lint'`). The config is deployed by
home-manager at `~/.config/beets/config.yaml`; the schema, plugins, and
vocabularies are defined in the nixos-config repo under
`users/tancredi-antigone/beets/` (edit there, not on the NAS).

## Conventions (what the library enforces)

- **Metadata comes from Discogs only** (no MusicBrainz). Tancredi supplies the
  Discogs release id. Releases not on Discogs go through a manual lane.
- **Every import starts from a clean slate:** all existing tags are wiped before
  importing, so the file carries only the canonical set.
- **Directory layout** (both collections):
  `<label>/<catno> - <albumartist> - <album> [<dates>]/<pos>. <title>`
  where `<dates>` is `[year]` or `[original, edition]` for reissues, and `<pos>`
  is the record position (A1) for grooved discs else the zero-padded track. A
  label-less release uses `Not on Label` and catalog `none`.
- **`beet lint`** is the validation gate: required fields, closed-enum
  vocabularies, releasetype rules, the genre vocabulary, and cross-track
  consistency. A release is not done until lint is clean.

## What the user provides

For each release: where the audio is on antigone, and either a **Discogs
release id** or "not on Discogs". Plus anything Discogs cannot give or gets
wrong: `macrogenre` (always), a catalog number when Discogs says none, the
physical `record_track`/`record_size`/`record_rpm` for records, and optionally
`source` when the provenance is known.

## Key paths and facts

- Connect: `ssh antigone` (user `tancredi`).
- Discogs token overlay (agenix, decrypted at runtime):
  `/run/user/1000/agenix/discogs-personal-access-token-turlando`. It holds the
  real `discogs.user_token`; the checked-in config only has a placeholder, so
  imports must pass this overlay with `-c`. Verify it exists first:
  `ls /run/user/1000/agenix/`. (Equivalent: `$XDG_RUNTIME_DIR/agenix/...`.)
- Force-apply overlay (deployed): `~/.config/beets/by-id.yaml`. Accepts a
  by-id match even though wiping left nothing to score against.
- Common source of new audio: slskd (Soulseek) completed downloads at
  `/srv/downloads/slskd/complete`. This tree is **read-only to tancredi**, so
  copy a release out of it into a writable staging dir before wiping.

## Workflow

Run each step on antigone. Use `beet modify -y` for scripted field edits and
`beet edit` only when interactive review is wanted.

Release-level native fields (`album`, `albumartist`, `year`, `genres`,
`country`, ...) must be modified **album-level**: `beet modify -a -y`. beets
resolves those fields from the Album object when building paths, so an
item-level `beet modify album=...` changes the items' copies but never moves
any file (master or export) — the rename silently does not happen. The custom
per-track fields (`macrogenre`, `labels`, `catalognumbers`, `record_*`, ...)
are item-level and take a plain `beet modify`.

0. **Fit check, before touching anything.** From the release's Discogs
   genres/styles (or a listen), confirm that every genre is in the vocabulary
   and that exactly one configured macrogenre genuinely fits the release. If a
   genre is unknown, or no macrogenre fits (e.g. a bleep techno record when the
   only shelf is the breakbeat continuum), stop and ask Tancredi **now**, per
   "Growing the vocabulary" — not after importing. This early check is the only
   gate for macrogenre: lint verifies membership in the enum, so a
   valid-but-wrong macrogenre (a misfiled release) never trips it.

1. **Stage a writable copy.** The wipe rewrites files in place, so never wipe
   slskd's tree (or any shared/originals dir) directly. Copy the album into a
   staging dir owned by tancredi:

   ```sh
   mkdir -p ~/import
   cp -r "/srv/downloads/slskd/complete/<ALBUM>" ~/import/
   ```

2. **Cover art.** Ensure a `cover.jpg` sits in the staged album folder (fetchart
   pulls from the filesystem; Discogs is not an art source). Keep Bandcamp
   covers as-is; the MP3 export shrinks them to 500 px.

3. **Wipe all metadata** from the staged FLACs (clean slate):

   ```sh
   find "~/import/<ALBUM>" -type f -iname '*.flac' -print0 \
     | xargs -0 -r metaflac --remove-all --dont-use-padding
   ```

4. **Import.**
   - Discogs lane (have a release id), force-applied with the token + overlay:

     ```sh
     beet -c /run/user/1000/agenix/discogs-personal-access-token-turlando \
          -c ~/.config/beets/by-id.yaml \
          import -q --search-id <RELEASE_ID> "~/import/<ALBUM>"
     ```

   - Manual lane (not on Discogs), imported as-is for hand tagging:

     ```sh
     beet import -A "~/import/<ALBUM>"
     ```

   Import copies into the master library and writes tags; the staged copy stays
   behind for cleanup in step 8.

5. **Set what Discogs cannot provide** (and fix what it got wrong). Match the
   release with a query such as `album:"<ALBUM>"`:

   ```sh
   beet modify -y album:"<ALBUM>" \
     macrogenre="<the shelf the step-0 fit check settled on>"
   ```

   Most of the collection bins under `Jungle` (the wide tent: the 93-96
   transition and the modern revival default there), but never write any value
   as a default: set exactly the macrogenre confirmed in step 0.

   Depending on the release also set:
   - `source` (optional) when you know the provenance: `Collection`,
     `Bandcamp`, or `SoundCloud`. Leave it unset when unknown; lint no longer
     requires it, but rejects any value outside the enum.
   - `catalognumbers` if the release has a catalog number Discogs reported as
     none (multi-valued; separate split-release numbers with `; `).
   - Grooved discs (`media` is `Vinyl` or `Acetate`): `record_track` (e.g. `A1`),
     `record_size` (`7`/`10`/`12`), `record_rpm` (`33`/`45`/`78`).
   - Reissues: `original_year`, `original_label`, `original_catalognumber`, and
     add `Reissue` to `releasetype` (alongside the one primary type).
   - `series` and `seriesnumber` when the release belongs to a series.

6. **Lint** and fix until clean:

   ```sh
   beet lint
   ```

   Fix missing/inconsistent fields yourself; but for any `not in` violation
   (a genre or enum value outside the vocabulary), stop and ask — see
   "Growing the vocabulary" below.

7. **Sync the MP3 export**:

   ```sh
   beet alt update mp3
   ```

   This reconciles the whole export incrementally against the master: new
   items are transcoded in, renamed releases are moved (no re-transcode),
   changed tags are rewritten in place, and removed items are deleted. There
   is no per-release query and never a reason to run `beet convert` directly.
   After renaming or removing releases, run it again — that is the cleanup.

8. **Clean up** the staging copy (the master is already imported):

   ```sh
   rm -rf "~/import/<ALBUM>"
   ```

## Vocabularies (authoritative lists in the repo)

`beet lint` enforces closed sets; see
`users/tancredi-antigone/beets/default.nix` for the current values.

- `media`: CD, File, Vinyl, Acetate
- `source`: Collection, Bandcamp, SoundCloud
- `macrogenre` (single value): Breakbeat Hardcore, Happy Hardcore, Darkside,
  Jungle, Drum and Bass, Atmospheric Drum and Bass, Breakcore. These are
  Tancredi's
  subjective scan bins (mood shelves for CDJ browsing), not genre truth
  claims — `genres` records what Discogs says; `macrogenre` records what
  Tancredi says. His ear decides: Jungle is the wide tent (the 93-96
  transition and the modern revival bin there by default), ties go to Jungle,
  Darkside must be earned (file it only on a confident call; any hesitation
  falls to Jungle), and Happy Hardcore is the 4-beat branch (the kick carries
  the groove, breaks decorative; if the break carries it, it belongs in the
  breakbeat lineage bins).
- `record_size`: 7, 10, 12 &nbsp;·&nbsp; `record_rpm`: 33, 45, 78
- `releasetype`: exactly one of Album, EP, Single, Compilation, plus optional
  Reissue.
- `genres`: canonical spellings with aliases (e.g. "Drum and Bass" absorbs DnB,
  "Drum n Bass"). Currently Drum and Bass, Jungle, Hardcore, Breakbeat, Happy
  Hardcore, Breakcore, Breaks, Acid.

### Growing the vocabulary

New genres, macrogenres, or enum values are expected as the collection grows.
When a release carries a value outside the schema (a `not in` lint violation,
or visible in the Discogs data during import), **stop and ask Tancredi what to
do — never resolve it yourself**. In particular, never delete or rewrite a
genre to make lint pass: that silently loses information Discogs provided.
Present the value(s) and the release, and let him choose:

- add it to the vocabulary as a new canonical value,
- map it as an alias of an existing canonical genre, or
- correct the release (only if the value is genuinely wrong for it).

Only after his decision, apply it in `users/tancredi-antigone/beets/default.nix`
(the `beetlint.enums`, `releasetype`, or `genres` block) in the nixos-config
repo, redeploy tancredi's antigone home config (from the repo:
`just home-switch-remote antigone tancredi antigone`), then re-lint.

Note: beets stores Discogs *styles* as the genres; the umbrella Discogs genre
(e.g. "Electronic") is intentionally never stored. Its absence is not a skipped
genre, so do not try to restore it.

## Troubleshooting

- **Token overlay missing** (`ls /run/user/1000/agenix/` is empty or lacks the
  file): tancredi's home generation or its agenix user service has not run in
  this session. Ensure the home config is activated; a fresh `ssh antigone`
  login normally decrypts it.
- **Import says "Skipping"**: confirm both `-c` overlays are passed and the
  release id is correct; the by-id overlay is what force-applies the match.
- **`beet` hangs or prompts about Discogs auth on a non-import command**: it
  should not (the placeholder token avoids OAuth). If it does, the config was
  not deployed; check `~/.config/beets/config.yaml`.
- **The library DB was rebuilt** (`~/.local/state/beets/library.db` recreated,
  e.g. after a re-import from the master): the export's sync state (`alt.mp3`
  per item) lived in the old DB, so `beet alt update mp3` can no longer see
  what it previously produced. Wipe the export contents first
  (`rm -rf /srv/music/electronic-mp3/*`), then run `beet alt update mp3` to
  regenerate the tree from scratch; never run it against the stale tree, which
  would leave unreconcilable orphans.
