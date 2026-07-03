# Implementation Handoff

Rules for the agent (or session) that executes the tasks produced by the
`develop-feature` skill. The planning skill produces `tasks.md`; this
document governs what happens when someone picks it up and starts building.

On Tracks C/D, `tasks.md` has already cleared the **Analyze** gate (a
non-destructive spec ↔ plan ↔ tasks coverage/consistency check) before reaching
you — so begin from a task list whose blockers were resolved, not a raw draft.

## Execution rules

- Execute tasks in the order defined in `tasks.md`, respecting phase and
  dependency order. Run `[P]`-marked tasks in parallel.
- For any story that includes test tasks: write and run tests first, confirm
  they fail, then implement. Never write implementation code before the tests
  for that story exist and fail.
- After each story-phase Checkpoint, pause and confirm the story is
  independently functional before starting the next.
- **Before any irreversible action** (deleting files or branches, dropping
  database tables, `git push --force`, posting to external services), stop
  and ask the user for confirmation.
- Honour every opted-in extension pack's rules as blocking constraints while
  implementing — they apply to the code, not just the plan.
- If a decision changes during implementation (a deviation from spec or plan,
  a risk accepted), record it in `decision-log.md` so the committed history
  of *why* stays complete — don't leave the reasoning only in chat.
- If approaching a context window limit, write a brief progress summary
  (what's done, what's next, any open decisions) to a scratch file before
  stopping so the session can resume cleanly.

## Review gate (per story by default)

Inside `develop-feature`, review runs once per completed story (its Phase 5),
so diffs stay small and issues surface early — batching several stories into
one pass is the exception, chosen explicitly by the human and recorded in
`decision-log.md`. If you are executing `tasks.md` outside that skill, close
the same gate yourself when a story (or the batch) is green:

1. Pass the diff (`git diff main` or equivalent) and the spec path
   (`specs/<NNN>/spec.md`).
2. Also pass the feature's `decision-log.md` so the reviewer knows which
   extension packs were opted in.
3. The reviewer produces a verdict — `approve`, `approve-with-nits`, or
   `request-changes` — ending with any Blockers as a numbered list.
4. On `request-changes`, **you drive the fix loop — the reviewer cannot**:
   sub-agents don't invoke each other, so `code-reviewer` never runs the
   `debugger` itself. Get the human's approval (first round only), invoke the
   `debugger` agent on all open Blockers as one batch, then re-invoke
   `code-reviewer` for a re-check pass scoped to the files the debugger
   touched. Repeat until clean; if a Blocker survives two consecutive rounds,
   or is really a spec bug, stop and escalate it to the human (the full
   protocol lives in `develop-feature`'s Phase 5 and the `code-reviewer`
   agent's "Debugger handoff" section).
5. On approval, append a **Review** row to `decision-log.md` (verdict +
   reviewer model used).

## See also

- `docs/context-engineering.md` — managing context rot on long implementation
  runs.
- `docs/token-efficiency.md` — compact and checkpoint tactics.
