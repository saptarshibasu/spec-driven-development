---
name: analyze
description: Use after tasks.md is drafted and before implementation begins — triggers on phrases like "analyze the spec/plan/tasks", "check the artifacts line up", "is this ready to implement", "cross-check coverage", or "run the analyze gate". Performs a NON-DESTRUCTIVE, read-only consistency and coverage check ACROSS spec.md + plan.md + tasks.md (and research/data-model/contracts on Track D): every requirement maps to a task, no contradictions between artifacts, no orphan/duplicate/ambiguous tasks, no constitution violations. Reports findings for a human to act on — it never rewrites the artifacts itself. Do not use to grade the spec in isolation (that's checklist), to resolve open questions (that's clarify), or to review written code (that's the code-reviewer agent).
---

# Analyze

The last guide-side gate before implementation. Once `spec.md`, `plan.md`, and
`tasks.md` all exist, this skill cross-checks them against each other and against
the constitution, then reports what doesn't line up. It is the cheapest place to
catch a requirement that never became a task — one stage before any code exists.

This is **distinct** from the other quality steps:

- `clarify` resolves open questions *inside* the spec.
- `checklist` grades the spec *in isolation* ("are the requirements good?").
- `code-reviewer` reviews the *diff* after code is written.
- **`analyze` checks that the artifacts agree with each other and cover every
  requirement** — across spec ↔ plan ↔ tasks, before implementation.

## Non-destructive — this is the whole point

`analyze` **reports**; it does not edit. It never rewrites `spec.md`, `plan.md`,
or `tasks.md`. When it finds a gap, it routes the fix to the human, who loops
back to the owning phase (Specify / Plan / Tasks). This keeps the same
"agent proposes, human approves" gate every other phase uses, and keeps the
findings auditable.

## When it runs (track-gated)

`analyze`'s value scales with how many artifacts there are to reconcile, so it is
**conditional on the workflow track** (see `docs/adaptive-workflow-and-extensions.md`):

| Track | Run analyze? | Why |
|---|---|---|
| **A · Trivial — Direct change** | **Skip** | No artifacts to cross-check. |
| **B · Simple — Patch** | **Optional, quick pass** | No `plan.md`; check spec ↔ tasks coverage only. Light. |
| **C · Moderate — Feature** | **Default-on (skippable)** | Full spec ↔ plan ↔ tasks cross-check. |
| **D · Complex — Architecture / brownfield** | **Default-on, extended (skippable)** | Also reconcile `research.md`, `data-model.md`, `contracts/`, the ADR, and characterization-test tasks. |

On C/D this gate runs **by default**, but the human controls it: they may
**explicitly skip** it, and that skip is recorded in `decision-log.md` (it is
their call to make knowingly, like skipping review). It is not a hard-mandatory
step. If invoked on a Track A change, say so and stop — there is nothing to
analyze.

## Before starting

Confirm `spec.md` and `tasks.md` exist for the feature (and `plan.md` on Tracks
C/D). If `tasks.md` is still placeholders, **stop** — analyze runs on a drafted
task list, not a blank one. This skill reads only; it makes no changes.

## What it checks

Read `spec.md`, `plan.md` (if present), `tasks.md`, and any `research.md` /
`data-model.md` / `contracts/` and the feature ADR on Track D. Then evaluate:

1. **Requirement coverage.** Every Functional and Non-Functional Requirement and
   every Acceptance Scenario in `spec.md` maps to at least one task in
   `tasks.md`. List any requirement with **no** covering task (a coverage gap)
   and any User Story with no task phase.
2. **Cross-artifact consistency.** `plan.md` does not contradict `spec.md`
   (e.g. plan adds scope the spec excludes, or picks an approach the spec rules
   out); `tasks.md` does not contradict `plan.md` (e.g. tasks reference a
   component, file, or technology the plan never introduced).
3. **Orphan / duplicate / ambiguous tasks.** Flag tasks that trace to no
   requirement (gold-plating), two tasks doing the same thing, or tasks too
   vague to verify ("handle errors" with no file or condition).
4. **Test-first integrity.** For any story where tests were requested, the test
   tasks precede their implementation tasks and are marked write-then-fail. On
   Track D, every untested legacy area being changed has a characterization-test
   task **before** the change.
5. **Constitution alignment.** Nothing in plan or tasks violates a standing
   principle in `memory/constitution.md` (e.g. simplicity/anti-abstraction, the
   TDD article). Re-check, don't assume Plan's gate caught everything — tasks can
   reintroduce complexity a clean plan didn't have.
6. **Extension compliance (if any pack was opted in).** Every opted-in rule with
   a Verification condition has a corresponding task or is already satisfied by
   the spec/plan. An unmet condition with no covering task is a Blocker. Report
   by rule ID (e.g. "SEC-02: no authz test task for the new endpoint — Blocker").
7. **Leftover markers.** No unresolved `[NEEDS CLARIFICATION]` survives into an
   approved spec/plan that tasks now depend on.

## How to report

Group findings by severity. Be specific — name the requirement ID, task ID, or
artifact and the exact mismatch. No trivial "everything's fine" noise; report
what a real artifact set could fail.

- **Blocker** — a coverage gap, a direct contradiction, an unmet opted-in
  Verification with no task, or a constitution violation. Implementation should
  not start until resolved.
- **Should-fix** — ambiguous or duplicate tasks, weak test-first ordering,
  gold-plating. Worth fixing now; not strictly blocking.
- **Note** — minor wording, optional tightening.

For each finding, **route it**: which phase owns the fix —
`spec.md` (back to Specify / `clarify`), `plan.md` (back to Plan), or `tasks.md`
(back to Tasks). End with a one-line verdict: **implementation-ready** or
**not ready — N blockers**.

**Example output (abbreviated):**

```markdown
### Blockers
- FR-004 (rate limiting) has no covering task. → tasks.md (add to US2 phase).
- plan.md introduces a Redis cache; spec Out-of-Scope excludes external infra.
  Contradiction. → reconcile in plan.md or spec.md.
- SEC-02: new /admin endpoint, no authz test task. → tasks.md.

### Should-fix
- T014 "handle errors" — no file path, not verifiable. → tasks.md.
- T009 and T017 both create the User model. Duplicate. → tasks.md.

### Notes
- US3 priority is P2 in spec but sequenced before P1 work in tasks. → tasks.md.
```

> Verdict: **not ready — 3 blockers.** Resolve coverage of FR-004 and the
> plan/spec scope conflict, add the SEC-02 task, then re-run analyze.

## After reporting

- Append an **Analyze** row to `specs/<NNN>/decision-log.md`: the date, the
  verdict (ready / N blockers), and a one-line summary. If the human knowingly
  accepts a finding rather than fixing it, record that acceptance in the log —
  the gap between "what analyze flagged" and "what we shipped" is never silent.
- If blockers exist, the human loops back to the owning phase; **re-run analyze**
  after the fix. Only a clean (or knowingly-accepted) verdict clears the gate to
  implementation (`docs/implementation-handoff.md`).

## What this skill deliberately does not do

- **Never edits artifacts.** It reports and routes; the owning phase fixes.
- Doesn't grade the spec alone (that's `checklist`) or resolve open questions
  (that's `clarify`).
- Doesn't review code (that's the `code-reviewer` agent, which runs later on the
  diff).
- Doesn't run on Track A, and runs only a light spec↔tasks pass on Track B.
