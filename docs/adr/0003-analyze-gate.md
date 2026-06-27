# ADR-0003: A non-destructive Analyze gate between Tasks and Implementation

**Status**: Accepted
**Date**: 2026-06-26
**Deciders**: Repository maintainers

## Context

The pipeline gated the *authoring* of each artifact — Specify, Plan, Tasks each
stop for human approval — and it grades the spec on its own (`checklist`) and
reviews the code after the fact (`code-reviewer` agent). But nothing verified
that the three artifacts **agree with each other** before implementation began.
A requirement could exist in `spec.md` and never become a task; `plan.md` could
drift from the spec; `tasks.md` could reference a component the plan never
introduced, duplicate work, or reorder priorities. Each of these is cheapest to
catch *before* any code exists — once implementation starts, the same gap costs a
review cycle or a rewrite.

GitHub's **spec-kit** names this step directly: its `analyze` command is a
read-only, cross-artifact consistency and coverage check that runs after `tasks`
and before `implement` (requirement→task coverage, contradictions, duplicate or
ambiguous tasks, constitution violations). We already had spec-kit's authoring
pipeline and its `clarify`/`checklist` quality steps; the cross-artifact gate was
a genuine gap. (See the prior research: this kit already adopted spec-kit's
constitution + spec→plan→tasks model, and AI-DLC's adaptive tracks + opt-in
extensions in ADR-0002. `analyze` is the remaining spec-kit idea worth taking.)

## Decision

Add an **`analyze`** skill and an **Analyze gate** as Phase 3.5 of
`spec-driven-feature`, between Tasks and the implementation handoff, with three
design constraints:

1. **Non-destructive.** `analyze` *reports and routes*; it never rewrites
   `spec.md`, `plan.md`, or `tasks.md`. A finding is routed to **whichever phase
   owns the fix — Specify, Plan, *or* Tasks** (a missing task is a `tasks.md`
   fix; a spec/plan contradiction is a `spec.md` or `plan.md` fix), and the human
   loops back there and re-runs analyze. It is explicitly **not** a tasks-only
   loop. This keeps the kit's "agent proposes, human approves" gate model and
   keeps findings auditable, exactly as spec-kit's analyze is read-only by
   design.

2. **Track-gated and default-on but skippable — not hard-mandatory.** Its value
   scales with the number of artifacts to reconcile, so it respects the adaptive
   tracks (ADR-0002): **skip on Track A** (nothing to cross-check), **optional
   light spec↔tasks pass on Track B** (no `plan.md`), **default-on on Track C**,
   **default-on and extended on Track D** (also reconcile
   research/data-model/contracts, the ADR, and characterization-test ordering).
   On C/D it runs by default, but the human controls the gate: they may
   **explicitly skip** it, and that skip is recorded in `decision-log.md` (their
   call to make knowingly, like skipping review). This deliberately sits between
   "fully optional like Clarify/Checklist" and "hard-mandatory": the one
   cross-artifact safety check shouldn't be silently forgotten, but the kit's
   human-controls-depth principle still holds — so the trivial tail stays cheap
   and no feature is forced through ceremony it doesn't need.

3. **Distinct from the existing quality steps.** `clarify` resolves questions
   inside the spec; `checklist` grades the spec in isolation; the
   `code-reviewer` agent reviews the diff *after* code exists. `analyze` is the
   only step that checks spec↔plan↔tasks agreement and full requirement→task
   coverage, and it runs one stage earlier than the reviewer, where fixes are
   cheapest.

The gate's outcome is recorded as an **Analyze** row in the feature's committed
`decision-log.md` (verdict + one-line summary; any knowingly-accepted finding
noted there too). No new per-feature artifact/template is introduced — analyze
reports to chat and logs a row — keeping the maintenance surface small.

The skill is canonical in `.agents/skills/analyze/` and mirrored to the tool
dirs via `mirror-skills.sh` (ADR-0001); the `spec-driven-feature` edit propagates
the same way.

## Consequences

- Coverage gaps, spec/plan/tasks contradictions, and constitution drift are
  caught before implementation rather than during review — fewer rework cycles.
- The gate is auditable per feature (the Analyze row) and adapts to scope, so
  small changes don't pay for it.
- Cost: one more skill to maintain and one more gate the human must actually
  engage with on C/D features (another rubber-stamp risk if ignored). Analyze is
  inferential — it can miss a subtle contradiction; it lowers risk, it does not
  eliminate it. Some checks (e.g. "every requirement has a task") could later be
  promoted to a computational control, consistent with "mechanize what you can,
  infer what you must" (`harness-engineering.md`).

## Alternatives considered

- **Make analyze a mandatory phase for every feature** — rejected: contradicts
  the adaptive tracks (ADR-0002); a Track A one-liner has nothing to cross-check.
- **Fold the check into `checklist`** — rejected: `checklist` tests the spec in
  isolation; conflating it with a cross-artifact check muddies a clean,
  single-purpose skill and would force it to run before plan/tasks exist.
- **Rely on the `code-reviewer` agent to catch these** — rejected: that runs on
  the diff after code is written, the most expensive place to discover a missing
  requirement; analyze catches the same class of error one stage earlier.
- **Let analyze auto-fix the artifacts it flags** — rejected: silent rewrites
  break the human-approval gate and the audit trail; reporting + routing keeps
  the human in the loop.
