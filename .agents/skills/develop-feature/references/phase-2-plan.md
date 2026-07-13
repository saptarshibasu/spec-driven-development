# Phase 2 — Plan

Only after the user has approved Phase 1. Delegates the drafting to the
`planner` agent — also pinned to the strongest available model, since a wrong
architecture decision here is as expensive to reverse as a wrong requirement.

1. Invoke the `planner` agent. Pass it: the path to the now-approved
   `spec.md`, the path to `research.md` **if it exists** (seeded at Step 0
   from the triggering prompt, or from an earlier pass — check for it before
   invoking, don't assume it's absent just because this is a non-Track-D
   feature), and the pack ID(s) and rule-file path(s) of any opted-in
   extensions — not the rule text; `planner` has its own `Read` tool and
   loads the rules itself. It reads `AGENTS.md` and
   `memory/constitution.md` itself, fills `plan.md`'s Technical Context and
   Project Structure, runs the three constitution check gates (Simplicity,
   Anti-abstraction, Isolation) with stated reasoning before each
   verdict — for each gate, name the concrete design choice, don't just
   assert pass/fail — fills Complexity Tracking on any gate fail, runs
   version-sensitive research where the plan depends on a rapidly-changing
   library (recording findings in `research.md`, creating it if needed),
   checks extension compliance by rule ID, strips instructional
   comments, and writes `plan.md` with Status still `Draft`.
2. The agent returns a short summary — not the document text — covering the
   three gate verdicts with their reasoning, any Complexity Tracking entries,
   research findings, and extension-compliance notes. Relay all of it — a
   gate fail or an unmet **Verification** condition is a blocker unless a
   human explicitly accepts the risk, recorded in `decision-log.md`; don't
   summarize it away.
3. **Stop.** Tell the human the file path (`specs/<NNN>/plan.md`) and the
   gate/extension/research summary from step 2 (see `SKILL.md`'s "don't
   reprint drafted documents" guardrail). Ask for explicit approval, and
   resolution of any `[NEEDS CLARIFICATION]` markers left in `plan.md`,
   before touching `tasks.md` — resolution means the marker is answered and
   removed from `plan.md` itself, not just noted as an accepted exemption in
   `decision-log.md`. Don't proceed on your own judgment. On approval, set
   `plan.md`'s **Status** to `Approved — <who>, <date>` and append a **Plan**
   row to `decision-log.md`.
4. On requested changes, re-invoke `planner` with the specific feedback rather
   than hand-editing `plan.md` yourself, for the same reason as Phase 1.
