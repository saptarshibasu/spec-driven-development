# ADR-0004: Analyze loops to a clean verdict; no accept-without-fix

**Status**: Accepted
**Date**: 2026-07-02
**Deciders**: Repository maintainers

## Context

ADR-0003 added the `artifact-analyzer` gate (Phase 3.5 of `develop-feature`):
a non-destructive, read-only check that cross-references `spec.md`, `plan.md`,
and `tasks.md`, reports findings grouped by severity (Blocker / Should-fix /
Note), and routes each one to the phase that owns the fix. It also gave the
human an escape valve: "a human may knowingly accept a finding instead of
fixing it — record that acceptance in `decision-log.md`."

In practice that escape valve undercut the gate it was attached to. A Blocker
— a coverage gap, a direct contradiction, a constitution violation — could be
waved through with a one-line log entry instead of an actual fix to the
artifact. The gate's whole premise (ADR-0003) is that these gaps are cheapest
to fix before code exists; logging acceptance instead of fixing defers the
same gap to review or later rework, which is exactly what the gate was built
to avoid.

## Decision

Once a human chooses to start the Analyze gate for a feature (respecting the
existing track policy — skip on Track A, optional on Track B, default-on but
declinable on Track C/D), it now loops until `artifact-analyzer` returns a
fully clean verdict: **zero findings at any severity** (Blocker, Should-fix,
*and* Note). Concretely:

1. **The upfront skip still exists, and only there.** Before analyze is first
   invoked for a feature, the human may decline to run it at all (as today),
   and that decision is logged in `decision-log.md` as "skipped — user's
   call." This is unchanged from ADR-0003.
2. **Once analyze has run, there is no mid-loop bailout.** Any finding, of any
   severity, routes back to whichever phase owns the fix (Specify / Plan /
   Tasks — not always Tasks), gets fixed there, and analyze re-runs. This
   repeats until a run comes back with nothing open.
3. **Findings are resolved by editing an artifact, never by logging
   acceptance.** A deliberate scope call ("we're not covering FR-004 this
   iteration") is resolved by writing it into `spec.md`'s Out-of-Scope section
   so `artifact-analyzer` no longer flags it as a gap — not by noting
   acceptance in `decision-log.md` and moving on. The "knowingly accept a
   finding" clause from ADR-0003 is removed.
4. **Each loop iteration is still human-approved**, exactly as every other
   phase in this kit: the owning agent (`specifier` / `planner` /
   `task-decomposer`) proposes the fix, the human approves it, then analyze
   re-runs. What's removed is the ability to skip approval *of the finding
   itself* — not the normal per-phase approval gate.
5. `decision-log.md`'s Analyze row now also records how many loop iterations
   it took to reach a clean verdict (or notes the upfront skip), so the audit
   trail shows the work, not just the final state.

This amends step 3 of ADR-0003's Decision section; everything else there
(non-destructive, track-gated, distinct from `check-spec`/`clarify-spec`/
`code-reviewer`) is unchanged.

## Consequences

- Closes the loophole where a Blocker could be waved through with a log entry
  instead of a fix — the gate now means what it says.
- More loop iterations on features with several Should-fix/Note findings,
  since those can no longer be accepted in bulk. This raises the bar on
  `artifact-analyzer`'s own precision (it must name the exact requirement,
  task, or artifact so the fix is unambiguous) — already required, now load-
  bearing.
- Legitimate scope decisions must land in the artifact itself (e.g. spec's
  Out-of-Scope section), which is arguably the correct place for them anyway
  — it keeps the spec as the single source of truth rather than splitting
  "what we decided" across the spec and a separate decision log.
- Track A/B still don't pay for this: Track A skips entirely, Track B's pass
  is optional up front, and the upfront skip on Track C/D is untouched. The
  mandatory-loop cost only applies once a human has chosen to run the gate.
- A pathological case — a finding that can't actually be resolved without a
  larger redesign — now forces that redesign conversation immediately rather
  than deferring it. This is intentional: it's the cheapest point to have that
  conversation, per ADR-0003's original rationale.

## Alternatives considered

- **Keep the accept-without-fix escape valve** — rejected: this is precisely
  the behavior this ADR removes; it defeated the gate's purpose.
- **Make analyze fully mandatory with no upfront skip** — rejected: Track A/B
  features have little or nothing to cross-check; forcing the gate there
  reintroduces the ceremony-on-trivial-changes problem ADR-0002's adaptive
  tracks and ADR-0003's own track-gating were built to avoid.
- **Cap the loop at N iterations, then auto-escalate to the human** — rejected
  for now: every iteration already goes through a human approval gate (the
  owning phase's normal review), so there's already a natural point for a
  human to notice a stuck loop and intervene, without adding a separate
  iteration-count mechanism. Revisit if this proves not to be true in
  practice.
