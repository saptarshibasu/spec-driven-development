# Changelog

All notable changes to the **Spec-Driven Development Kit** are documented in
this file. This tracks the *kit itself* (the kit-owned paths copied in by
`scripts/update-kit.sh`) — not your project's own history, which lives in your
normal commit log.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the kit uses [Semantic Versioning](https://semver.org/): the version lives
in this repo's root `KIT_VERSION` file.

> **Downstream adopters:** this file lives in the kit checkout, not in your
> project — `scripts/update-kit.sh` no longer copies `KIT_VERSION` or this
> file into your project (see [0.2.0] below). Read it here, in the kit
> checkout, whenever you run an update.

## [Unreleased]

### Changed
- **`.gitattributes` removed from the kit-owned manifest — now copy-by-hand,
  like `.githooks/pre-commit` and the CI workflow.** It's a repo-wide policy
  file the adopter owns: their copy may carry LFS rules, linguist overrides,
  or merge drivers, and the kit's `* text=auto eol=lf` is a whole-repo
  choice that isn't the kit's to make — yet the updater overwrote it
  wholesale on every run. The file stays in this repo; adopters should merge
  the two rules that matter into their own `.gitattributes`:
  `*.sh` / `*.bash` / `*.ps1 text eol=lf` (CRLF breaks shebangs on Unix
  shells) and the `linguist-generated` / `merge=ours` attributes on the
  generated mirror dirs (`.claude/**`, `.codex/**`, `.github/agents/**`,
  `.github/skills/**`).
  **Action for adopters:** the updater never deletes files — if an earlier
  kit version overwrote your `.gitattributes`, restore your own rules from
  git history and fold the kit rules above back in by hand.
- **Kit license moved from root `LICENSE` to `.agents/LICENSE` in the
  manifest.** The updater used to copy the kit's Apache-2.0 `LICENSE` to the
  project root, overwriting the adopting project's own LICENSE on every
  update — a root LICENSE declares the *project's* license, which is the
  adopter's choice, not the kit's. The kit's license text still ships
  (Apache-2.0 §4(a) requires a copy alongside redistributed files) but now
  lands at `.agents/LICENSE`, scoped to the kit-owned paths.
  **Action for adopters:** per the manifest's removal policy, the updater
  never deletes files — if an earlier kit version copied its LICENSE to your
  project root, review it and remove or replace it by hand if it doesn't
  match your project's actual license.

## [0.2.0] - 2026-07-09

### Changed
- **`scripts/update-kit.sh` (`.ps1` twin) redesigned: run from the kit
  checkout, copy into a project, no version tracking.** Previously the tool
  ran from inside the *project*, took a path to a kit checkout, and refused
  to run without a `KIT_VERSION` file already seeded in the project
  (`echo "0.0.0" > KIT_VERSION` as a first-time bootstrap step) — it then
  compared semver between the two before copying, with a `--force` flag to
  override a downgrade. All of that is gone: the tool now runs from inside
  the kit checkout and takes `<path-to-project>` as its argument
  (`scripts/update-kit.sh <path-to-project>`), and always copies the
  kit-owned paths as they currently stand in that checkout — no version
  comparison, no downgrade guard, no bootstrap step. A re-run still skips
  any file whose content hasn't changed, so diffs stay small. See
  `docs/adr/0007-kit-versioning-and-update-path.md`'s "2026-07-09 revision"
  section for the full rationale.
- **`KIT_VERSION`, `KIT-CHANGELOG.md`, and `scripts/update-kit.sh` (`.ps1`)
  are no longer copied into downstream projects.** Removed their `file=`
  entries from `.agents/kit-manifest.conf`. The kit isn't "installed" into a
  project as files any more — it stays in whichever checkout you cloned, and
  you come back to that checkout to run `update-kit.sh` again. This repo
  still keeps its own root `KIT_VERSION` / `KIT-CHANGELOG.md` for the kit's
  own release history, same as always.
- **`README.md`'s onboarding steps simplified** to match: "clone the kit,
  run `update-kit.sh` pointed at your project" is now one step instead of
  "clone the kit, seed a `KIT_VERSION` file in your project, then run
  `update-kit.sh` pointed at the kit checkout."
- `docs/adr/` is **no longer distributed** to downstream projects — removed
  `adr_dir=docs/adr` from `.agents/kit-manifest.conf`. Follow-up to the
  removal above: being *cited* from a live file and being *read* during
  feature development turned out not to be the same thing — every
  `(ADR-000N)` citation in a shipped agent/skill file is a footnote next to
  a rule that's already stated in full in the same sentence; nothing ever
  instructs an agent to open the ADR itself except the generic "check
  `docs/adr/` before a cross-cutting change" step, which only needs the
  directory listing, not any specific ADR's content. The 7 ADRs stay in
  this kit repo as maintainer-facing design history (nothing here
  contradicts the note above — they're still worth keeping, just not
  worth shipping to every adopter). Also stripped the now-decorative
  `(ADR-000N)` citations themselves from every shipped/operational file
  that had one — `.agents/skills/develop-feature/references/
  phase-3.5-analyze.md`, `.../step-0-scaffold.md`,
  `.agents/skills/init-project/SKILL.md`,
  `.agents/skills/sync-agents-md/SKILL.md`,
  `.agents/extensions/README.md`, `docs/adaptive-workflow-and-extensions.md`,
  `docs/guardrails.md`, `docs/README.md`,
  `.gitattributes`, `AGENTS.md`, and `.github/workflows/agent-harness.yml` —
  the rule each one justified is left in place, only the file-that's-no-
  longer-there pointer is gone. ADR-to-ADR citations inside `docs/adr/`
  itself are untouched; that's the historical record amending itself and
  stays meaningful regardless of distribution.
- **Testing strategy flipped from integration-first to isolation-first.**
  Most adopting projects don't run tests against real external services or
  databases, and `task-decomposer`/`test-writer` were defaulting to an
  "integration test" per user story regardless of whether the project had
  that infrastructure. Removed the `tests/integration/` category entirely
  (folder deleted; row dropped from `tests/README.md`) and its example task
  line from `templates/tasks.template.md`. Renamed `planner`'s third
  constitution-check gate from **Integration-first** ("will tests use real
  services/databases rather than mocks") to **Isolation** ("do tests run
  against mocks/stubs/fakes at the external boundary rather than real
  services or databases, unless the spec explicitly requires otherwise") —
  same API-contracts-first check, inverted real-vs-mock default. Updated the
  matching mentions in `.agents/skills/develop-feature/references/
  phase-2-plan.md`, `.agents/agents/test-writer.md` (tier guidance + Article
  IV label), `.agents/skills/init-project/SKILL.md` and
  `.agents/skills/amend-constitution/SKILL.md` (Article IV — Testing
  strategy question, and amend-constitution's tooling-choice example),
  `AGENTS.md`, and `templates/agents.template.md` (Always-on context
  principle list + Testing Discipline example). `contract/` and
  `characterization/` categories are unaffected — contract tests are
  clarified as verified against a mocked/stubbed boundary, not a live
  external service.

### Removed
- **The `partial=` manifest namespace and its `KIT:BEGIN`/`KIT:END` merge
  machinery in `update-kit.sh` / `.ps1`.** This existed only for
  `.githooks/pre-commit` and `.github/workflows/agent-harness.yml`, and had
  zero live entries since those two files were pulled from the manifest
  entirely in an earlier change (a CI workflow can't be safely
  partial-copied the way a git hook can). The `KIT:BEGIN`/`KIT:END` markers
  themselves stay in both files — they still separate the kit-authored
  section from the stack-specific one for a human reading the file — only
  the now-dead code that used to read them at update time is gone.
- `docs/harness-engineering.md`, `docs/hooks.md`, `docs/mcp.md`,
  `docs/token-efficiency.md`, and `docs/implementation-handoff.md`. Audit
  found none of the five were referenced from any live, shipped
  `.agents/agents/*.md` or `.agents/skills/**/*.md` file — the canonical
  content that actually drives agent behavior during feature development —
  only from each other's "See also" sections, the docs index, and this
  repo's own non-distributed `.githooks/pre-commit(.ps1)` /
  `agent-harness.yml`. Removed the corresponding entries from
  `.agents/kit-manifest.conf`, `docs/README.md`, and
  every dangling citation across `README.md`, `AGENTS.md`,
  `.agents/extensions/README.md`, `docs/adaptive-workflow-and-extensions.md`,
  `docs/adr/0003-analyze-gate.md`, `docs/context-engineering.md`,
  `docs/efficient-code-generation-and-performance-pitfalls.md`,
  `docs/model-selection-and-token-optimization-in-sdd.md`,
  `templates/agents.template.md`, `.mcp.json.example`, `.gitattributes`,
  `.githooks/pre-commit(.ps1)`, and `.github/workflows/agent-harness.yml`.
  All 7 ADRs (`docs/adr/0001`–`0007`) were reviewed and kept — each is
  cited from live agent/skill files and forms part of an amendment chain
  (0002→0003→0004, 0005→0006), so none qualified as unused.
- `docs/context-engineering.md`, `docs/adaptive-workflow-and-extensions.md`,
  `docs/efficient-code-generation-and-performance-pitfalls.md`, and
  `docs/model-selection-and-token-optimization-in-sdd.md`. Same audit
  standard as the first removal round: every citation to these four was
  decorative — the operational rule it footnoted was already stated in full
  inline (e.g. `specifier`'s strong-model pin, `code-reviewer`'s performance
  check, `develop-feature`'s track-routing step), and for the model-selection
  doc, the routing it described is independently enforced by each agent's
  `model:` front-matter field, not by an agent reading the doc. Removed the
  corresponding `file=` entries from `.agents/kit-manifest.conf`, the table
  row from `docs/README.md`, and every dangling
  citation across `README.md`, `AGENTS.md`, `docs/guardrails.md`,
  `docs/adr/0001-agents-md-single-source-of-truth.md`,
  `.agents/extensions/README.md`, `templates/agents.template.md`,
  `scripts/quiet.sh`, `.agents/agents/{specifier,planner,task-decomposer,
  implementor,docs-writer,code-reviewer}.md`, and
  `.agents/skills/develop-feature/{SKILL.md,references/phase-4-implement.md}`
  (each substantive rule was left in place — only the now-dead pointer was
  removed).

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
  file lists.
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
