<!--
  TEMPLATE — project-wide, ALWAYS-true principles. Not feature-specific.
  This file changes rarely and deliberately; per-feature specifics go in
  spec.template.md instead. Save as e.g. `memory/constitution.md` or
  `docs/constitution.md` and point to it from AGENTS.md.

  Keep this short. Every principle here should be something you'd enforce
  on EVERY feature, in EVERY session, regardless of who's working on it —
  if it's only sometimes true, it belongs in a spec or a Skill, not here.

  Once a principle below is filled in, delete its instructional comment along
  with it — including this one, once the constitution is ratified. Watch in
  particular for principle III below: its example citation only makes sense
  while you're drafting from this knowledge base's templates, not as
  permanent content of your actual constitution.
-->

# [PROJECT NAME] Constitution

## Core Principles

### I. [PRINCIPLE NAME, e.g. "Library-First"]

[One or two sentences. Example: "Every feature starts as a standalone,
independently testable module before it's wired into the application — no
feature is implemented directly inline with no reusable boundary."]

### II. [PRINCIPLE NAME, e.g. "Observability"]

[Example: "Every component exposes a way to inspect or invoke it directly
(CLI, admin endpoint, structured logs) — nothing should require attaching a
debugger to understand what it did."]

### III. Test-First (NON-NEGOTIABLE)

No implementation code is written before:
1. The test is written.
2. The test is reviewed/approved (by a human, or against the spec's
   acceptance criteria).
3. The test is confirmed to **fail** for the expected reason.

Red → Green → Refactor, enforced every time.

Additional rules that are corollaries of this principle and equally
non-negotiable:
- **Never delete or weaken a failing test to make the suite pass.** Fix
  the implementation, or flag the test as wrong and get explicit approval
  before changing it.
- **Brownfield areas:** Before changing existing behaviour in any area
  without existing tests, write characterization tests capturing *current*
  behaviour first — do not assume what "correct" means without one. Mark
  these areas in `AGENTS.md` so all agents know to apply this rule there.

### IV. [PRINCIPLE NAME, e.g. "Integration-First Testing"]

[Example: "Prefer real databases and real service instances over mocks
wherever practical. Contract tests are mandatory before implementation of
anything crossing a service or repo boundary."]

### V. Simplicity / Anti-Abstraction

- Maximum [N] new top-level modules/projects per feature without documented
  justification (see Complexity Tracking in plan.template.md).
- Use the framework directly rather than wrapping it, unless the wrapper is
  justified in writing.
- No speculative "might need it later" features or abstractions — every
  abstraction must trace back to a concrete, current requirement.

## [Additional Constraints]

<!-- Security requirements, compliance standards, performance floors,
     deployment policies — anything that's always true for this project.
     Example entries below; keep only what's genuinely universal for your
     project and delete the rest. -->

- **Credentials:** No secrets, API keys, tokens, or passwords are ever
  committed to version control, hard-coded in source files, or logged.
  Use the project's designated secrets manager or environment-variable
  mechanism — always.
- [Compliance / regulatory requirement, if any — e.g. "All PII must be
  encrypted at rest and in transit; no PII in logs."]
- [Performance floor, if non-negotiable across all features — e.g.
  "p95 response time ≤ 200 ms for all user-facing endpoints."]
- [Deployment policy, if universal — e.g. "Production deploys require
  a human to trigger them; no automated deploy to production."]

## [Development Workflow / Quality Gates]

<!-- Code review requirements, required CI checks, what blocks a merge.
     Only include items that are enforced for every PR, without exception. -->

- [e.g., "All CI checks must pass before merge — no exceptions."]
- [e.g., "Every PR requires at least one human review from a team member
  who did not write the code."]
- [e.g., "Coverage must not drop below N% — PRs that reduce coverage are
  blocked until tests are added."]

## Governance

This constitution supersedes ad hoc team conventions. Amendments require:
- Written rationale for the change.
- Review/approval by [whoever owns this].
- A note on backward-compatibility impact for in-flight features.

Use `AGENTS.md` and per-feature `spec.md` files for day-to-day, conditional
guidance — this file is for what's true regardless of which feature is being
built.

**Version**: [x.y.z] | **Ratified**: [DATE] | **Last Amended**: [DATE]
