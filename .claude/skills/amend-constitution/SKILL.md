---
name: amend-constitution
description: Use when updating or revisiting a project's governing constitution — triggers on phrases like "amend the constitution", "update our principles", "revisit the constitution", "change our architectural principles", "update the constitution", or "ratify a constitution change". Amends specific sections of an existing memory/constitution.md, asking targeted questions and requiring explicit approval before saving. The initial constitution is created by init-project — use this skill only for subsequent amendments. Do not use for per-feature decisions (those go in spec.md) or for repo-specific operational facts (those go in AGENTS.md).
---

# Amend Constitution

Updates specific sections of an existing `memory/constitution.md` by walking
the user through the relevant sections of `templates/constitution.template.md`.
Two gated phases — gather updated principles, then ratify — never skip the
approval gate.

## What belongs in a constitution vs. elsewhere

Before starting, be clear about the distinction so the output lands in the
right file:

| Belongs in **constitution.md** | Belongs in **AGENTS.md** | Belongs in **spec.md** |
|---|---|---|
| Always-true, every feature, every session | Repo-specific facts and operational rules | Feature-specific requirements |
| Architectural principles and their rationale | Commands, tech stack, project structure | User stories, acceptance criteria |
| Universal quality gates (test-first, no secrets) | Git/PR workflow, model routing | Success criteria, edge cases |
| Governance and amendment process | Brownfield area details, performance idioms | Out of scope for this feature |

If a principle is only sometimes true, or only applies to certain features
or areas, it does not belong in the constitution.

## Behavioral guardrails (active for the entire session)

- **No guessing.** If the user's answers leave something unspecified, write
  `[NEEDS CLARIFICATION: question]` rather than inventing a principle.
- **No over-populating.** A short constitution enforced consistently beats a
  long one that gets ignored. Push back if the user tries to add something
  conditional or feature-specific.
- **Investigate before claiming.** Read `AGENTS.md` and any existing
  constitution file before making any statements about the project's current
  principles.
- **Conservative by default.** Do not modify any existing files (including
  an existing constitution) until the user explicitly approves the draft.

## Before starting

1. Confirm `memory/constitution.md` (or the path referenced in AGENTS.md's
   Specs section) already exists. If it doesn't, tell the user to run
   `init-project` first — this skill amends an existing constitution, it does
   not create one from scratch.
2. Show the user the current constitution briefly and ask which section(s) they
   want to amend. Skip to just those sections in Phase 1 rather than walking
   every section.
3. Read `AGENTS.md` — note anything there that looks like a universal principle
   that should be in the constitution instead; surface it as a candidate.

## Phase 1 — Gather Principles

Ask the user about each section of the constitution template in turn. Do not
dump all questions at once — work through them one or two at a time so the
conversation stays focused. For each section:

### Core Principles (Articles I–V and any custom ones)

The template pre-populates Articles III (Test-First) and V
(Simplicity/Anti-Abstraction) because these are non-negotiable starting
points for spec-driven development. For the others:

**Article I — Architecture pattern:**
> "What is the primary architectural boundary for new features — should each
> feature start as a standalone module/library before being wired into the
> app, or do you have a different pattern you enforce?"

**Article II — Observability:**
> "How should components expose their behaviour for inspection — CLI
> interfaces, admin endpoints, structured logging, or something else? Is
> there a standard you want enforced on every feature?"

**Article IV — Testing strategy:**
> "For integration tests, do you prefer real services and databases over
> mocks, or do you use a hybrid approach? Are contract tests required before
> any cross-boundary implementation?"

**Additional principles:**
> "Are there any other universal principles you want enforced on every
> feature — performance floors, security mandates, compliance requirements,
> deployment policies?"

For each answer:
- If it's clearly always-true and universal → include it in the constitution
- If it's conditional or feature-specific → note that it belongs in
  AGENTS.md or spec.md instead, and explain why
- If it's unspecified → mark `[NEEDS CLARIFICATION: question]`

**Example of applying the test:**
- *"No secrets in version control"* → always true, every feature, every
  session → **constitution.**
- *"Use Testcontainers for DB integration tests"* → a tooling choice, not a
  universal principle → **AGENTS.md**, not here.
- *"The checkout flow must support Apple Pay"* → one feature's requirement →
  **spec.md**, not here.

### Additional Constraints

Prompt the user specifically for:
- Security / credentials policy (the template already includes a "no
  secrets committed" placeholder — confirm whether this applies as-is or
  needs to be worded differently for their context)
- Compliance or regulatory requirements (GDPR, HIPAA, SOC 2, etc.)
- Non-negotiable performance floors across all features
- Deployment or release policy (who can trigger production deploys, etc.)

### Development Workflow / Quality Gates

> "What gates apply to every PR without exception — required CI checks,
> minimum reviewers, coverage floors, anything that blocks a merge?"

Only include gates that are truly universal. If a gate only applies to
certain modules or feature types, note that it belongs in AGENTS.md.

### Governance

> "Who owns the constitution and has authority to amend it? What's the
> process — written rationale, review, backwards-compatibility check?"

Fill in the `[whoever owns this]` placeholder from the user's answer, and
set the version and ratification date.

### Draft and self-check

Once you have answers for all sections:

1. Fill in `templates/constitution.template.md` with the gathered
   principles, replacing all bracketed placeholders.
2. Remove every instructional HTML comment (`<!-- ... -->`) from the output —
   these guided drafting and must not appear in the committed file.
3. Remove any Article or section whose placeholder was never filled and is
   not needed — do not leave half-filled placeholder sections.
4. Self-check: for every principle, ask yourself — "is this actually
   always-true for every feature, every session?" If the honest answer is
   "sometimes" or "it depends," flag it rather than including it.

5. **Stop. Present the full draft to the user and ask for explicit
   approval** — or resolution of any `[NEEDS CLARIFICATION]` markers —
   before writing anything to disk. Highlight any places where you made
   a judgement call the user should review.

## Phase 2 — Ratify

Only after the user has approved Phase 1.

1. Apply any changes from the review pass.
2. Write the amended file to the same path it came from.
3. Increment the **minor version** (e.g. `1.0.0` → `1.1.0`) and set
   **Last Amended** to today.
4. **Stop. Confirm to the user** where the file was saved and what version it is.

## What this skill deliberately does not do

- It does not populate `spec.md`, `plan.md`, or `tasks.md` — those are
  feature-specific documents, not project-wide principles.
- It does not skip the approval gate even if the draft looks complete —
  a constitution that hasn't been read and approved by a human is not
  ratified.

(No-guessing, no-over-populating, the conditional-vs-universal test, and the
template requirement are covered by the guardrails, the table, and "Before
starting" above.)
