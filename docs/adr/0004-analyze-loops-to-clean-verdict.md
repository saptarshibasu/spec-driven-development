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
clean verdict on the severities that gate implementation: **zero Blockers and
zero Should-fix findings.** Notes are reported every run but are advisory —
they don't block the verdict and don't drive another loop iteration by
themselves. Concretely:

1. **The upfront skip still exists, and only there.** Before analyze is first
   invoked for a feature, the human may decline to run it at all (as today),
   and that decision is logged in `decision-log.md` as "skipped — user's
   call." This is unchanged from ADR-0003.
2. **Once analyze has run, there is no mid-loop bailout on Blockers or
   Should-fix.** Any Blocker or Should-fix finding routes back to whichever
   phase owns the fix (Specify / Plan / Tasks — not always Tasks), gets fixed
   there, and analyze re-runs. This repeats until a run comes back with zero
   open Blockers and zero open Should-fix findings. **Notes are advisory,
   not gating:** they're listed in the report and the human may act on any of
   them, but a run with only open Notes (no Blocker, no Should-fix) *is* a
   clean verdict — no further loop iteration is required on their account.
3. **Findings are resolved by editing an artifact, never by logging
   acceptance** — this still applies to Blockers and Should-fix findings. A
   deliberate scope call ("we're not covering FR-004 this iteration") is
   resolved by writing it into `spec.md`'s Out-of-Scope section so
   `artifact-analyzer` no longer flags it as a gap — not by noting acceptance
   in `decision-log.md` and moving on. The "knowingly accept a finding" clause
   from ADR-0003 is removed for Blocker/Should-fix. Notes need no such
   clause — they were never gating in the first place.
4. **Each loop iteration is still human-approved**, exactly as every other
   phase in this kit: the owning agent (`specifier` / `planner` /
   `task-decomposer`) proposes the fix, the human approves it, then analyze
   re-runs. What's removed is the ability to skip approval *of a Blocker or
   Should-fix finding* — not the normal per-phase approval gate.
5. `decision-log.md`'s Analyze row now also records how many loop iterations
   it took to reach a clean verdict (or notes the upfront skip), plus how many
   Notes were still open at closure (if any), so the audit trail shows the
   work, not just the final state.

### Why Notes are advisory, not gating

The original version of this ADR gated on zero findings at *every* severity,
including Note ("minor wording, optional tightening"). In practice this
doesn't reliably converge: Blocker and Should-fix findings are objective —
a requirement either has a covering task or it doesn't, a contradiction
either exists or it doesn't — so fixing the named thing makes the finding go
away for good. Notes are explicitly the opposite: they're a subjective,
open-ended category ("optional tightening" of wording), and `artifact-analyzer`
runs on opus with a mandate to actually look for issues rather than
pattern-match a clean bill of health. Told to report Notes on a
freshly-edited artifact, it can plausibly always find a new one — a rewording
of line 40 creates a new candidate for tightening line 41, and so on. Because
each new Note is *new* (not the same finding surviving two runs), the
survives-two-runs stuck-detector never fires on this churn, and every
iteration still costs a full sub-agent invocation plus a human approval gate.
Demoting Notes to advisory removes the one severity that can't reliably
reach zero, without weakening the gate's actual purpose: Blockers and
Should-fix — the findings that represent a real coverage gap, contradiction,
or ambiguity that would otherwise surface later as rework — still loop to a
hard zero before implementation starts.

This amends step 3 of ADR-0003's Decision section; everything else there
(non-destructive, track-gated, distinct from `check-spec`/`clarify-spec`/
`code-reviewer`) is unchanged.

## Consequences

- Closes the loophole where a Blocker could be waved through with a log entry
  instead of a fix — the gate now means what it says, for Blocker and
  Should-fix findings.
- More loop iterations on features with several Should-fix findings, since
  those can no longer be accepted in bulk. This raises the bar on
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
- Notes being advisory means a feature can reach "implementation-ready" with
  open wording nits. That's the intended trade: those nits cost nothing to
  leave in an artifact (no runtime behavior, no test, no user-facing surface
  depends on spec/plan/task prose being perfectly worded), and gating on them
  was the actual source of non-convergence, not a meaningful quality bar.

## Why analyze (pre-code) is stricter than code-reviewer (post-code)

`artifact-analyzer`'s gate (zero Blocker + zero Should-fix, looped) is
stricter than `code-reviewer`'s (only zero Blocker gates; `approve-with-nits`
ships with open Should-fix/Nit findings, per Phase 5 of `develop-feature`).
This asymmetry is deliberate, not an oversight, for two reasons:

1. **Cost of the fix differs by an order of magnitude.** A Should-fix at the
   artifact stage (an ambiguous task, a duplicate task, weak test ordering) is
   a text edit to a markdown file with no code depending on it yet. The same
   class of issue caught post-code (a convention violation, a missed
   performance idiom) requires touching working code, re-running tests, and
   risking a regression the fix itself introduces. ADR-0003's founding
   premise — catch it before code exists because that's the cheapest point —
   is exactly why analyze can afford to hold Should-fix to zero where
   code-reviewer can't: shipping with a known Should-fix post-code trades a
   real regression-risk cost for the fix; shipping with one pre-code doesn't,
   because the fix is nearly free.
2. **Convergence risk differs by category, which is why Note is the one
   severity demoted here and not on the `code-reviewer` side.** Should-fix
   findings at the artifact stage are objective (named ambiguity, named
   duplicate) and terminate once fixed, unlike Note. `code-reviewer`'s own
   Nit category (style, optional) plays the same "advisory, doesn't gate"
   role there that Note now plays here — the two systems already agree that
   the purely-subjective bottom severity shouldn't gate; they differ on
   whether the *middle* severity (Should-fix) should, and that's the cost
   asymmetry in point 1, not a convergence problem.

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
  iteration-count mechanism. This alternative was reconsidered when the
  zero-Note gate proved to be exactly the "not true in practice" case this
  entry flagged for revisit: an opus analyzer told to report Notes on
  freshly-edited artifacts can plausibly emit a new, distinct Note each pass,
  and a churn loop of always-new nits never trips the survives-two-runs
  stuck-detector. Rather than add a separate iteration-count mechanism on top
  (which would also cap legitimate multi-Should-fix loops, not just Note
  churn), the fix demotes Note to advisory (see "Why Notes are advisory,
  not gating," above) — it removes the one severity that doesn't reliably
  converge instead of papering over non-convergence with a counter. No
  iteration cap exists for Blocker/Should-fix; those remain objective enough
  that the per-iteration human approval gate is still the intended backstop
  for a stuck loop.
