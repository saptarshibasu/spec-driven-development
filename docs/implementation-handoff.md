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

## Review gate (after all tasks complete)

When every task in `tasks.md` is done and all story-phase Checkpoints have
passed, invoke the `code-reviewer` agent before considering the feature
complete:

1. Pass the full diff (`git diff main` or equivalent) and the spec path
   (`specs/<NNN>/spec.md`).
2. Also pass the feature's `decision-log.md` so the reviewer knows which
   extension packs were opted in.
3. The reviewer produces a verdict — `approve`, `approve-with-nits`, or
   `request-changes`.
4. If the verdict is `request-changes`, the reviewer handles the Debugger
   handoff (see `code-reviewer` agent). Do not manually patch Blockers —
   let the reviewer orchestrate the fix cycle.
5. On approval, append a **Review** row to `decision-log.md` (verdict +
   reviewer model used).

## See also

- `docs/context-engineering.md` — managing context rot on long implementation
  runs.
- `docs/token-efficiency.md` — compact and checkpoint tactics.
