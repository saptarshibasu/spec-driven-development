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
   hook runs its own checks), then continue to step 5 before moving to the
   next story's `phase-3.7-tests.md` — or, if this was the last story, step 5
   still applies before the feature is called done (see `SKILL.md`'s closing
   note on `docs-writer`).
4. On `request-changes` with a Blocker `code-reviewer` escalated to the human
   (not resolved by its internal loop): resolve it together. If the root
   cause turns out to be a spec or plan bug rather than an implementation
   bug, loop back to `specifier` or `planner` instead of forcing another
   `implementor` pass on an already-correct implementation. Once resolved,
   re-run Phase 5 for this story.
5. **Offer a `learnings.md` compaction pass.** This story's checkpoint —
   Review row just committed — is the natural point to garbage-collect the
   feature's append-only scratchpad before it's carried, unread in full,
   into the next story's fresh `implementor`/`debugger` context. This skill
   (never `implementor`/`debugger` themselves) does the offering:
   - Read the current `learnings.md`. If it's short and every entry is still
     distinct and relevant, say so and skip — compaction isn't mandatory
     every story, only worth doing once there's real duplication or bloat
     (repeated variants of the same gotcha, entries about a command that an
     approved `AGENTS.md` correction already fixed).
   - Otherwise, draft a compacted version: merge duplicate/near-duplicate
     entries into one, and drop any entry whose discovery an **applied**
     `AGENTS.md` correction (Phase 4 step 2 or this phase's step 2) has
     already fixed — that entry's job (surviving until the fix landed) is
     done. Never drop an entry just because it's old, or one that isn't
     clearly superseded.
   - Show the human the before/after (or a summary of what's merging into
     what and what's being dropped, for a long file) and wait for approval
     before rewriting the file. On approval, rewrite `learnings.md` with the
     compacted entries plus the one marker line the template's Compaction
     rules describe, so a later read knows a pass happened and roughly what
     it removed. On decline, leave the file as-is and move on — this is an
     offer, not a gate the story is blocked on.
   - This step never runs mid-story and never runs unattended — same
     "propose, human approves" model as the `AGENTS.md` self-correction rule,
     applied to this file instead of that one.
