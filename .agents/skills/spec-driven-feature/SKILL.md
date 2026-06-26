---
name: spec-driven-feature
description: Use when starting spec-driven development on a new feature — triggers on phrases like "create a spec for X", "let's spec out Y", "start a new feature: Z", "use SDD for this", or "write a spec before we code". First right-sizes the work by proposing a workflow track (direct fix / patch / feature / architecture) for human approval, then scaffolds specs/<NNN-feature-slug>/ from this project's templates/ folder and walks Specify -> Plan -> Tasks at the chosen depth, asking for explicit approval before each phase. Handles trivial changes too — they route to the lightweight track rather than being turned away.
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

Confirm `templates/spec.template.md`, `templates/plan.template.md`,
`templates/tasks.template.md`, and `templates/decision-log.template.md` exist at
the project root. If they don't, **stop** and tell the user to copy this
knowledge base's `templates/` folder into the project first. This skill does not
bundle its own copies of these templates — there is exactly one source of truth
for what these documents look like, and it lives at the project root, not inside
this skill.

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

`SCRATCH.md` is *not* the audit trail. The durable, committed record of what was
decided and approved is `decision-log.md` (see Step R and the per-phase steps).
The breadcrumb is throwaway resume state; the decision log outlives the feature.

## Step R — Route the work (right-size before you scaffold)

Not every change deserves the full three-phase pipeline, and forcing a one-line
fix through a full spec is exactly the kind of ceremony this kit exists to avoid
(see `docs/adaptive-workflow-and-extensions.md`). Before scaffolding, **propose a
track**, then let the human approve or override it. *You recommend the track; the
human decides it* — never pick the depth silently.

Assess the request (reading the relevant code read-only if needed) and propose
exactly one track, with a one-line rationale and the precise list of artifacts
you will produce:

- **Track A — Direct change.** Trivial, localized, no design choices: a typo,
  copy/comment edit, config value, dependency bump, obvious one-liner. *No
  feature folder.* Go straight to implement → review. Still test-first if
  behaviour changes. Capture the rationale in the commit message, not a spec.
- **Track B — Patch.** A localized bug fix or small enhancement with no new
  architecture. Scaffold the folder, write a **short `spec.md`** (problem +
  acceptance + out-of-scope) and `tasks.md`; **skip `plan.md`** unless a design
  decision surfaces. Tests-first.
- **Track C — Feature (default).** A normal new capability. Full Specify → Plan →
  Tasks at standard depth. This is the default when you're unsure between B and C.
- **Track D — Architecture / brownfield.** A new service, a cross-cutting change,
  or modifying untested legacy code. Full pipeline at maximum depth: add
  `research.md` and/or `data-model.md` as needed, use the strongest model
  (see `AGENTS.md` Model Routing), write **characterization tests first** for any
  legacy area, and record the cross-cutting decision as an **ADR** under
  `docs/adr/` (the decision log gets a one-line pointer to it).

Then, in the same turn:

1. **Scan for opt-in extensions.** List every `*.opt-in.md` under
   `.agents/extensions/` and present each pack's opt-in question to the human
   (e.g. the Security Baseline question). Do **not** load any pack's full rules
   yet — only the small opt-in prompts. A pack with no `*.opt-in.md` is always
   enforced; note it as such.
2. **Stop for approval of the route.** Present: the proposed track + rationale,
   the exact artifacts you'll create, and the extension opt-in choices you're
   recommending. Wait for the human to confirm or change the track and the
   opt-ins before you scaffold or load any extension rules.
3. After approval, for each opted-in pack, read its `<pack>.md` rules and treat
   them as **blocking constraints** for every subsequent gate and for review.

Record the approved track and the extension opt-in/opt-out choices as the first
entries in `decision-log.md` immediately after scaffolding (Step 0).

For **Track A**, stop here: there is no folder and no further phase — implement
the change directly under the normal behavioral guardrails, then hand to review.
For **Tracks B/C/D**, continue to Step 0.

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
copy the four templates into it as `spec.md`, `plan.md`, `tasks.md`, and
`decision-log.md`.

This step is deterministic on purpose — picking the next feature number and
copying files is exactly the kind of mechanical work that shouldn't depend
on model judgment, and a script gets it right every time where free-form
reasoning occasionally won't (off-by-one on the number, wrong slug, etc.).

**Immediately after scaffolding:**

- Open `decision-log.md` and fill in its first two rows — the **Route** row
  (approved track + rationale) and the **Extensions** row (opted-in packs by ID,
  or "none") — from the decisions just approved in Step R. This file is
  committed; it is the feature's durable audit trail.
- **Track B** does not use `plan.md`: delete the scaffolded `plan.md` and note
  "plan skipped (Track B)" in the decision log, unless a design decision later
  forces a promotion to Track C (record that promotion in the log too).

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
6. If any extension pack was opted in, verify the spec against its rules now
   (e.g. Security Baseline `SEC-01`/`SEC-02` shape what the requirements must
   cover for inputs and access). Any unmet **Verification** condition is a
   blocker — surface it before approval; don't defer a security gap to "later."
7. **Stop. Present the draft spec to the user and ask for explicit
   approval** — or resolution of any `[NEEDS CLARIFICATION]` markers —
   before touching `plan.md`. Do not proceed on your own judgment that the
   spec "looks done." On approval, append a **Specify** row to
   `decision-log.md` (what was settled, any clarifications resolved).

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
5. If any extension pack was opted in, verify the plan against its rules and
   report compliance per rule ID (e.g. "SEC-03: secrets sourced from env, not
   committed — PASS"). An unmet **Verification** condition is a blocker unless a
   human explicitly accepts the risk, recorded in `decision-log.md`.
6. Strip `plan.md`'s instructional comments the same way as Phase 1 step 5
   above, including the opening comment block.
7. **Stop. Present the plan, the gate results, the extension-rule results, and
   any outstanding research findings. Ask for explicit approval** before
   touching `tasks.md`. On approval, append a **Plan** row to `decision-log.md`
   (constitution gate verdicts; any complexity or risk justified).

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
4. If any extension pack was opted in, ensure the relevant verification work is
   represented as explicit tasks (e.g. an authz test for `SEC-02`, an
   input-validation test for `SEC-01`) so compliance is checkable, not assumed.
5. Strip `tasks.md`'s instructional comments the same way as Phase 1 step 5
   above.
6. **Stop here.** Tell the user the documents are ready and implementation can
   begin story by story. Append a **Tasks** row to `decision-log.md`. This skill
   produces the planning artifacts — it does not start writing implementation
   code.

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
- Honour every opted-in extension pack's rules as blocking constraints while
  implementing — they apply to the code, not just the plan.
- If a decision changes during implementation (a deviation from spec or plan, a
  risk accepted), record it in `decision-log.md` so the committed history of
  *why* stays complete — don't leave the reasoning only in chat.
- If approaching a context window limit, write a brief progress summary
  (what's done, what's next, any open decisions) to a scratch file before
  stopping so the session can resume cleanly.

## What this skill deliberately does not do

- It does not write any source code — only `spec.md`, `plan.md`, and
  `tasks.md`. Phase 4 is guidance for whoever runs implementation, not an
  instruction for this skill to start coding.
- It does not skip a gate just because the user seems impatient — say so,
  don't silently comply. "Skip review, just generate all three" is the user's
  call to make knowingly, not yours to make for them.

(No-guessing, no-over-engineering, and the template requirement are covered by
the behavioral guardrails and "Before starting" above; they apply throughout.)
