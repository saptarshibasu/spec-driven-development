<!--
  TEMPLATE — one per feature, at specs/<NNN-feature-name>/decision-log.md.

  This is the feature's DURABLE, COMMITTED audit trail — distinct from SCRATCH.md
  (which is an ephemeral, gitignored resume breadcrumb you delete when done). The
  decision log is the opposite: it is committed and it outlives the feature, so a
  future agent or human can see WHAT was decided, WHO approved it, and WHY —
  without replaying chat history that no longer exists.

  Append one row per decision as the feature moves through the workflow. Never
  rewrite history: if a later decision reverses an earlier one, add a new row
  that references the one it supersedes. Keep each entry to a line or two —
  rationale, not prose.

  Cross-cutting decisions (a new pattern other features will follow) belong in a
  full ADR under docs/adr/, not here; in that case log a one-line pointer to the
  ADR number. This file is for decisions local to THIS feature.

  Delete this comment block once the first real entry is in.
-->

# Decision Log: [FEATURE NAME]

**Feature**: `[###-feature-name]` | **Created**: [DATE]

This log records the human-approved decisions for this feature: the chosen
workflow track, any opted-in rule extensions, each phase-gate approval, and any
deviation from the spec or plan made during implementation.

| Date | Stage | Decision | Rationale | Approved by |
|---|---|---|---|---|
| [DATE] | Route | Track [A/B/C/D] — [name] | [why this track fits the change's scope/risk] | [human] |
| [DATE] | Extensions | Opted in: [pack-ids or "none"] | [why these packs apply / don't] | [human] |
| [DATE] | Specify | spec.md approved | [one line: what was settled, e.g. clarifications resolved] | [human] |
| [DATE] | Plan | plan.md approved | [constitution gate results; any complexity justified] | [human] |
| [DATE] | Tasks | tasks.md approved | [one line] | [human] |
| [DATE] | Analyze | [implementation-ready / N blockers resolved / skipped — user's call] | [cross-artifact check: coverage + consistency; any finding knowingly accepted, or why skipped] | [human] |

## Notes

<!-- Optional free-text for anything that doesn't fit a row: a rejected
     alternative worth remembering, a risk accepted knowingly, a link to an ADR
     this feature triggered. Delete if unused. -->

- [Any deviation from spec/plan made during implementation, with the reason and
  who signed off — so the gap between "what we planned" and "what we shipped" is
  never silent.]
