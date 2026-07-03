---
name: develop-feature
description: "Use when starting spec-driven development on any change, large or trivial — triggers: \"create a spec for X\", \"start a new feature: Z\", \"use SDD for this\", \"write a spec before we code\". Proposes a right-sized workflow track for approval, then orchestrates Specify -> Plan -> Tasks -> Analyze -> (Tests red -> Implement green -> Review) through dedicated agents, gating each phase on human approval."
---

# Spec-Driven Feature

Runs the Specify → Plan → Tasks workflow described in this project's
`AGENTS.md`, populating `specs/<NNN-feature-slug>/{spec.md,plan.md,tasks.md}`
from the canonical templates in `templates/`. This skill is a thin
**orchestrator**: it routes the work, scaffolds the folder, and owns every
approval gate and `decision-log.md` entry, but the actual drafting of each
document is delegated to a dedicated agent — `specifier` (`spec.md`),
`planner` (`plan.md`), `task-decomposer` (`tasks.md`) — each invoked fresh, so
none of them carries the other phases' revision back-and-forth into its own
context, and each can be pinned to the model tier its phase actually needs
(`AGENTS.md` Model Routing; see also
`docs/model-selection-and-token-optimization-in-sdd.md`). Three gated phases —
never skip a gate, and never merge two phases into one turn.

This file is intentionally short: it covers routing and the rules that apply
throughout the whole session. **Each phase's actual protocol lives in its own
file under `references/`, read only when you reach that phase** — see
"Phases" below. A feature commonly spans days across many separate
conversation turns; re-reading the phase file at the point of use, rather
than relying on one big upfront read, is what keeps the protocol from
decaying as the session grows.

## Behavioral guardrails (apply throughout this skill session)

These rules are active from Step R through Phase 5 — routing, drafting,
analysis, and implementation alike.

- **No guessing.** Where input leaves something unspecified, write
  `[NEEDS CLARIFICATION: specific question]` and surface it — never silently
  invent an assumption.
- **Investigate before claiming.** Never make statements about the codebase
  without first reading the relevant files. If a claim requires looking at
  code, look first.
- **Conservative by default.** Recommend before you write; stop and ask before
  anything irreversible (deleting files, force-pushing, dropping tables,
  external service calls).
- **No over-engineering.** Only specify, plan, and build what is directly
  requested — no abstractions, extra projects, or flexibility for hypothetical
  future requirements unless the user explicitly asks.
- **Don't reprint drafted documents in chat.** Every drafting phase (1, 2, 3)
  ends the same way: an agent already wrote the document to disk, so tell the
  human the file path and the agent's summary — retyping the content doubles
  output-token cost for no benefit. If the human asks to see it inline
  ("show me", "print it"), read the file and relay it then; otherwise let them
  review it in the file directly.

## Before starting

Confirm `templates/spec.template.md`, `templates/plan.template.md`,
`templates/tasks.template.md`, `templates/decision-log.template.md`, and
`templates/learnings.template.md` exist at the project root. If not, **stop**
— tell the user to copy `templates/` from this kit first. One source of
truth: the project root, not this skill.

## Resuming an in-progress feature

If `specs/<NNN>-<slug>/` already exists: **resume, don't start** — Step 0
refuses to overwrite by design.

1. Read each document's **Status** header (`spec.md`, `plan.md`, `tasks.md`):
   `Draft` = drafted but not yet approved; `Approved` = that gate is cleared. A
   document still full of placeholders hasn't been started.
2. Resume at the first phase whose document is not `Approved`; honour the
   approval gate before moving on. Any `[NEEDS CLARIFICATION]` markers still in
   the documents are the open questions left to settle. **Read that phase's
   reference file (below) before acting** — don't resume from memory of an
   earlier read.
3. Cross-check `decision-log.md` — it carries one committed row per approved gate.
4. If `learnings.md` has entries, skim it before re-invoking `implementor` or
   `debugger` — it may already record why a prior attempt at this story went
   sideways. If it's grown large or repetitive across many prior stories and
   no compaction pass has run recently, this is also a good moment to offer
   one (see `references/phase-5-review.md`'s compaction step) before it's
   handed, unread in full, into another fresh sub-agent context.

## Approval status (the resume signal)

Each document carries a **Status** field in its header — `Draft` until you
approve that gate, then `Approved — <who>, <YYYY-MM-DD>`. This field *is* the
resume state: it records what has been ratified without a separate breadcrumb
file.

- **At each approval gate**, flip the just-approved document's Status from
  `Draft` to `Approved — <who>, <date>` in the same step that appends the
  `decision-log.md` row.
- **On resume**, the first document still at `Draft` (or all-placeholder) is
  where work picks up — see "Resuming an in-progress feature" above.
- The filled-in body shows what's *drafted*; the Status field shows whether it's
  *approved*; `decision-log.md` is the durable, committed audit trail of those
  approvals. No throwaway scratch file is needed.

## Step R — Route the work (right-size before you scaffold)

Before scaffolding, **propose a track** (see `docs/adaptive-workflow-and-extensions.md`).
*You recommend; human decides.* Never pick silently.

Propose exactly one track with a one-line rationale and the artifacts you'll produce:

- **Track A · Trivial — Direct change.** Trivial, localized, no design choices: a typo,
  copy/comment edit, config value, dependency bump, obvious one-liner. *No
  feature folder, no spec, no tasks.* Make the change; if it touches behaviour,
  write and confirm a failing test first, then make it pass. When done, invoke
  the `code-reviewer` agent on the diff (no spec path — it reviews against
  `AGENTS.md` and `memory/constitution.md` only). Capture the rationale in the
  commit message.
- **Track B · Simple — Patch.** A localized bug fix or small enhancement with no new
  architecture. Scaffold the folder, write a **short `spec.md`** (problem +
  acceptance + **unchanged-behavior / regression guard** + out-of-scope) and
  `tasks.md`; **skip `plan.md`** unless a design decision surfaces. Tests-first —
  for a bug fix, that includes a regression test for each unchanged-behavior
  invariant (write it first, confirm it stays green) plus a test that fails on
  the bug and passes once fixed.
- **Track C · Moderate — Feature (default).** A normal new capability. Full Specify → Plan →
  Tasks at standard depth. This is the default when you're unsure between B and C.
- **Track D · Complex — Architecture / brownfield.** A new service, a cross-cutting change,
  or modifying untested legacy code. Full pipeline at maximum depth: add
  `research.md` and/or `data-model.md` as needed, use the strongest model
  (see `AGENTS.md` Model Routing), offer **characterization tests first** for any
  legacy area (ask-first — the human decides at Phase 3.7, never auto-run),
  and record the cross-cutting decision as an **ADR** under
  `docs/adr/` (the decision log gets a one-line pointer to it).

In the same turn:

1. **Scan for opt-in extensions.** List every `*.opt-in.md` under
   `.agents/extensions/`, present each opt-in question. Don't load full rules
   yet — only the small prompts. No `*.opt-in.md` = always enforced; note it.
2. **Stop for route approval.** Present: track + rationale, artifacts, extension
   opt-in choices. Wait for confirmation before scaffolding.
3. After approval, record only the opted-in **pack IDs and their rule-file
   paths** (e.g. `security/baseline` →
   `.agents/extensions/security/baseline/security-baseline.md`) — never read
   the full pack rules into this skill's own context. This orchestrator routes
   extensions, it does not enforce them: each downstream agent (`specifier`,
   `planner`, `task-decomposer`, `test-writer`, `artifact-analyzer`,
   `code-reviewer`) has its own `Read` tool and is passed the pack path(s), not
   the rule text, so it loads and checks the rules itself, in its own context,
   at its own phase.

Record the approved track and extension choices (pack IDs + paths, not rule
text) as the first entries in `decision-log.md` immediately after
scaffolding — every later phase resolves the full rules from that log entry,
not from anything carried in this session's context.

**Track A**: no folder, no further phases — implement, then invoke `code-reviewer` on the diff.
**Tracks B/C/D**: continue to Step 0.

## Step 0 — Scaffold (mechanical — don't use judgment here)

Before running the scaffold script, check whether a matching feature folder
already exists under `specs/` — don't blind-scaffold a duplicate. **Read
`references/step-0-scaffold.md` now** for the existing-feature check, the
exact scaffold-script invocation (path pitfalls, OS variants, manual fallback),
and the immediately-after-scaffolding checklist (decision-log rows, Track B's
`plan.md` deletion, `learnings.md`).

## Phases (read the reference file at phase entry)

Each row below is a one-line map, not the protocol. **Before starting a
phase, `Read` its reference file in `references/`** — the full step-by-step
detail lives there, not here, so it stays out of context until the moment
it's actually needed (and gets a fresh, undecayed read every time you re-enter
that phase, even late in a multi-day session).

| Phase | Gate | Reference file |
|---|---|---|
| 1 — Specify | `specifier` drafts `spec.md`; human approves | `references/phase-1-specify.md` |
| 2 — Plan | `planner` drafts `plan.md`; human approves | `references/phase-2-plan.md` |
| 3 — Tasks | `task-decomposer` drafts `tasks.md`; human approves | `references/phase-3-tasks.md` |
| 3.5 — Analyze | `artifact-analyzer` cross-checks; loops to clean verdict or logged skip | `references/phase-3.5-analyze.md` |
| 3.7 — Tests (red) | `test-writer` writes failing tests per story | `references/phase-3.7-tests.md` |
| 4 — Implement (green) | `implementor` (+ `debugger` on escalation) | `references/phase-4-implement.md` |
| 5 — Review & commit | `code-reviewer` (+ `debugger` loop on Blockers); human commits; offers a `learnings.md` compaction pass | `references/phase-5-review.md` |

Phases 3.7 → 4 → 5 repeat **per user story**, in `tasks.md`'s priority order,
until the last story clears Phase 5 — see `phase-3.7-tests.md` for how that
loop is sequenced. When the last story clears Phase 5, the feature is
complete. If any doc (`README.md`, `AGENTS.md`, a glossary) now describes
something inaccurately, offer the `docs-writer` agent — it edits docs only,
never application code.
