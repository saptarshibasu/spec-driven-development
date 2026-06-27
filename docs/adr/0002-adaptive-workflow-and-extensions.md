# ADR-0002: Adaptive workflow tracks, opt-in extensions, and a durable decision log

**Status**: Accepted
**Date**: 2026-06-26
**Deciders**: Repository maintainers

## Context

The kit ran every feature through one fixed pipeline: Specify → Plan → Tasks,
each gated. That is correct for a typical feature but mis-fits the tails. A
trivial one-line fix incurs the full ceremony (wasted tokens, and gate fatigue
that erodes the gates that matter), while a new service or a change to untested
legacy code gets no more depth than a CRUD endpoint when it needs research, a
data model, characterization tests, and an ADR.

AWS Labs' AI-DLC (AI-Driven Development Life Cycle, MIT-0) names this directly:
its "Principle 10 — no hard-wired, opinionated SDLC workflows" argues an
AI-native process should adapt its breadth and depth to the work, with the human
approving the AI's proposed plan. AI-DLC also ships an **opt-in extension**
mechanism (paired rules + opt-in-prompt files, blocking when enabled) and
emphasizes **end-to-end traceability** of every plan and approval. We already
satisfied several AI-DLC tenets independently (single source of truth via
ADR-0001, human-in-the-loop gates, tool-agnostic mirroring), but adaptivity,
modular constraints, and a durable audit trail were genuine gaps.

## Decision

We will adopt three AI-DLC-influenced mechanisms, adapted to this kit's
conventions:

1. **Workflow tracks.** `spec-driven-feature` first proposes one of four named
   tracks — A (direct change, no folder), B (patch: short spec + tasks, no
   plan), C (feature: full pipeline, the default), D (architecture/brownfield:
   full pipeline + research/data-model + ADR + characterization tests) — with a
   rationale and exact artifact list, for explicit human approval before
   scaffolding. Named tracks, not free-form judgment, so the routing is itself
   auditable.
2. **Opt-in extensions.** Blocking rule packs live under `.agents/extensions/`
   as a rules file (`<pack>.md`, rules with stable IDs + Verification sections)
   plus a `<pack>.opt-in.md` prompt. Only the opt-in prompts are scanned at
   feature start; full rules load only when the human opts in. The
   `code-reviewer` agent enforces opted-in rules by ID. We seed one pack,
   `security/baseline` (`SEC-01`…`SEC-07`), as a directional reference.
3. **Durable decision log.** Each feature gets a committed
   `specs/<NNN>/decision-log.md` (from `templates/decision-log.template.md`,
   seeded by `start-feature.{sh,ps1}`) recording the track, extension opt-ins,
   and each gate approval — distinct from live resume state, which is carried by
   each document's **Status** header (`Draft` → `Approved`).

Extensions are read on demand by path (like `docs/`), so they add no new mirror
target and do not enlarge always-loaded context — consistent with ADR-0001 and
the kit's token-budget discipline.

## Consequences

- Small changes stop paying for ceremony they don't need; large changes get
  depth they previously lacked — both under explicit human approval.
- New constraint regimes (security, compliance, a11y) attach per feature without
  bloating `AGENTS.md` or the constitution, which load on every call.
- Every feature carries a committed record of *what was decided and why*,
  surviving past the chat that produced it.
- Cost: more surface to maintain (a new template, a new canonical directory, a
  longer skill) and a routing step the human must actually engage with rather
  than rubber-stamp. The seeded security pack is explicitly directional and must
  be customised before it is trusted — shipping it risks a false sense of cover
  if that caveat is ignored.
- The skill is the canonical source (`.agents/skills/`); its edits propagate via
  `mirror-skills.sh`, and the reviewer change via `mirror-agents.sh`. Editing a
  generated copy still reintroduces drift (ADR-0001 unchanged).

## Alternatives considered

- **Keep one fixed pipeline; tell people to "skip gates" manually** — rejected:
  silent, unauditable, and it makes the trivial-vs-default call every time with
  no record.
- **Put security/compliance rules directly in the constitution or `AGENTS.md`** —
  rejected: they load on every call and apply to every feature, taxing the
  token budget for rules most changes don't need.
- **Use AI-DLC wholesale (its rule files, phases, and `aidlc-docs/` output)** —
  rejected: it duplicates machinery we already have (gated SDD, ADRs, mirroring)
  and is oriented to Amazon Q / Kiro; we took the ideas, not the implementation.
- **Fold the audit trail into resume state** — rejected: resume state is a
  single live flag per document (the **Status** header, `Draft` → `Approved`),
  while the audit trail is an append-only narrative of decisions, rationale, and
  deviations. Different shapes and purposes, so they stay separate files.
