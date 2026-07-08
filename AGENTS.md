# AGENTS.md — Spec-Driven Development Kit

## What this is

This repo *is* the kit: a portable harness (agents, skills, templates, hooks,
CI) that other projects copy in and run `init-project` against. There is no
application code here — `src/` and `tests/` are empty scaffolding kept only so
the kit's own directory shape matches what it tells other projects to create.
Working on this repo means editing the harness itself, so the bar is higher
than usual: a bug here ships to every project that later copies this kit.

## Always-on context

`memory/constitution.md` in this repo is intentionally still the stub — it is
a template output, not a real constitution, because this repo has no
application domain to ratify principles about. The kit's own non-negotiable
rules live below and in `docs/adr/` (why each rule exists, for kit
maintainers — not distributed to downstream projects). Never hand-edit anything under
`.claude/`, `.github/`, or `.codex/` — they're generated mirrors, not source.

## Commands

- Enable the pre-commit sensor (once per clone): `git config core.hooksPath .githooks`
- Regenerate agent mirrors after editing `.agents/agents/`: `bash scripts/mirror-agents.sh`
- Regenerate skill mirrors after editing `.agents/skills/`: `bash scripts/mirror-skills.sh`
- Check generated mirrors match canon (what CI runs): `bash scripts/mirror-agents.sh && bash scripts/mirror-skills.sh && git status --porcelain` (non-empty output = drift) — this also covers guardrail sync, since `docs/guardrails.md` is expanded into each empty `<!-- GUARDRAILS:* --><!-- /GUARDRAILS:* -->` marker at mirror time by these same scripts.
- Condense noisy command output: `scripts/quiet.sh <command>` — e.g. `scripts/quiet.sh bash scripts/mirror-agents.sh`
- Pull upstream kit changes into an existing copy: `scripts/update-kit.sh <path-to-newer-kit-checkout> [--dry-run]`
- Run the full local sensor set before committing: `bash scripts/mirror-agents.sh && bash scripts/mirror-skills.sh && git status --porcelain`
- There is no build step and no test runner for this repo itself — `tests/{unit,contract,characterization}` are placeholders (`.gitkeep` only) that model the layout a downstream project should adopt, not suites that run here.

## Tech Stack

- Bash + PowerShell scripts (`.sh` / `.ps1` twins for every script — cross-platform parity is required, see below).
- Markdown with YAML front-matter as the canonical agent/skill format under `.agents/`.
- GitHub Actions (`.github/workflows/agent-harness.yml`) for CI.
- Mermaid diagrams in `README.md` and `docs/` for the workflow/loop visuals.
- No package manager, no application runtime — this is a documentation-and-scripts harness, not a service.

## Project Structure

- `.agents/agents/` — canonical agent definitions (9), mirrored into `.claude/`, `.github/agents/`, `.codex/`. Edit only here.
- `.agents/skills/` — canonical skill definitions (7), byte-for-byte mirrored. Edit only here.
- `.agents/extensions/` — opt-in rule packs (e.g. `security/baseline`), loaded only when a feature opts in.
- `.agents/model-map.conf` — the org-specific model/tool policy the mirror scripts read from (data, not code).
- `.claude/`, `.github/agents/`, `.github/skills/`, `.codex/` — **generated**. Never hand-edit; `mirror-agents.sh`/`mirror-skills.sh` overwrite them and CI's drift guard fails if they don't match a fresh generation.
- `templates/` — canonical spec/plan/tasks/constitution/decision-log/learnings/agents templates that `init-project` and `develop-feature` fill in for downstream projects.
- `docs/` — deep-reference guides (guardrails) plus `docs/adr/` (7 ADRs, kit-maintainer reference — not distributed to downstream projects).
- `scripts/` — `mirror-agents`, `mirror-skills`, `quiet`, `update-kit` (each with a `.sh`/`.ps1` twin).
- `.githooks/pre-commit(.ps1)` — deterministic pre-commit sensor; has a `KIT:BEGIN`/`KIT:END`-delimited generic section (kit-owned) and a stack-specific section below it (project-owned in a downstream copy — here, that section stays empty since this repo has no stack).
- `memory/`, `specs/`, `src/`, `tests/` — present so this repo's shape matches what it scaffolds elsewhere; contents are the unfilled template stubs, not real project artifacts.

## Code Style

This repo has no application source, so there is no code-style snippet to give. The style rules that matter here are documentation conventions:

- Every canonical `.agents/agents/*.md` and `.agents/skills/*/SKILL.md` file's `## Behavioral guardrails` section carries only an empty `<!-- GUARDRAILS:* --><!-- /GUARDRAILS:* -->` marker, never the wording itself — `scripts/mirror-agents.sh`/`scripts/mirror-skills.sh` expand it from `docs/guardrails.md` into each generated `.claude/.github/.codex` copy at mirror time, and CI's drift guard fails if a generated copy doesn't match a fresh generation. Don't hand-write guardrail wording into a canonical file.
- Any `.sh` script added under `scripts/` or `.githooks/` needs a `.ps1` twin that produces byte-identical output — CI's drift guard and the cross-platform promise both depend on this.
- Files with `KIT:BEGIN`/`KIT:END` markers (`.githooks/pre-commit`, `.github/workflows/agent-harness.yml`) must keep generic, stack-agnostic checks inside the markers and any stack-specific addition outside/below them.

## Git / PR Workflow

- No enforced branch-naming or commit-message pattern beyond normal git hygiene; CI (`agent-harness.yml`) is the real gate.
- Before opening a PR that touches `.agents/agents/` or `.agents/skills/`, run the mirror regeneration commands above and commit the resulting diffs in `.claude/`, `.github/`, `.codex/` — CI fails the drift check otherwise.
- `KIT_VERSION` and the latest `KIT-CHANGELOG.md` entry must move together — CI checks this; bump both in the same PR when releasing.

## Boundaries

**✅ Always** — do this without asking:
- Edit only under `.agents/`, `templates/`, `docs/`, `memory/`, `scripts/`, `.githooks/` (the generic section), and this file — never hand-edit `.claude/`, `.github/agents/`, `.github/skills/`, or `.codex/`.
- Run `mirror-agents.sh` and `mirror-skills.sh` after any edit under `.agents/agents/` or `.agents/skills/`, and commit the regenerated output.
- Keep `CLAUDE.md` and `.github/copilot-instructions.md` as thin pointers to this file — CI fails if either grows past ~2 real lines.
- Add a `.ps1` twin for any new `.sh` script.

**⚠️ Ask first** — high-impact but not categorically forbidden:
- Changing the wording inside a `<!-- GUARDRAILS:* -->` block in `docs/guardrails.md` — every downstream copy needs the mirror scripts re-run in the same change, or CI's drift guard will fail.
- Adding or renumbering an ADR in `docs/adr/` — numbers are load-bearing (ADRs cross-reference each other by number, and amending ADRs like 0004/0006 amend a specific prior one by number).
- Editing anything inside the `KIT:BEGIN`/`KIT:END` markers of `.githooks/pre-commit` or `.github/workflows/agent-harness.yml` — these markers still delimit the kit-owned generic section this repo uses on itself, but `kit-manifest.conf` no longer lists either file as `partial=`, so `update-kit.sh` does not touch them on a downstream update; an adopter who wants updates to this section copies it in by hand.
- Bumping `KIT_VERSION` / adding a `KIT-CHANGELOG.md` entry — this is a release action, not a routine edit.

**🚫 Never** — hard stops, no exceptions:
- Never hand-edit a generated mirror (`.claude/`, `.github/agents/`, `.github/skills/`, `.codex/`) — the next mirror run silently discards it.
- Never fill in `AGENTS.md` or `memory/constitution.md` for a *downstream* project by hand here — that's what `init-project` is for; this repo's own copies of those concepts are this file and the stub, respectively.
- Never remove the `KIT:BEGIN`/`KIT:END` markers or reorder content across them.

## Conventions (rule + reason)

- Reference deep docs by name (`docs/guardrails.md`, etc.) rather than inlining their content into `.agents/agents/*.md` or `.agents/skills/*/SKILL.md` — this repo's whole thesis is tiered context; inlining here would be the kit contradicting its own design.
- Keep `README.md` and this file in sync manually when a structural change lands (new agent, new skill, new script) — there is no automated sync between them, only `docs-writer` in a downstream project checks README/AGENTS.md drift, and that agent doesn't run on the kit repo itself.
- Number new ADRs sequentially and never renumber an existing one — other docs link to ADR numbers directly.

## Domain Language

"Kit-owned" and "project-owned" are the load-bearing distinction in this repo — kit-owned paths are silently overwritten by `scripts/update-kit.sh`, project-owned paths never are. "Canonical" (under `.agents/`) vs. "generated" (`.claude/`, `.github/`, `.codex/`) is the other recurring pair.

## Testing Discipline

This repo has no test suite of its own to run. `tests/{unit,contract,characterization}` hold only `.gitkeep` — they exist to demonstrate the directory shape `init-project` and the templates expect a downstream project to populate, not code under test here. The closest thing to tests in this repo are the CI sensors in `.github/workflows/agent-harness.yml` (mirror drift — which also covers guardrail sync, since guardrails are expanded from `docs/guardrails.md` at mirror time — unresolved-clarification-marker check, thin-pointer check, `KIT_VERSION`/`KIT-CHANGELOG.md` match) — run `bash scripts/mirror-agents.sh && bash scripts/mirror-skills.sh && git status --porcelain` before committing changes to `.agents/`.

## Multi-Repo / Cross-Boundary Notes

None — this repo is self-contained. Downstream copies of the kit are separate repos this repo cannot see; `scripts/update-kit.sh` reads from an explicit local path to a newer kit checkout rather than any implicit link.

## Model Routing

Not applicable to work on this repo itself — `.agents/model-map.conf` defines model routing for *downstream* projects that mirror-generate Copilot/Codex configs from it; editing this repo's own agent definitions doesn't require picking a model tier for the task.
