# Phase 3 — Tasks

Only after the user has approved Phase 2. Delegates the drafting to the
`task-decomposer` agent — mid-tier model is fine here (Model Routing):
decomposition from an already-good plan is mechanical, and errors are visible
and local rather than propagating.

1. Invoke the `task-decomposer` agent. Pass it: the paths to the approved
   `spec.md` and `plan.md`, and the pack ID(s) and rule-file path(s) of any
   opted-in extensions — not the rule text; `task-decomposer` has its own
   `Read` tool and loads the rules itself. It generates
   `tasks.md` grouped as Setup, Foundational (marked a hard blocker), one
   phase per user story in priority order (P1 first, tests-first within each
   story when requested, `[P]` for parallelizable tasks, `[US#]` labels,
   exact file paths, a Checkpoint per story), then Polish; represents any
   opted-in extension's verification work as explicit tasks; strips
   instructional comments; and writes `tasks.md` with Status still `Draft`.
2. The agent returns a short summary — not the document text — a task/story
   count and shape (e.g. "18 tasks across 3 user stories, 4 marked `[P]`")
   plus any extension-compliance notes. Relay it.
3. **Stop.** Tell the human the file path (`specs/<NNN>/tasks.md`) and the
   summary from step 2 (see `SKILL.md`'s "don't reprint drafted documents"
   guardrail). Get explicit approval, and resolution of any
   `[NEEDS CLARIFICATION]` markers left in `tasks.md`, before this gate
   clears — resolution means the marker is answered and removed from
   `tasks.md` itself, not just noted as an accepted exemption in
   `decision-log.md`. Don't proceed on your own judgment. On approval, set
   `tasks.md`'s **Status** to `Approved — <who>, <date>` and append a
   **Tasks** row to `decision-log.md`. Don't tell the user to start
   implementing yet — on Tracks C/D the analyzer gate (Phase 3.5) runs first.
4. On requested changes, re-invoke `task-decomposer` with the specific
   feedback rather than hand-editing `tasks.md` yourself, for the same reason
   as Phase 1.
