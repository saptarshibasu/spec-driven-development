# Tests

Test layout for spec-driven development. Each subdirectory has a distinct
role; keeping them separate keeps the *intent* of every test visible to both
humans and agents.

| Directory | What goes here | When it is written |
|---|---|---|
| `contract/` | Tests that pin down an API/event contract a caller depends on. | **Before** implementation, generated from `tasks.md`. Required for anything crossing a service or repo boundary (constitution, Article IV). |
| `integration/` | End-to-end / cross-component tests exercising a real user journey, against real services or databases where practical. | With the user story, tests first. |
| `unit/` | Fast, isolated tests for a single module's logic. | With the implementation, tests first (Red → Green → Refactor). |
| `characterization/` | Tests that capture the **current** behaviour of brownfield/legacy code *before* you change it — kept separate so their special status (they assert "what is," not "what should be") stays obvious. | Before touching any untested legacy area (constitution, Article III). |

## Rules (from the constitution — see `memory/constitution.md`)

- **Test-first is non-negotiable.** No implementation code before a failing
  test exists and has been confirmed to fail for the expected reason.
- **Never delete or weaken a failing test to make the suite green.** Fix the
  implementation, or get explicit approval to change the test.
- **Characterization before change.** In any area without coverage, write a
  characterization test that locks in current behaviour before modifying it.

Replace this file's framework-agnostic guidance with your project's real test
commands and idioms — or point to the relevant section of `AGENTS.md` so
there is a single source of truth.
