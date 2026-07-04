# Changelog

All notable changes to the **Spec-Driven Development Kit** are documented in
this file. This tracks the *kit itself* (the contents of `docs/KIT-MANIFEST.md`'s
kit-owned paths) — not your project's own history, which lives in your normal
commit log.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the kit uses [Semantic Versioning](https://semver.org/): the version lives
in the root `VERSION` file.

> **Downstream adopters:** don't hand-edit this file. `scripts/update-kit.sh`
> (`.ps1` twin) appends to it automatically when you pull in a newer kit
> version — see `docs/KIT-MANIFEST.md` for what "kit-owned" means and how
> updates flow.

## [Unreleased]

No unreleased changes.

## [0.1.0] - 2026-07-04

Baseline release — the first version tracked by this file. Establishes:

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
- `.githooks/pre-commit` (+ `.ps1` twin) — deterministic pre-commit sensors:
  secret scanning, unresolved-clarification-marker check, thin-pointer check.
- `.github/workflows/agent-harness.yml` — CI backstop mirroring the local
  hooks, plus a drift guard for the generated tool mirrors.
- `scripts/mirror-agents.sh` / `.ps1` and `scripts/mirror-skills.sh` / `.ps1` —
  generate the per-tool copies from the canonical `.agents/` sources.
- `scripts/quiet.sh` / `.ps1` — condenses verbose lint/test output to
  pass/fail + first error, so hook and CI output stays token-cheap.
- Templates for spec, plan, tasks, checklist, data model, research, decision
  log, learnings, constitution, and `AGENTS.md` itself.
- Reference docs: harness engineering, context engineering, adaptive workflow
  and extensions, token efficiency, model selection, efficient code
  generation, MCP guidance, hooks guidance, guardrails, implementation
  handoff, and a domain glossary.
- ADR-0001 through ADR-0006 recording the kit's own architectural decisions.
- An opt-in extension mechanism (`.agents/extensions/`), starting with a
  `security/baseline` rule pack.

### Notes
- This is the first version to carry a `VERSION` file and this changelog.
  Repos cloned before 0.1.0 have no recorded history here; treat 0.1.0 as
  their starting point going forward.

[Unreleased]: https://github.com/saptarshibasu/spec-driven-development/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/saptarshibasu/spec-driven-development/releases/tag/v0.1.0
