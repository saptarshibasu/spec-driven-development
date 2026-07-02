---
name: develop-feature
description: >-
  Use when starting spec-driven development on a new feature — triggers on
  phrases like "create a spec for X", "let's spec out Y", "start a new
  feature: Z", "use SDD for this", or "write a spec before we code". First
  right-sizes the work by proposing a workflow track (direct fix / patch /
  feature / architecture) for human approval, then scaffolds
  specs/<NNN-feature-slug>/ from this project's templates/ folder and walks
  Specify -> Plan -> Tasks -> Analyze -> (Tests red -> Implement green ->
  Review) per story, at the chosen depth, asking for explicit approval before
  each phase. Specify/Plan/Tasks are each delegated to a dedicated agent
  (specifier/planner/task-decomposer) invoked fresh, so this skill orchestrates
  and gates rather than drafting itself. The Analyzer gate (Tracks C/D)
  cross-checks the artifacts for coverage and consistency; then, one user
  story at a time, the test-writer agent writes and confirms failing tests,
  the implementor agent makes them pass, and the code-reviewer agent (looping
  with the debugger agent on any Blocker) reviews the result before the next
  story starts. Handles trivial changes too — they route to the lightweight
  track rather than being turned away.
---

# Spec-Driven Feature

Runs the Specify → Plan → Tasks workflow described in this project's
`AGENTS.md`, populating `specs/<NNN-feature-slug>/{spec.md,plan.md,tasks.md}`
from the canonical templates in `templates/`. This skill is a thin
**orchestrator**: it routes the work, scaffolds the folder, and owns every
approval gate and `decision-log.md` entry, but the actual drafting of each
document is delegated to a dedicated agent — `specifier` (`spec.md`),
`planner` (`plan.md`), `task-decomposer` (`tasks.md`) — each invoked fresh, so
none of them carries the other phases' revision back-and-forth into its own
context, and each can be pinned to the model tier its phase actually needs
(`AGENTS.md` Model Routing; see also
`docs/model-selection-and-token-optimization-in-sdd.md`). Three gated phases —
never skip a gate, and never merge two phases into one turn.

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
**Path matters**: the script lives next to *this* file, not at the repo root.
Don't run a bare `scripts/start-feature.sh` relative path — your shell's
current directory is usually the repo root (or something else entirely), not
this skill's folder, and that lookup will fail with "no such file or
directory." Instead, build the full path yourself from where you read this
SKILL.md: `.claude/skills/develop-feature/`, `.codex/skills/develop-feature/`,
`.github/skills/develop-feature/`, and `.agents/skills/develop-feature/` are
byte-identical mirrors (ADR-0001) — take whichever prefix matches the copy you
loaded, and append `scripts/start-feature.sh` (or `.ps1`). Run the command
with your shell's cwd at the **repo root** — these paths are repo-root-relative,
not relative to the skill folder. Two byte-equivalent versions — use the one
matching the current OS:

```bash
# macOS / Linux (bash) — substitute the tool prefix you're running under:
bash .claude/skills/develop-feature/scripts/start-feature.sh "<feature description>"
```

```powershell
# Windows (PowerShell) — substitute the tool prefix you're running under:
pwsh .claude/skills/develop-feature/scripts/start-feature.ps1 "<feature description>"
# (on Windows PowerShell, equivalently: powershell -File .claude/skills/develop-feature/scripts/start-feature.ps1 "<feature description>")
```

Prefer `.ps1` on Windows, `.sh` on macOS/Linux. Unsure? Try one and fall back.

If neither script runs (path genuinely doesn't resolve, no shell available,
etc.), do it by hand: find the highest `NNN-` prefix under
`specs/`, increment, slugify to kebab-case, create `specs/<NNN>-<slug>/`, copy
the four templates as `spec.md`, `plan.md`, `tasks.md`, `decision-log.md`.

**Immediately after scaffolding:**

- Fill `decision-log.md`'s first two rows (**Route** and **Extensions**) from
  the Step R decisions. This file is committed — the feature's durable audit trail.
- **Track B** does not use `plan.md`: delete the scaffolded `plan.md` and note
  "plan skipped (Track B)" in the decision log, unless a design decision later
  forces a promotion to Track C (record that promotion in the log too).

## Phase 1 — Specify

Delegates the drafting to the `specifier` agent, pinned to the strongest
available model, invoked in its own fresh context so it never carries this
session's routing/scaffolding chatter into the draft.

1. Invoke the `specifier` agent. Pass it: the user's feature description, the
   path to the newly-scaffolded `spec.md`, and the text of any opted-in
   extension rules from Step R (e.g. Security Baseline). It investigates the
   codebase read-only, fills in `spec.md` per `templates/spec.template.md`,
   applies the No-guessing guardrail (`[NEEDS CLARIFICATION: ...]` for
   anything unstated), runs the Spec Completeness Checklist itself, strips
   instructional comments, and writes the file with Status still `Draft`.
2. The agent returns a short summary — not the document text — covering any
   open `[NEEDS CLARIFICATION]` markers, the Completeness Checklist result,
   and extension-compliance notes. Relay all of it — don't summarize away an
   unmet **Verification** condition; surface it before approval, same as if
   you'd drafted it yourself.
3. **Stop.** Tell the human the file path (`specs/<NNN>/spec.md`) and the
   summary from step 2 — **don't reprint the drafted document in chat**; the
   content was already generated once for the file, and retyping it doubles
   output-token cost for no benefit. If the human asks to see it inline
   ("show me", "print it"), read the file and relay it then — otherwise let
   them review it in the file directly. **Offer the optional sharpeners
   before approval** — they aren't auto-run, so name them or the human won't
   know they exist: if any `[NEEDS CLARIFICATION]` markers remain, recommend
   the `clarify-spec` skill; for a high-stakes, security-sensitive, or ambiguous
   spec, offer the `check-spec` skill (a requirements-quality or domain pass).
   Both are optional — surface them and let the human choose; don't run them
   unprompted. Then ask for explicit approval or resolution of any
   `[NEEDS CLARIFICATION]` markers before touching `plan.md`. Don't proceed
   on your own judgment. On approval, set `spec.md`'s **Status** to
   `Approved — <who>, <date>` and append a **Specify** row to
   `decision-log.md`.
4. If the human requests substantive changes instead of approving, re-invoke
   `specifier` with the specific feedback (it re-reads its own prior draft
   from disk) rather than hand-editing `spec.md` yourself — the drafting
   agent stays responsible for spec quality, not the orchestrator. Small
   wording fixes you can make directly.

## Phase 2 — Plan

Only after the user has approved Phase 1. Delegates the drafting to the
`planner` agent — also pinned to the strongest available model, since a wrong
architecture decision here is as expensive to reverse as a wrong requirement.

1. Invoke the `planner` agent. Pass it: the path to the now-approved
   `spec.md`, and any opted-in extension rules. It reads `AGENTS.md` and
   `memory/constitution.md` itself, fills `plan.md`'s Technical Context and
   Project Structure, runs the three constitution check gates (Simplicity,
   Anti-abstraction, Integration-first) with stated reasoning before each
   verdict — for each gate, name the concrete design choice, don't just
   assert pass/fail — fills Complexity Tracking on any gate fail, runs
   version-sensitive research where the plan depends on a rapidly-changing
   library, checks extension compliance by rule ID, strips instructional
   comments, and writes `plan.md` with Status still `Draft`.
2. The agent returns a short summary — not the document text — covering the
   three gate verdicts with their reasoning, any Complexity Tracking entries,
   research findings, and extension-compliance notes. Relay all of it — a
   gate fail or an unmet **Verification** condition is a blocker unless a
   human explicitly accepts the risk, recorded in `decision-log.md`; don't
   summarize it away.
3. **Stop.** Tell the human the file path (`specs/<NNN>/plan.md`) and the
   gate/extension/research summary from step 2 — **don't reprint the drafted
   plan in chat**; the content was already generated once for the file, and
   retyping it doubles output-token cost for no benefit. If the human asks to
   see it inline, read the file and relay it then. Ask for explicit approval
   before touching `tasks.md`. On approval, set `plan.md`'s **Status** to
   `Approved — <who>, <date>` and append a **Plan** row to `decision-log.md`.
4. On requested changes, re-invoke `planner` with the specific feedback rather
   than hand-editing `plan.md` yourself, for the same reason as Phase 1.

## Phase 3 — Tasks

Only after the user has approved Phase 2. Delegates the drafting to the
`task-decomposer` agent — mid-tier model is fine here (Model Routing):
decomposition from an already-good plan is mechanical, and errors are visible
and local rather than propagating.

1. Invoke the `task-decomposer` agent. Pass it: the paths to the approved
   `spec.md` and `plan.md`, and any opted-in extension rules. It generates
   `tasks.md` grouped as Setup, Foundational (marked a hard blocker), one
   phase per user story in priority order (P1 first, tests-first within each
   story when requested, `[P]` for parallelizable tasks, `[US#]` labels,
   exact file paths, a Checkpoint per story), then Polish; represents any
   opted-in extension's verification work as explicit tasks; strips
   instructional comments; and writes `tasks.md` with Status still `Draft`.
2. The agent returns a short summary — not the document text — a task/story
   count and shape (e.g. "18 tasks across 3 user stories, 4 marked `[P]`")
   plus any extension-compliance notes. Relay it.
3. **Stop.** Tell the human the file path (`specs/<NNN>/tasks.md`) and the
   summary from step 2 — **don't reprint the task list in chat**; the content
   was already generated once for the file, and retyping it doubles
   output-token cost for no benefit. If the human asks to see it inline, read
   the file and relay it then. Get explicit approval. On approval, set
   `tasks.md`'s **Status** to `Approved — <who>, <date>` and append a **Tasks**
   row to `decision-log.md`. Don't tell the user to start implementing yet — on
   Tracks C/D the analyzer gate (Phase 3.5) runs first.
4. On requested changes, re-invoke `task-decomposer` with the specific
   feedback rather than hand-editing `tasks.md` yourself, for the same reason
   as Phase 1.

## Phase 3.5 — Analyze (gate, non-destructive)

The last guide-side gate before implementation: cross-check the artifacts
against each other and the constitution **while no code yet exists** — the
cheapest place to catch a requirement that never became a task. Invoke the
`artifact-analyzer` agent (full detail there). It is **conditional on the track**:

- **Track A** — skip (no artifacts to cross-check).
- **Track B** — optional quick pass: spec ↔ tasks coverage only (no `plan.md`).
- **Track C** — default-on: full spec ↔ plan ↔ tasks cross-check.
- **Track D** — default-on, extended: also reconcile `research.md` /
  `data-model.md` / `contracts/`, the ADR, and characterization-test ordering.

On C/D analyze runs **by default**, but starting it is a gate the human
controls, not a hard requirement: the user may **explicitly skip** it —
*before it ever runs*. Don't skip silently — offer to run it, and if the user
declines, **record the skip** (and that it was their call) in
`decision-log.md` before proceeding to implementation. Skipping is the user's
decision to make knowingly, exactly as with review. But this decision is only
available up front: once analyze has been invoked once for a feature, there is
no mid-loop bailout — see step 2.

`analyze` **reports, it does not edit.** It checks requirement→task coverage,
spec/plan/tasks contradictions, orphan/duplicate/ambiguous tasks, test-first
integrity, constitution alignment, and any opted-in extension's verification
tasks; each finding is routed to **the phase that owns the fix — Specify, Plan,
or Tasks** (a missing task is a `tasks.md` fix; a spec/plan contradiction is a
`spec.md` or `plan.md` fix). It is distinct from `check-spec` (grades the spec
alone) and the `code-reviewer` agent (reviews the diff later).

1. Offer to run analyze at the depth for the track. If the user declines on C/D,
   log the skip (step 4) and proceed — this is the only exit that doesn't
   require a clean verdict.
2. **Any finding, at any severity** (Blocker, Should-fix, or Note): loop back
   to whichever phase owns the fix (Specify / Plan / Tasks) — not always Tasks
   — fix there, then **re-run analyze**. Repeat until a run comes back with
   zero findings across all severities. There is no accepting a finding in
   place of fixing it once analyze has run — a deliberate scope call (e.g.
   "not covering FR-004 this iteration") is resolved by writing it into the
   owning artifact (e.g. `spec.md`'s Out-of-Scope section) so analyze no
   longer flags it, not by logging acceptance and moving on. Don't start
   implementation while any finding is open.
3. Each iteration still goes through the normal per-phase approval gate: the
   owning agent (`specifier` / `planner` / `task-decomposer`) proposes the
   fix, the human approves it, then analyze re-runs. This is human-approved at
   every step, just never human-skippable mid-loop.
4. On a clean verdict, **or an explicit skip decided in step 1**, append an
   **Analyze** row to `decision-log.md` (verdict, or "skipped — user's call",
   plus how many loop iterations it took) and tell the user implementation can
   begin story by story.

## Phase 3.7 — Write failing tests (test-writer gate)

After the Analyze gate clears (or is explicitly skipped), invoke the
`test-writer` agent to write failing tests **before any implementation begins**.
This is the point where TDD becomes mechanical rather than advisory.

Conditioned on track — mirrors the Analyze pattern:

- **Track A** — skip (trivial changes; still test-first if behaviour changes,
  but enforced in the commit message, not here).
- **Track B** — default-on: write a regression test for the bug and one test
  per acceptance scenario. Confirm each fails for the right reason before
  proceeding.
- **Track C** — default-on: write tests for every user story's acceptance
  scenarios before implementation of that story begins.
- **Track D** — default-on, plus characterization tests for any brownfield area
  identified in `AGENTS.md` or the plan must be written *before* any changes to
  that code. The test-writer handles this in its characterization mode —
  those land in `tests/characterization/` and pin *current* behaviour, not
  desired behaviour.

**Tests are written and confirmed red one user story at a time, immediately
before that story's implementation** — not all upfront for the whole feature.
Phases 3.7, 4, and 5 therefore form one loop that repeats per story, in the
priority order `tasks.md` lays out (P1 first): test-writer writes and
confirms that story's tests red (3.7), implementor makes them green (4),
code-reviewer reviews and the human commits (5) — then the loop starts over
at 3.7 for the next story. It only stops once the last story clears Phase 5.
This keeps test intent close to the implementation it drives and lets each
story's review happen while the work is still fresh.

1. For the next user story in priority order, invoke the `test-writer` agent.
   Pass it: the approved `spec.md` (that story's acceptance scenarios), the
   approved `tasks.md` (that story's test tasks), and any opted-in extension
   rules. On Track D, if the story touches a brownfield area named in
   `AGENTS.md` or the plan, tell it to write characterization tests for that
   area first. It writes each test, runs it, confirms it fails for the right
   reason (assertion failure or missing implementation — not an import error
   or typo), and returns a report rather than the test code itself.
2. Relay the test-writer's report as-is: each test's tier, path, and
   confirmed-failing output; which acceptance criteria are covered and which
   aren't (with reason for any gap). A confirmed-red report is the pass
   condition here — there's no separate human approval gate for "is this
   correctly red," since that's a fact the test-writer already verified by
   running it, not a judgment call.
3. Append a **Tests (red)** row to `decision-log.md` for this story (or "skipped
   — user's call" per the track table above), then continue to Phase 4 for the
   same story.

## Phase 4 — Implement (implementor gate)

Delegates the actual red→green→refactor work to the `implementor` agent —
mid-tier model, since the expensive design reasoning already happened in
Specify/Plan and this phase is mechanical execution of an already-ordered
task list (see `docs/model-selection-and-token-optimization-in-sdd.md`).
Invoked once per story, in its own fresh context, so one story's review
back-and-forth never bleeds into the next story's implementation.

**Track A** — no `implementor` invocation: Step R already routes trivial
changes straight to a direct change plus `code-reviewer` on the diff; this
phase does not apply.

**Tracks B/C/D**, once the current story's tests are confirmed red (Phase 3.7
above):

1. Invoke the `implementor` agent. Pass it: the approved `tasks.md` and
   `plan.md`/`spec.md`, the current story's scope (which task IDs), and the
   test-writer's confirmed-red report for this story. It implements the
   smallest change that makes each test pass, task by task, running the full
   story-level suite (not just the one test) before calling a task done, then
   refactors with tests kept green throughout. It never writes a new test and
   never weakens or deletes a failing one — an apparently-wrong test is
   flagged back to you, not silently edited. When a failure's root cause
   isn't obvious after one focused look, it escalates to the `debugger` agent
   itself rather than guessing.
2. Relay its report: tasks completed, tests now green, any `debugger`
   escalation and outcome, any uncovered case it found but didn't add a test
   for (that's a `test-writer` follow-up, not something implementor should
   have added silently), and any deviation from `plan.md` it had to make.
3. If the report shows a task left incomplete, a `[NEEDS CLARIFICATION]`
   marker, or a flagged-wrong test: resolve it with the human first — loop
   back to whichever phase owns the fix (the test itself → `test-writer`;
   `plan.md` → `planner`; `tasks.md` → `task-decomposer`) before continuing.
   Don't proceed to review on a partially-green story.
4. Once every test for this story is green and the story-level suite passes,
   append an **Implement** row to `decision-log.md` for this story and
   continue to Phase 5.

## Phase 5 — Review & commit (code-reviewer gate)

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
2. If the verdict has Blockers, `code-reviewer` runs its own review↔debugger
   loop internally (see the Debugger handoff section of `.agents/agents/code-reviewer.md`)
   — it asks the human to approve the first `debugger` round, then repeats
   fix→re-check on its own until every Blocker is resolved or a Blocker stops
   making forward progress across two rounds, in which case it stops and
   escalates that specific Blocker to the human instead of looping further.
   This skill does not re-implement that loop — just relay `code-reviewer`'s
   prompts and its final report.
3. On a clean verdict (`approve` or `approve-with-nits`): append a **Review**
   row to `decision-log.md`, let the human commit (the `.githooks/pre-commit`
   hook runs its own checks), and move on to the next story's Phase 3.7 — or,
   if this was the last story, the feature is done.
4. On `request-changes` with a Blocker `code-reviewer` escalated to the human
   (not resolved by its internal loop): resolve it together. If the root
   cause turns out to be a spec or plan bug rather than an implementation
   bug, loop back to `specifier` or `planner` instead of forcing another
   `implementor` pass on an already-correct implementation. Once resolved,
   re-run Phase 5 for this story.

When the last story clears Phase 5, the feature is complete. If any doc
(`README.md`, `AGENTS.md`, a glossary) now describes something inaccurately,
offer the `docs-writer` agent — it edits docs only, never application code.
