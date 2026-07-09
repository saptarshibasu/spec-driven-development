# ADR-0007: Kit-owned path manifest and the `update-kit` copy tool

**Status**: Accepted (revised)
**Date**: 2026-07-04
**Revised**: 2026-07-09 — see "2026-07-09 revision" below. This ADR is updated in place rather
than superseded by a new number; the filename and number (`0007`) are unchanged.
**Deciders**: Repository maintainers

## Context

This kit is distributed by copy, not by package manager: a downstream
adopter clones the kit checkout, runs `update-kit.sh` (`.ps1` twin) to copy
the kit-owned files into their project, then runs `init-project` to fill in
`AGENTS.md` and `memory/constitution.md`, and starts building. From that
point on, the copy is theirs — they customize `AGENTS.md`, fill in the
constitution, write specs under `specs/`, and fill in the stack-specific
sections of `.githooks/pre-commit` and `.github/workflows/agent-harness.yml`
(the kit's own repo ships those commented out; see the "UNCOMMENT and match
AGENTS.md" markers in both files).

Nothing in the kit before this decision recorded *which files* the kit
maintainers consider theirs to evolve versus which files belong to the
adopting project:

- There was no explicit list of kit-owned vs. project-owned paths. ADR-0001
  already established that `.claude/`, `.github/agents/`, `.github/skills/`,
  and `.codex/` are generated and must never be hand-edited, but it didn't
  address the much larger question this ADR does: which parts of `.agents/`,
  `templates/`, `docs/`, `scripts/`, and the hook/CI files are the kit's to
  update, and which are the project's to own.
- There was no tooling to pull in a kit improvement after the fact. The only
  path was a manual three-way merge against a fresh clone — tedious enough,
  and risky enough (easy to overwrite a customized `AGENTS.md` or a filled-in
  constitution by accident), that in practice nobody would do it. Every
  downstream copy forks permanently the day it's cloned; kit improvements
  (a hardened hook check, a clarified template, a bug fix in a mirror script)
  never reach existing adopters, only new ones.

This is the same class of problem ADR-0001 solved for *tool* drift (Claude
vs. Copilot vs. Codex instructions going out of sync) applied to *kit*
drift (an adopted copy vs. upstream going out of sync over time). The fix
follows the same shape: make the boundary explicit and mechanize crossing
it.

## Decision

1. **An explicit, path-by-path manifest** of kit-owned vs. project-owned
   paths, in `.agents/kit-manifest.conf`:
   - Kit-owned, whole-file/whole-dir: `.agents/agents/`, `.agents/skills/`,
     `.agents/extensions/` (kit-shipped packs), `templates/`, the `docs/*.md`
     reference guides, `scripts/mirror-*.sh|.ps1`, `scripts/quiet.sh|.ps1`,
     `.mcp.json.example`, `.gitattributes`, `LICENSE`, and
     `.agents/kit-manifest.conf` itself.
   - Generated (kit-derived, never hand-edited, per ADR-0001): `.claude/`,
     `.github/agents/`, `.github/skills/`, `.codex/` — regenerated inside the
     target project by re-running `mirror-agents.sh` / `mirror-skills.sh`,
     not copied directly.
   - Never copied downstream, even though they live in the kit repo: this
     repo's own `KIT_VERSION`, `KIT-CHANGELOG.md`, and `scripts/update-kit.sh`
     (`.ps1`) — see "2026-07-09 revision" below for why.
   - Never copied downstream: `.githooks/pre-commit` (`.ps1`) and
     `.github/workflows/agent-harness.yml` — a CI workflow auto-runs the
     moment it lands in a repo, unlike an opt-in git hook, which surprised
     adopters who already had their own CI. An adopter who wants either
     copies it in by hand and owns it from that point on.
   - Never copied downstream: the kit's own `docs/adr/` — maintainer-facing
     design history, not something a downstream project's feature work
     depends on.
   - Project-owned: `AGENTS.md`, `memory/`, `specs/`, `src/`, `tests/`,
     project-authored ADRs, `docs/glossary.md`, `.mcp.json`, and everything
     outside the manifest.
   - Anything not listed is project-owned by default — the copy tool only
     ever writes to paths it explicitly knows about.
2. **`scripts/update-kit.sh` / `.ps1`**, run from inside a kit checkout,
   takes a path to the target project and:
   - Adds/updates (never deletes) files under the kit-owned whole-file and
     whole-dir paths, comparing content so it only touches what actually
     changed.
   - Adds/updates the kit's own ADRs by filename in `docs/adr/` (currently
     unused — the kit's ADRs aren't distributed, per the manifest), leaving
     any ADR filename the project authored itself untouched.
   - Regenerates `.claude/`, `.github/agents/`, `.github/skills/`, `.codex/`
     inside the target project by re-running that project's own (just
     copied) mirror scripts against its freshly updated `.agents/`, rather
     than copying the kit checkout's generated output directly.
   - Never touches anything the manifest marks project-owned.
   - Supports `--dry-run` (report without writing) and `--yes` (skip the
     confirmation prompt).

## 2026-07-09 revision

The original version of this ADR (2026-07-04) also specified: a `VERSION`
file recording the installed kit version per project, a `CHANGELOG.md`
distributed alongside it, semver comparison with a downgrade guard, and a
`partial=` manifest namespace so `.githooks/pre-commit` and
`agent-harness.yml` could be half kit-owned via `KIT:BEGIN`/`KIT:END`
markers. `update-kit.sh` ran from inside the *project*, pointed at a path to
a kit checkout (`update-kit.sh <path-to-newer-kit-checkout>`).

In practice this added ceremony that a copy-and-diverge tool doesn't need:

- **No downstream adopter was tracking a per-project kit version.** The
  `.githooks/pre-commit` / `agent-harness.yml` partial-ownership question
  was moot the moment those two files were pulled from the manifest
  entirely (a CI workflow can't be safely partial-copied — see the Decision
  section above) — from that point on, the `partial=` namespace had zero
  live entries and the `KIT:BEGIN`/`KIT:END` merge code in `update-kit.sh`
  had nothing left to act on.
- **Semver comparison and a downgrade guard protect against a problem this
  tool doesn't actually have.** `update-kit.sh` never deletes anything and
  always diffs before writing — running it against an older kit checkout by
  mistake just re-copies older content, visible immediately in `git diff`
  before it's ever committed. The downgrade guard was solving for a mistake
  that's already cheap to see and revert.
- **The `VERSION`-seeding step was the most confusing part of first-time
  adoption** (`echo "0.0.0" > KIT_VERSION` before the first run, purely to
  satisfy a check the tool needed for itself) and `KIT_VERSION` /
  `KIT-CHANGELOG.md` living in the project added a file pair the project
  would otherwise never touch or read again.

The revision:

- Drops `VERSION`/`CHANGELOG.md` distribution and the `KIT_VERSION` /
  `KIT-CHANGELOG.md` manifest entries. This repo still keeps its own root
  `KIT_VERSION` and `KIT-CHANGELOG.md` for the kit's *own* release history —
  they're just no longer copied into adopting projects.
- Drops the semver comparison and downgrade guard entirely. `update-kit.sh`
  now always copies the kit-owned paths as they stand in whatever checkout
  you point it at — the same "diff before writing" behavior as before,
  minus the version gate.
- Drops the `partial=` manifest namespace and the `KIT:BEGIN`/`KIT:END`
  merge code in `update-kit.sh`. `.githooks/pre-commit` and
  `agent-harness.yml` keep their `KIT:BEGIN`/`KIT:END` markers (they still
  usefully separate the kit-authored generic section from the
  project-authored stack-specific one for a human reading the file), but
  `update-kit.sh` no longer has any mechanism that reads those markers —
  copying either file remains a manual, one-time, adopter-owned action.
- **Reverses the invocation direction.** `update-kit.sh` now runs from
  inside the kit checkout and takes the target project's path as its
  argument (`scripts/update-kit.sh <path-to-project>`), instead of running
  from inside the project and pointing at a kit checkout. This matches how
  the tool is actually used — someone maintaining or updating a kit
  checkout, choosing which project(s) to push it into — and removes the
  `VERSION`-seeding step from first-time adoption entirely: there's nothing
  to bootstrap in the project before the first run.

## Consequences

- Downstream adopters get kit improvements (a hardened hook check, a
  clarified template, a bug fix in a mirror script) with one command instead
  of a manual three-way merge — closing the "forks permanently on day one"
  problem this ADR exists to fix.
- The manifest is a contract, not just documentation: `update-kit.sh` trusts
  it literally, so a maintainer adding a new kit-owned path must update the
  path list both updater scripts read and call it out in `KIT-CHANGELOG.md`
  in the same change, or the tool silently won't pick it up. This mirrors
  the existing discipline `mirror-agents.sh` already requires for its
  tool/model mapping tables — a known, accepted cost of keeping generation
  mechanical instead of inferred.
- There is no longer any way to answer "which kit version is this project
  on?" from inside the project itself — an adopter who wants to know how far
  behind they are compares their project's tree directly against a fresh
  kit checkout (`git diff --no-index`, or just re-running `update-kit.sh
  --dry-run` and reading what it would change) rather than reading a
  `KIT_VERSION` file. This is an accepted trade for removing the version
  ceremony; projects that value strict version tracking can still record
  which kit commit/tag they last ran `update-kit.sh` against in their own
  commit message or changelog.
- `update-kit.sh` writes files as it goes rather than staging everything
  atomically; a mid-run failure (e.g., a permissions error) can leave a
  partially updated tree. This is accepted because the tool is meant to run
  against a clean git working tree in the target project, where `git
  checkout -- .` or `git diff` trivially recovers.
- This does not change how a *brand-new* adopter gets the kit (still clone
  or copy the kit checkout, then run `update-kit.sh` against their project);
  it's the same mechanized path for both first-time adoption and later
  updates, which is simpler than the two-step "seed a version file, then
  update" flow the original decision required.

## Alternatives considered

- **Ship the kit as an installable package (npm/pip-style) instead of a
  copy-in template** — rejected for now: the kit's value is that its files
  live directly in the adopting project's repo, version-controlled and
  editable in place (`AGENTS.md`, the constitution, specs) — a package
  manager model would fight that by pushing kit content into a
  `node_modules`-style dependency directory instead of the project's own
  history. Revisit if the copy-and-diverge model proves too fragile even
  with `update-kit.sh` in place.
- **Full rsync-with-delete semantics for kit-owned directories** — rejected:
  deleting files the source no longer has is more powerful but also more
  dangerous the moment a project has quietly added its own file inside an
  otherwise kit-owned directory (e.g., its own agent under `.agents/agents/`,
  its own extension pack under `.agents/extensions/`). Add-and-update-only is
  safer by construction; a file the kit genuinely removed is called out in
  `KIT-CHANGELOG.md` for the adopter to delete by hand instead.
- **Keep per-project version tracking, but make it optional** (e.g., only
  compare versions if a `KIT_VERSION` file happens to already exist) —
  rejected as needless complexity: a conditional feature that only some
  projects opt into is harder to reason about than either always having it
  or never having it, and nothing in practice was using it.
- **Track kit version via a git tag / commit SHA comparison instead of a
  distributed `VERSION` file** — moot after the 2026-07-09 revision, since
  there's no per-project version tracking at all any more. Recorded here for
  history: this was considered and rejected in the original decision because
  an adopted copy is frequently de-linked from the kit's own git history
  (squashed into the project's initial commit, or copied without `.git` at
  all), so a file that travels with the tree was judged more reliable than
  history that may not.
