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
- **MP3 export:** `/srv/music/electronic-mp3` (beets `convert.dest`). 320 kbps
  CBR, 44.1 kHz, ID3v2.3, embedded shrunk cover, a trimmed DJ tag set. Rebuilt
  from the master on demand; syncthing replicates it.

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
wrong: `source`, `macrogenre`, a catalog number when Discogs says none, and (for
records) the physical `record_track`/`record_size`/`record_rpm`.

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
     source="Collection" \
     macrogenre="Hardcore, Jungle, Drum and Bass"
   ```

   Depending on the release also set:
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

7. **Export** the release (or a wider query) to MP3:

   ```sh
   beet convert -y album:"<ALBUM>"
   ```

8. **Clean up** the staging copy (the master is already imported):

   ```sh
   rm -rf "~/import/<ALBUM>"
   ```

## Vocabularies (authoritative lists in the repo)

`beet lint` enforces closed sets; see
`users/tancredi-antigone/beets/default.nix` for the current values.

- `media`: CD, File, Vinyl, Acetate
- `source`: Collection, Bandcamp
- `macrogenre` (single value): "Hardcore, Jungle, Drum and Bass"
- `record_size`: 7, 10, 12 &nbsp;·&nbsp; `record_rpm`: 33, 45, 78
- `releasetype`: exactly one of Album, EP, Single, Compilation, plus optional
  Reissue
- `genres`: canonical spellings with aliases (e.g. "Drum and Bass" absorbs DnB,
  "Drum n Bass"). Currently Drum and Bass, Jungle, Hardcore.

### Growing the vocabulary

New genres, macrogenres, or enum values are expected as the collection grows.
When lint flags a value that should be allowed, do **not** bend the release to
fit; add the value to `users/tancredi-antigone/beets/default.nix` (the
`beetlint.enums`, `releasetype`, or `genres` block) in the nixos-config repo,
redeploy tancredi's antigone home config (from the repo:
`just home-switch-remote antigone tancredi antigone`), then re-lint. Report such
additions back to the user.

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
