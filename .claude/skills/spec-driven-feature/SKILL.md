---
name: spec-driven-feature
description: Use when starting spec-driven development on a new feature — triggers on phrases like "create a spec for X", "let's spec out Y", "start a new feature: Z", "use SDD for this", or "write a spec before we code". Scaffolds a new specs/<NNN-feature-slug>/ folder from this project's templates/ folder and walks Specify -> Plan -> Tasks, asking for explicit approval before each phase. Do not use for a trivial one-line fix that doesn't warrant a spec — ask the user first if it's unclear whether this task needs one.
---

# Spec-Driven Feature

Runs the Specify → Plan → Tasks workflow described in this project's
`AGENTS.md`, populating `specs/<NNN-feature-slug>/{spec.md,plan.md,tasks.md}`
from the canonical templates in `templates/`. Three gated phases — never
skip a gate, and never merge two phases into one turn.

## Behavioral guardrails (apply for the entire skill session)

These rules are active from Step 0 through Phase 3 and during any
implementation that follows.

- **No guessing.** Anywhere the user's description leaves something
  unspecified that you'd otherwise have to assume, write
  `[NEEDS CLARIFICATION: specific question]` and surface it before
  proceeding — never silently invent an assumption.
- **No over-engineering.** Only specify, plan, and build what is directly
  requested. Do not add abstractions, extra projects, "nice to have"
  features, or flexibility for hypothetical future requirements unless
  the user explicitly asks for them.
- **Investigate before claiming.** Never make statements about the
  existing codebase without first reading the relevant files. If a claim
  requires looking at code, look at it first.
- **Conservative by default.** During Specify and Plan, provide
  information and recommendations; do not modify source files or take
  irreversible actions. During implementation, act — but stop and ask
  before anything hard to reverse (deleting files, force-pushing,
  dropping tables, posting to external services).

## Before starting

Confirm `templates/spec.template.md`, `templates/plan.template.md`, and
`templates/tasks.template.md` exist at the project root. If they don't,
**stop** and tell the user to copy this knowledge base's `templates/`
folder into the project first. This skill does not bundle its own copies
of these templates — there is exactly one source of truth for what these
documents look like, and it lives at the project root, not inside this
skill.

## Resuming an in-progress feature

If a `specs/<NNN>-<slug>/` directory for this feature already exists, you are
**resuming, not starting** — do not run the scaffold script (Step 0 refuses to
overwrite an existing feature, by design). Instead:

1. Read the existing `spec.md`, `plan.md`, and `tasks.md`. A document still
   full of `[bracketed placeholders]` (or effectively empty) is not yet done;
   a filled-in one is complete.
2. Resume at the first incomplete phase — Specify, Plan, or Tasks — and honour
   the same approval gate at the end of it before moving to the next.
3. If a scratch progress file (e.g. `SCRATCH.md`, gitignored) exists from an
   earlier session, read it first: it records what was done, what's next, and
   any open decisions.

The on-disk documents are the source of truth for progress, so an interrupted
feature loses nothing — it picks up wherever the files left off.

## Progress breadcrumb (keep it current)

So that even an abrupt interruption (closed app, killed session) resumes
cleanly, maintain a lightweight `specs/<NNN>-<slug>/SCRATCH.md` as you go. It is
gitignored — a breadcrumb, not a deliverable, and it points at the real
documents rather than duplicating them.

- **At the end of each phase, immediately before you stop for approval**, write
  or overwrite `SCRATCH.md` with a few lines: the current phase and its status
  (drafted / approved), what the next phase is, and any open decisions or
  `[NEEDS CLARIFICATION]` still outstanding.
- **On resume**, read it first (see "Resuming an in-progress feature" above),
  then trust the on-disk documents where they disagree.
- **When the feature is complete** (`tasks.md` approved), delete `SCRATCH.md` —
  the committed documents are now the full record.

## Step 0 — Scaffold (mechanical — don't use judgment here)

Run the bundled scaffolding script from this skill's own directory, passing
the feature description as a single argument. Two byte-equivalent versions
ship side by side — run the one that matches the current OS:

```bash
# macOS / Linux (bash):
bash scripts/start-feature.sh "<feature description>"
```

```powershell
# Windows (PowerShell):
pwsh scripts/start-feature.ps1 "<feature description>"
# (on Windows PowerShell, equivalently: powershell -File scripts/start-feature.ps1 "<feature description>")
```

Detect the platform and pick accordingly: prefer the `.ps1` on Windows and the
`.sh` on macOS/Linux. If you can't tell, try one and fall back to the other —
they produce identical results.

(Claude Code exposes this skill's own folder as `${CLAUDE_SKILL_DIR}`, so the
full path is `${CLAUDE_SKILL_DIR}/scripts/start-feature.{sh,ps1}`. Other tools
resolve a skill's own directory differently — use whatever path your tool gives
you to this skill's folder.)

If the environment can't execute either script, do the equivalent by
hand: find the highest existing `NNN-` prefix under `specs/`, increment it,
slugify the description into kebab-case, create `specs/<NNN>-<slug>/`, and
copy the three templates into it as `spec.md`, `plan.md`, `tasks.md`.

This step is deterministic on purpose — picking the next feature number and
copying files is exactly the kind of mechanical work that shouldn't depend
on model judgment, and a script gets it right every time where free-form
reasoning occasionally won't (off-by-one on the number, wrong slug, etc.).

## Phase 1 — Specify

1. Open the newly created `spec.md`.
2. Fill in the Problem Statement, User Stories (with priorities P1/P2/...),
   Acceptance Scenarios, Edge Cases, Functional Requirements, Non-Functional
   Requirements, Success Criteria, and Out of Scope — based on the user's
   description and a read-only look at the existing codebase if relevant.
3. Apply the No-guessing guardrail: wherever the description leaves something
   you'd otherwise assume, write `[NEEDS CLARIFICATION: specific question]`.
4. Run through the Spec Completeness Checklist at the bottom of the
   template yourself before presenting the draft.
5. Strip every instructional HTML comment (`<!-- ... -->`) out of the
   document as you go, including the file's opening comment block — they
   guided drafting, they are not part of the spec, and they should never
   reach the user's committed `spec.md`. Do the same for any bracketed
   placeholder you didn't end up using (e.g. an unused User Story 2 slot) —
   delete the whole placeholder section rather than leaving it half-filled.
6. **Stop. Present the draft spec to the user and ask for explicit
   approval** — or resolution of any `[NEEDS CLARIFICATION]` markers —
   before touching `plan.md`. Do not proceed on your own judgment that the
   spec "looks done."

## Phase 2 — Plan

Only after the user has approved Phase 1.

1. Read `AGENTS.md` for this repo's tech stack, conventions, and project
   structure, and the project's constitution (commonly
   `memory/constitution.md`) for standing architectural principles.
2. Fill in `plan.md`'s Technical Context and Project Structure.
3. Run the three constitution check gates explicitly and report the result
   for each — do not silently skip or combine them:

   **Simplicity gate** — Using ≤ 3 projects? No future-proofing or
   speculative components? No layers added for hypothetical reuse?

   **Anti-abstraction gate** — Using framework features directly rather
   than wrapping them? Is there a single model representation per entity
   (no DTO proliferation)?

   **Integration-first gate** — Are API contracts defined before
   implementation begins? Will tests use real services/databases rather
   than mocks where the spec doesn't require otherwise?

   For each gate, **state your reasoning before the verdict** — name the
   concrete design choice that makes it pass or fail, don't just assert
   pass/fail. (E.g. "Anti-abstraction: PASS — entities map to single domain
   models; no DTO layer added." / "Simplicity: FAIL — needs a 4th module
   because X; justified below.")

   If any gate fails, fill in the Complexity Tracking section with a
   concrete justification rather than skipping it. Flag it clearly for the
   user.

4. If the plan depends on a rapidly-changing library or framework, identify
   the specific questions that need current information (e.g. "which version
   of X ships with this capability?") and run those as parallel research
   tasks before finalising the plan — do not guess at version-sensitive
   details.
5. Strip `plan.md`'s instructional comments the same way as Phase 1 step 5
   above, including the opening comment block.
6. **Stop. Present the plan, the gate results, and any outstanding research
   findings. Ask for explicit approval** before touching `tasks.md`.

## Phase 3 — Tasks

Only after the user has approved Phase 2.

1. Read the approved `spec.md` (for user stories and priorities) and
   `plan.md` (for structure and stack).
2. Generate `tasks.md` with this structure:
   - **Setup** — shared infrastructure, no dependencies, starts immediately
   - **Foundational** — prerequisites that block all user stories (schema,
     auth, routing); mark this phase clearly as a hard blocker
   - **One phase per user story** in priority order (P1 first), each
     independently completable and testable without the others
   - **Polish** — cross-cutting concerns, documentation, cleanup
3. Within each user story phase:
   - If tests were requested: list test tasks first, with an explicit note
     that they must be written, run, and confirmed FAILING before any
     implementation task in that story begins
   - Mark tasks that touch different files and have no mutual dependencies
     with `[P]` — these can run in parallel
   - Label every task with its story (`[US1]`, `[US2]`, etc.)
   - Include the exact file path in every task description
   - End the phase with a Checkpoint describing how to verify the story
     works in isolation
4. Strip `tasks.md`'s instructional comments the same way as Phase 1 step 5
   above.
5. **Stop here.** Tell the user the three documents are ready and
   implementation can begin story by story. This skill produces the
   planning artifacts — it does not start writing implementation code.

## Phase 4 — Implementation handoff (guidance only)

This skill does not run implementation itself. When the user is ready to
implement, share these rules so the executing agent (or a subsequent
session) applies them:

- Execute tasks in the order defined in `tasks.md`, respecting phase and
  dependency order. Run `[P]`-marked tasks in parallel.
- For any story that includes test tasks: write and run tests first,
  confirm they fail, then implement. Never write implementation code before
  the tests for that story exist and fail.
- After each story-phase Checkpoint, pause and confirm the story is
  independently functional before starting the next.
- **Before any irreversible action** (deleting files or branches, dropping
  database tables, `git push --force`, posting to external services), stop
  and ask the user for confirmation.
- If approaching a context window limit, write a brief progress summary
  (what's done, what's next, any open decisions) to a scratch file before
  stopping so the session can resume cleanly.

## What this skill deliberately does not do

- It does not write any source code — only `spec.md`,