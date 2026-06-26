---
name: create-constitution
description: Use when creating or updating a project's governing constitution — triggers on phrases like "create a constitution", "set up project principles", "write our constitution", "let's define our architectural principles", "update the constitution", or "ratify the constitution". Produces a filled-in constitution.md from templates/constitution.template.md, asking targeted questions per section and requiring explicit approval before saving. Do not use for per-feature decisions (those go in spec.md) or for repo-specific operational facts (those go in AGENTS.md).
---

# Create Constitution

Produces a `memory/constitution.md` (or equivalent) for this project by
walking the user through `templates/constitution.template.md` section by
section. Two gated phases — gather principles, then ratify — never skip the
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

1. Check whether `templates/constitution.template.md` exists. If it doesn't,
   stop and tell the user — this skill requires that template.
2. Check whether a constitution already exists (look for `memory/constitution.md`,
   `docs/constitution.md`, or any path referenced in `AGENTS.md`'s Specs
   section). If one exists:
   - Tell the user what you found and show the current version briefly.
   - Ask: **amend** (update specific sections) or **recreate** (start fresh
     from the template)?
   - If amending, skip to the relevant section in Phase 1 rather than
     walking every section.
3. Read `AGENTS.md` if it exists — it often contains principles that have
   already been decided but not yet formalised into a constitution. Note
   anything there that looks like a universal principle rather than a
   project-specific fact; surface these to the user during Phase 1 as
   candidates for the constitution.

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
2. Confirm the save location with the user:
   - Default: `memory/constitution.md`
   - If AGENTS.md already references a different path, use that path
   - If neither, ask the user where they want it
3. Write the final file to the confirmed path.
4. If `AGENTS.md` exists and its Specs section references the constitution
   path, verify the path is correct — update it if the save location
   differs.
5. Set the **Version** (start at `1.0.0` for a new constitution, increment
   the minor version for an amendment), **Ratified** date (today, for a new
   constitution), and **Last Amended** date (today).
6. **Stop. Confirm to the user** where the file was saved, what version it
   is, and that implementation can now reference it. Remind them to point
   `AGENTS.md` to this file if they haven't already.

## What this skill deliberately does not do

- It does not populate `spec.md`, `plan.md`, or `tasks.md` — those are
  feature-specific documents, not project-wide principles.
- It does not skip the approval gate even if the draft looks complete —
  a constitution that hasn't been read and approved by a human is not
  ratified.

(No-guessing, no-over-populating, the conditional-vs-universal test, and the
template requirement are covered by the guardrails, the table, and "Before
starting" above.)
