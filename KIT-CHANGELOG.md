# Changelog

All notable changes to the **Spec-Driven Development Kit** are documented in
this file. This tracks the *kit itself* (the contents of `docs/KIT-MANIFEST.md`'s
kit-owned paths) — not your project's own history, which lives in your normal
commit log.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the kit uses [Semantic Versioning](https://semver.org/): the version lives
in the root `KIT_VERSION` file.

> **Downstream adopters:** don't hand-edit this file. `scripts/update-kit.sh`
> (`.ps1` twin) appends to it automatically when you pull in a newer kit
> version — see `docs/KIT-MANIFEST.md` for what "kit-owned" means and how
> updates flow.

## [Unreleased]

No changes yet.

## [0.1.0] - 2026-07-04

Baseline release — the first version tracked by this file.

### Added
- Nine single-purpose agents (`specifier`, `planner`, `task-decomposer`,
  `artifact-analyzer`, `test-writer`, `implementor`, `debugger`,
  `code-reviewer`, `docs-writer`) canonically defined under `.agents/agents/`
  and mirrored to Claude Code, GitHub Copilot, and Codex formats.
- Seven workflow skills (`develop-feature`, `init-project`, `check-spec`,
  `clarify-spec`, `amend-constitution`, `create-adr`, `sync-agents-md`)
  canonically defined under `.agents/skills/` and mirrored byte-for-byte.
- The gated SDLC pipeline (Route → Specify → Plan → Tasks → Analyze → Tests →
  Implement → Review) with four right-sized workflow tracks.
- `.agents/kit-manifest.conf` — the machine-readable, single source of truth
  for the kit-owned path list. `update-kit.sh` / `.ps1` read it from the
  source checkout at run time rather than each hand-maintaining its own
  file lists, and a CI step ("Kit manifest doc matches kit-manifest.conf")
  fails the build if `docs/KIT-MANIFEST.md`'s prose table ever omits a path
  listed in the conf file.
- Generated behavioral guardrails: canonical `.agents/agents/*.md` and
  `.agents/skills/*/SKILL.md` files carry an empty
  `<!-- GUARDRAILS:<variant> -->` marker, expanded from `docs/guardrails.md`
  at generation time by `mirror-agents.sh` / `mirror-skills.sh` (and `.ps1`
  twins) — a stale wording simply fails to regenerate identically, so the
  existing mirror-drift guard covers guardrails drift too.
- `scripts/mirror-agents.sh` / `.ps1` and `scripts/mirror-skills.sh` / `.ps1` —
  generate the per-tool copies from the canonical `.agents/` sources.
- `scripts/quiet.sh` / `.ps1` — condenses verbose lint/test output to
  pass/fail + first error, so hook and CI output stays token-cheap.
- `scripts/update-kit.sh` / `.ps1` — stages and validates every kit-owned-file
  write before anything touches disk; real semver comparison (refuses to
  point at an older kit checkout unless `--force` is passed).
- Templates for spec, plan, tasks, checklist, data model, research, decision
  log, learnings, constitution, and `AGENTS.md` itself.
- Reference docs: harness engineering, context engineering, adaptive workflow
  and extensions, token efficiency, model selection, efficient code
  generation, MCP guidance, hooks guidance, guardrails, implementation
  handoff, and a domain glossary.
- ADR-0001 through ADR-0007 recording the kit's own architectural decisions.
- An opt-in extension mechanism (`.agents/extensions/`), starting with a
  `security/baseline` rule pack.
- `.github/workflows/agent-harness.yml` in CI, which validates `.sh` and
  `.ps1` script syntax (`bash -n` and the PowerShell parser) alongside its
  other checks.

### Notes
- `.githooks/pre-commit` (+ `.ps1` twin) and `.github/workflows/agent-harness.yml`
  are **not** kit-owned — they're this repo's own reference sensors (see
  `docs/hooks.md`), not something `update-kit.sh` copies into an adopting
  project. A CI workflow isn't opt-in the way a git hook is: GitHub
  auto-runs anything under `.github/workflows/` the moment it's committed,
  which would surprise adopters who already have their own CI. Copy either
  file in by hand if you want it — from that point on it's an ordinary
  project-owned file.
- This is the first version to carry a `KIT_VERSION` file and this changelog.
  Repos cloned before 0.1.0 have no recorded history here; treat 0.1.0 as
  their starting point going forward.

[Unreleased]: https://github.com/saptarshibasu/spec-driven-development/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/saptarshibasu/spec-driven-development/releases/tag/v0.1.0
