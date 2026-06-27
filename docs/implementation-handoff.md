# Implementation Handoff

Rules for the agent (or session) that executes the tasks produced by the
`spec-driven-feature` skill. The planning skill produces `tasks.md`; this
document governs what happens when someone picks it up and starts building.

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

## See also

- `docs/context-engineering.md` — managing context rot on long implementation
  runs.
- `docs/token-efficiency.md` — compact and checkpoint tactics.
