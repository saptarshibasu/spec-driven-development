---
name: spec-driven-feature
description: >-
  Use when starting spec-driven development on a new feature — triggers on
  phrases like "create a spec for X", "let's spec out Y", "start a new
  feature: Z", "use SDD for this", or "write a spec before we code". First
  right-sizes the work by proposing a workflow track (direct fix / patch /
  feature / architecture) for human approval, then scaffolds
  specs/<NNN-feature-slug>/ from this project's templates/ folder and walks
  Specify -> Plan -> Tasks -> Analyze -> Tests (red) at the chosen depth, asking
  for explicit approval before each phase. The Analyzer gate (Tracks C/D)
  cross-checks the artifacts for coverage and consistency; the test-writer gate
  then writes and confirms failing tests before implementation begins. Handles
  trivial changes too — they route to the lightweight track rather than being
  turned away.
---

# Spec-Driven Feature

Runs the Specify → Plan → Tasks workflow described in this project's
`AGENTS.md`, populating `specs/<NNN-feature-slug>/{spec.md,plan.md,tasks.md}`
from the canonical templates in `templates/`. Three gated phases — never
skip a gate, and never merge two phases into one turn.

## Behavioral guardrails (apply throughout this skill session)

These rules are active from Step 0 through Phase 3 and during any
implementation that follows.

- **No guessing.** Where input leaves something unspecified, write
  `[NEEDS CLARIFICATION: specific question]` and surface it — never silently
  invent an assumption.
- **Investigate before claiming.** Never make statements about the codebase
  without first reading the relevant files. If a claim requires looking at
  code, look first.
- **Conservative by default.** Recommend before you write; stop and ask before
  anything irreversible (deleting files, force-pushing, dropping tables,
  external service calls).
- **No over-engineering.** Only specify, plan, and build what is directly
  requested — no abstractions, extra projects, or flexibility for hypothetical
  future requirements unless the user explicitly asks.

## Before starting

Confirm `templates/spec.template.md`, `templates/plan.template.md`,
`templates/tasks.template.md`, and `templates/decision-log.template.md` exist at
the project root. If not, **stop** — tell the user to copy `templates/` from
this kit first. One source of truth: the project root, not this skill.

## Resuming an in-progress feature

If `specs/<NNN>-<slug>/` already exists: **resume, don't start** — Step 0
refuses to overwrite by design.

1. Read each document's **Status** header (`spec.md`, `plan.md`, `tasks.md`):
   `Draft` = drafted but not yet approved; `Approved` = that gate is cleared. A
   document still full of placeholders hasn't been started.
2. Resume at the first phase whose document is not `Approved`; honour the
   approval gate before moving on. Any `[NEEDS CLARIFICATION]` markers still in
   the documents are the open questions left to settle.
3. Cross-check `decision-log.md` — it carries one committed row per approved gate.

## Approval status (the resume signal)

Each document carries a **Status** field in its header — `Draft` until you
approve that gate, then `Approved — <who>, <YYYY-MM-DD>`. This field *is* the
resume state: it records what has been ratified without a separate breadcrumb
file.

- **At each approval gate**, flip the just-approved document's Status from
  `Draft` to `Approved — <who>, <date>` in the same step that appends the
  `decision-log.md` row.
- **On resume**, the first document still at `Draft` (or all-placeholder) is
  where work picks up — see "Resuming an in-progress feature" above.
- The filled-in body shows what's *drafted*; the Status field shows whether it's
  *approved*; `decision-log.md` is the durable, committed audit trail of those
  approvals. No throwaway scratch file is needed.

## Step R — Route the work (right-size before you scaffold)

Before scaffolding, **propose a track** (see `docs/adaptive-workflow-and-extensions.md`).
*You recommend; human decides.* Never pick silently.

Propose exactly one track with a one-line rationale and the artifacts you'll produce:

- **Track A · Trivial — Direct change.** Trivial, localized, no design choices: a typo,
  copy/comment edit, config value, dependency bump, obvious one-liner. *No
  feature folder, no spec, no tasks.* Make the change; if it touches behaviour,
  write and confirm a failing test first, then make it pass. When done, invoke
  the `code-reviewer` agent on the diff (no spec path — it reviews against
  `AGENTS.md` and `memory/constitution.md` only). Capture the rationale in the
  commit message.
- **Track B · Simple — Patch.** A localized bug fix or small enhancement with no new
  architecture. Scaffold the folder, write a **short `spec.md`** (problem +
  acceptance + **unchanged-behavior / regression guard** + out-of-scope) and
  `tasks.md`; **skip `plan.md`** unless a design decision surfaces. Tests-first —
  for a bug fix, that includes a regression test for each unchanged-behavior
  invariant (write it first, confirm it stays green) plus a test that fails on
  the bug and passes once fixed.
- **Track C · Moderate — Feature (default).** A normal new capability. Full Specify → Plan →
  Tasks at standard depth. This is the default when you're unsure between B and C.
- **Track D · Complex — Architecture / brownfield.** A new service, a cross-cutting change,
  or modifying untested legacy code. Full pipeline at maximum depth: add
  `research.md` and/or `data-model.md` as needed, use the strongest model
  (see `AGENTS.md` Model Routing), write **characterization tests first** for any
  legacy area, and record the cross-cutting decision as an **ADR** under
  `docs/adr/` (the decision log gets a one-line pointer to it).

In the same turn:

1. **Scan for opt-in extensions.** List every `*.opt-in.md` under
   `.agents/extensions/`, present each opt-in question. Don't load full rules
   yet — only the small prompts. No `*.opt-in.md` = always enforced; note it.
2. **Stop for route approval.** Present: track + rationale, artifacts, extension
   opt-in choices. Wait for confirmation before scaffolding or loading rules.
3. After approval, read each opted-in pack's rules and treat them as **blocking
   constraints** for every subsequent gate and review.

Record the approved track and extension choices as the first entries in
`decision-log.md` immediately after scaffolding.

**Track A**: no folder, no further phases — implement, then invoke `code-reviewer` on the diff.
**Tracks B/C/D**: continue to Step 0.

## Step 0 — Scaffold (mechanical — don't use judgment here)

**First, check for an existing feature — don't blind-scaffold.** The script
always mints a *new* incremented folder, so running it for work that already
has one creates a duplicate. Before running it: list `specs/` and compare
against the user's request. If a folder plausibly matches (by slug or topic),
**stop and confirm** with the user — "resume `specs/<NNN>-<slug>/` or start a
new feature?" — and on resume, follow "Resuming an in-progress feature" above
instead of scaffolding. Only scaffold once you've confirmed this is genuinely
new. When in doubt, ask; a wrong guess either duplicates or overwrites intent.

Then run the scaffold script with the feature description as a single argument.
Two byte-equivalent versions — use the one matching the current OS:

```bash
# macOS / Linux (bash):
bash scripts/start-feature.sh "<feature description>"
```

```powershell
# Windows (PowerShell):
pwsh scripts/start-feature.ps1 "<feature description>"
# (on Windows PowerShell, equivalently: powershell -File scripts/start-feature.ps1 "<feature description>")
```

Prefer `.ps1` on Windows, `.sh` on macOS/Linux. Unsure? Try one and fall back.

(Claude Code: `${CLAUDE_SKILL_DIR}/scripts/start-feature.{sh,ps1}`. Other
tools: use whatever path they give for this skill's folder.)

If neither script runs, do it by hand: find the highest `NNN-` prefix under
`specs/`, increment, slugify to kebab-case, create `specs/<NNN>-<slug>/`, copy
the four templates as `spec.md`, `plan.md`, `tasks.md`, `decision-log.md`.

**Immediately after scaffolding:**

- Fill `decision-log.md`'s first two rows (**Route** and **Extensions**) from
  the Step R decisions. This file is committed — the feature's durable audit trail.
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
5. Strip all instructional HTML comments (`<!-- ... -->`) and unused bracketed
   placeholders — delete whole unused sections, never leave them half-filled.
6. If any extension pack was opted in, verify the spec against its rules now
   (e.g. Security Baseline `SEC-01`/`SEC-02` shape what the requirements must
   cover for inputs and access). Any unmet **Verification** condition is a
   blocker — surface it before approval; don't defer a security gap to "later."
7. **Stop.** Present the draft. **Offer the optional sharpeners before approval** —
   they aren't auto-run, so name them or the human won't know they exist: if any
   `[NEEDS CLARIFICATION]` markers remain, recommend the `clarify` skill; for a
   high-stakes, security-sensitive, or ambiguous spec, offer the `checklist` skill
   (a requirements-quality or domain pass). Both are optional — surface them and
   let the human choose; don't run them unprompted. Then ask for explicit approval
   or resolution of any `[NEEDS CLARIFICATION]` markers before touching `plan.md`.
   Don't proceed on your own judgment. On approval, set `spec.md`'s **Status** to
   `Approved — <who>, <date>` and append a **Specify** row to `decision-log.md`.

## Phase 2 — Plan

Only after the user has approved Phase 1.

1. Read `AGENTS.md` (stack, conventions, structure) and `memory/constitution.md`
   (standing principles).
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

   For each gate, **state reasoning before verdict** — name the concrete design
   choice, don't just assert pass/fail. (E.g. "Anti-abstraction: PASS — single
   domain models, no DTO layer." / "Simplicity: FAIL — 4th module needed; see below.")

   Gate fails: fill Complexity Tracking with justification and flag clearly.

4. If the plan depends on a rapidly-changing library, run parallel research for
   version-sensitive questions before finalising — never guess.
5. If any extension pack was opted in, verify the plan against its rules and
   report compliance per rule ID (e.g. "SEC-03: secrets sourced from env, not
   committed — PASS"). An unmet **Verification** condition is a blocker unless a
   human explicitly accepts the risk, recorded in `decision-log.md`.
6. Strip `plan.md`'s instructional comments (same as Phase 1 step 5).
7. **Stop.** Present plan, gate results, extension results, research findings.
   Ask for explicit approval before touching `tasks.md`. On approval, set
   `plan.md`'s **Status** to `Approved — <who>, <date>` and append a **Plan** row
   to `decision-log.md`.

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
5. Strip `tasks.md`'s instructional comments (same as Phase 1 step 5).
6. **Stop.** Present the task list and get approval. On approval, set
   `tasks.md`'s **Status** to `Approved — <who>, <date>` and append a **Tasks**
   row to `decision-log.md`. Don't tell the user to start implementing yet — on Tracks
   C/D the analyzer gate (Phase 3.5) runs first.

## Phase 3.5 — Analyzer (gate, non-destructive)

The last guide-side gate before implementation: cross-check the artifacts
against each other and the constitution **while no code yet exists** — the
cheapest place to catch a requirement that never became a task. Invoke the
`analyzer` agent (full detail there). It is **conditional on the track**:

- **Track A** — skip (no artifacts to cross-check).
- **Track B** — optional quick pass: spec ↔ tasks coverage only (no `plan.md`).
- **Track C** — default-on: full spec ↔ plan ↔ tasks cross-check.
- **Track D** — default-on, extended: also reconcile `research.md` /
  `data-model.md` / `contracts/`, the ADR, and characterization-test ordering.

On C/D analyze runs **by default**, but it is a gate the human controls, not a
hard requirement: the user may **explicitly skip** it. Don't skip silently —
offer to run it, and if t