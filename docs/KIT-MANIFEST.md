# KIT-MANIFEST.md

This file is the contract between the kit and the project it's copied into.
It answers one question precisely: **if I run `scripts/update-kit.sh`, what
will it touch, and what is guaranteed to survive untouched?**

Everything under **Kit-owned** is safe to overwrite from a newer kit version —
`update-kit.sh` only ever writes to these paths (or the marked sub-sections
called out below). Everything under **Project-owned** is yours; the kit never
writes to it after the initial copy, and `update-kit.sh` refuses to touch it.

See [`../scripts/update-kit.sh`](../scripts/update-kit.sh) for the mechanism.

**Machine-readable source of truth:** the table below is for humans; the path
list itself lives in [`../.agents/kit-manifest.conf`](../.agents/kit-manifest.conf),
which `update-kit.sh` and `update-kit.ps1` both read at run time (from the
*source* checkout being updated to), so there is nothing left to hand-sync
between the two scripts. CI's "Kit manifest doc matches kit-manifest.conf"
step (`.github/workflows/agent-harness.yml`) fails the build if this table
ever omits a path listed in the conf file — so drift between the prose and
the data is caught mechanically instead of trusted on faith.

## Kit-owned paths

Regenerated or overwritten wholesale by `update-kit.sh`. Hand-editing anything
in this list creates the exact fork-on-day-one problem this manifest exists to
prevent — if you need a local variant, open an extension under
`.agents/extensions/` instead (see `.agents/extensions/README.md`), or accept
that your edit will be silently discarded on the next update.

| Path | What it is |
|---|---|
| `KIT_VERSION` | The installed kit version (semver). Named to avoid colliding with a project's own version file. |
| `KIT-CHANGELOG.md` | The kit's own release history (not your project's). Named to avoid colliding with a project's own `CHANGELOG.md`. |
| `docs/KIT-MANIFEST.md` | This file. |
| `.agents/agents/` | Canonical agent definitions. |
| `.agents/skills/` | Canonical skill definitions. |
| `.agents/kit-manifest.conf` | Machine-readable kit-owned path list — the data both `update-kit.sh`/`.ps1` read and this table is checked against in CI. See the file itself for the format. |
| `.agents/extensions/README.md` and any extension pack the kit ships (e.g. `.agents/extensions/security/baseline/`) | Opt-in rule packs authored upstream. Extension packs *you* author locally are project-owned. |
| `.claude/`, `.github/agents/`, `.github/skills/`, `.codex/` | Generated mirrors of `.agents/`. `update-kit.sh` regenerates these by re-running `mirror-agents.sh` / `mirror-skills.sh` after updating `.agents/` — never hand-edit them. These paths are marked `linguist-generated=true` (collapsed by default in GitHub PR diffs) and `merge=ours` (no line-level merge conflicts) in `.gitattributes` — this requires a one-time per-clone `git config merge.ours.driver true`, and after any merge touching them you must still re-run the regenerate step so the mirrors reflect the merged canonical source. |
| `scripts/mirror-agents.sh` / `scripts/mirror-agents.ps1` | Mirror generator. |
| `scripts/mirror-skills.sh` / `scripts/mirror-skills.ps1` | Mirror generator. |
| `scripts/quiet.sh` / `scripts/quiet.ps1` | Log-condensing helper used by hooks/CI. |
| `scripts/update-kit.sh` / `scripts/update-kit.ps1` | This updater — it updates itself like any other kit-owned file. |
| `templates/` | Spec/plan/tasks/checklist/etc. templates. |
| `docs/README.md`, `docs/guardrails.md` | Upstream reference guides, referenced by name rather than inlined. |
| `.mcp.json.example` | Example MCP config. |
| `.gitattributes` | Line-ending normalization. |
| `LICENSE` | Kit license. |

### Not distributed: the kit's own hook & CI files

`.githooks/pre-commit` / `.ps1` and `.github/workflows/agent-harness.yml`
still live in **this** repo — the kit uses them on itself, as a reference
implementation you can look at directly (both are short and commented inline).
They are **not** in `.agents/kit-manifest.conf`, so `update-kit.sh` never
copies or updates them in a downstream project, and they are not part of
what an adopter gets by default.

They used to be tracked as `partial=` (KIT:BEGIN/KIT:END-scoped) paths, on
the theory that the generic sensors and a project's own stack-specific
lint/test/CI steps could safely share one file. That worked fine for the git
hook — it's inert until someone runs `git config core.hooksPath .githooks` —
but not for the CI workflow: GitHub Actions auto-runs anything under
`.github/workflows/` the moment it's committed, which surprised adopters who
already had their own CI running. Rather than only partially solve that (the
hook was fine as-is), both were dropped from the manifest together, so there
is one rule instead of two.

If you want either one, copy it in by hand from the kit repo and it's yours
from that point on — no markers, no `update-kit.sh` involvement, ordinary
project-owned file like anything else not listed in this manifest.

### Not distributed: the kit's own ADRs

`docs/adr/` (7 ADRs, numbered 0001–0007) records why the kit's own internals
work the way they do — audited and confirmed: nothing in a shipped agent or
skill file requires the ADR text itself to run correctly, only the rule it
justifies, which is always stated inline wherever that rule matters. The
ADRs are kit-maintainer reference, not a downstream dependency, so
`update-kit.sh` no longer copies them into an adopting project (this is a
change from earlier kit versions, which shipped them via an `adr_dir=`
manifest entry — see `KIT-CHANGELOG.md`). They remain in this repo for
anyone who wants the design history behind a specific rule.

An adopting project's own `docs/adr/` starts empty and gets its first entry
the first time `create-adr` runs — numbered from 0001, with no reserved
range and no collision risk with the kit's own numbering, since the two
never coexist in the same repo.

## Project-owned paths

The kit writes these once (via `init-project` or the initial clone) and never
again. `update-kit.sh` will not touch them under any circumstances, even if
the upstream kit's own templates for them have changed — you decide if and
when to re-derive them.

| Path | What it is |
|---|---|
| `AGENTS.md` | Your project's filled-in conventions (generated by `init-project` from `templates/agents.template.md`, then yours to maintain). |
| `memory/constitution.md` | Your project's principles (generated by `init-project`/`amend-constitution`, then yours). |
| `memory/` (anything else you add) | Project-specific memory. |
| `specs/` | Your feature work: specs, plans, tasks, decision logs, contracts. |
| `src/`, `tests/` | Your application code and tests. |
| `docs/adr/` | Your project's own architectural decisions, authored with `create-adr` and numbered from 0001 — the kit's own ADRs are not copied in (see "Not distributed" above). |
| `docs/glossary.md` | Domain vocabulary — starts from the kit's stub but is yours to fill in and own going forward. |
| `.mcp.json` (not the `.example`) | Your actual MCP server config, with real values. |
| `CLAUDE.md`, `.github/copilot-instructions.md` | Thin pointers — content-free by design, but the files themselves are project-owned (a tool might require them to exist). |
| `.githooks/pre-commit` / `.ps1`, `.github/workflows/agent-harness.yml` | Not kit-owned at all (see "Not distributed" above) — if you copy either in from the kit repo, the whole file, including its generic checks, is yours to maintain. |
| `.agents/extensions/` packs you author yourself | Local rule packs not shipped by the kit. |
| `.agents/model-map.conf` | Not shipped as kit-owned data — it's org-specific policy (which models/tools your org has enabled) that `mirror-agents.sh`/`.ps1` read at run time. Falls under the "ambiguous or new paths" rule below by default, but is called out explicitly here because it's easy to assume it's kit-owned like the scripts that read it: it isn't, and `update-kit.sh` will never touch it. |

## Ambiguous or new paths

Anything not listed here — a file the kit didn't ship, or a new top-level
directory you created — is treated as project-owned by default:
`update-kit.sh` only ever writes to paths it explicitly knows about. If a
future kit release adds a new kit-owned path, it will show up in that
release's `KIT-CHANGELOG.md` entry and in this file, both of which
`update-kit.sh` brings in as part of the update — so this manifest is always
current for the version you have installed.

## Keeping this file honest

If you add a new file under a kit-owned directory upstream, or move something
from project-owned to kit-owned (or vice versa), update **both** this
manifest's table **and** `.agents/kit-manifest.conf` in the same commit, and
call it out in `KIT-CHANGELOG.md`. A manifest that drifts from reality is worse
than no manifest — `update-kit.sh` trusts `kit-manifest.conf` literally, and
CI trusts this table to match it: the "Kit manifest doc matches
kit-manifest.conf" step in `.github/workflows/agent-harness.yml` fails the
build if a path listed in the conf file isn't also mentioned here.
