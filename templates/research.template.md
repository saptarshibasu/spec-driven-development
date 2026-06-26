<!--
  TEMPLATE — optional, one per feature at specs/<NNN-feature-name>/research.md.
  Created during Plan (Phase 2) to record open questions you had to RESOLVE
  before the plan could be finalised — version-sensitive library facts,
  unknowns about an existing system, trade-offs you investigated. It is the
  scratchpad that keeps that investigation out of plan.md so the plan stays
  clean.

  Delete this file entirely if the plan had no open questions worth recording —
  don't manufacture content. Once filled in, delete this comment block.
-->

# Research: [FEATURE NAME]

**Feature**: `specs/[###-feature-name]/` | **Created**: [DATE]

## Open Questions Resolved

<!-- One entry per question that genuinely blocked planning. State what you
     needed to know, what you found, and the source — so a later reader (or
     agent) doesn't redo the investigation or distrust the answer. -->

### [Question 1 — e.g. "Which version of <library> ships <capability>?"]

- **Why it mattered**: [what in the plan depended on this]
- **Finding**: [the answer, specific and dated if version-sensitive]
- **Source**: [docs link, code reference, experiment, person]
- **Decision**: [what the plan now does as a result]

### [Question 2]

[Same shape.]

## Alternatives Investigated

<!-- Approaches you seriously considered and rejected. Recording these stops
     the team (and agents) from re-proposing them later. A rejected option with
     no stated reason invites a relitigation. -->

| Option | Considered for | Rejected because |
|---|---|---|
| [approach] | [what it would solve] | [concrete reason] |

## Still Open (carried into implementation)

<!-- Questions that did NOT block planning but remain genuinely unresolved.
     If something here would change the design, it belongs back in the spec as
     [NEEDS CLARIFICATION], not buried here. -->

- [e.g., "Exact cache TTL — start at 60s, tune against real traffic."]
