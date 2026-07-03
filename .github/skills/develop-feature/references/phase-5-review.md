# Phase 5 — Review & commit (code-reviewer gate)

Once a story is fully green, invoke the `code-reviewer` agent on that story's
diff before moving to the next story's Phase 3.7 (or batch several stories
into one review pass if the human explicitly asks for that — record the
choice in `decision-log.md`; the default is one review per story so diffs
stay small and issues surface early).

1. Invoke `code-reviewer`. Pass it: the diff (or the files `implementor`
   touched), the spec path, and the feature's `decision-log.md` (for opted-in
   extension packs). It runs the full review against spec, constitution,
   conventions, performance idioms, boundaries, and security, and reports
   findings grouped by severity with a verdict.
2. If the verdict has Blockers, **this skill runs the review↔debugger loop**
   — sub-agents can't invoke each other or pause for approval, so the loop
   lives here, not inside `code-reviewer`:
   - Relay the complete findings, then ask the human: *"Invoke the debugger
     on all [N] Blockers above?"* Wait for explicit approval before the
     **first** round only; later rounds in the same loop don't re-ask.
   - Invoke the `debugger` agent once per round, passing every currently-open
     Blocker as a numbered list (file:line, description, suggested fix) and
     this feature's `learnings.md` path; on round 2+, note which Blockers are
     still open and what the debugger already tried, so it doesn't repeat a
     failed fix.
   - Re-invoke `code-reviewer` for a **re-check pass**, passing the prior
     findings, the debugger's report, and the files it touched (see the
     Debugger handoff section of `.agents/agents/code-reviewer.md`).
   - Decide from the re-check verdict: all Blockers resolved → step 3; some
     resolved, some still open → another round; **no forward progress** (the
     same Blocker survives two consecutive rounds, or the debugger calls it a
     spec bug) → stop looping and take that Blocker to the human — accept the
     risk, revise the spec, or redesign (step 4).
   - If any round's debugger report includes a proposed `AGENTS.md`
     correction, relay it and get approval the same way Phase 4 step 2 does —
     apply directly if approved, don't let it block the Blocker loop itself.
3. On a clean verdict (`approve` or `approve-with-nits`): append a **Review**
   row to `decision-log.md`, let the human commit (the `.githooks/pre-commit`
   hook runs its own checks), and move on to the next story's `phase-3.7-tests.md`
   — or, if this was the last story, the feature is done (see `SKILL.md`'s
   closing note on `docs-writer`).
4. On `request-changes` with a Blocker `code-reviewer` escalated to the human
   (not resolved by its internal loop): resolve it together. If the root
   cause turns out to be a spec or plan bug rather than an implementation
   bug, loop back to `specifier` or `planner` instead of forcing another
   `implementor` pass on an already-correct implementation. Once resolved,
   re-run Phase 5 for this story.
