---
name: init-project
description: Use when setting up a project's AI agent configuration from scratch — triggers on phrases like "initialize the project", "set up AGENTS.md", "bootstrap project config", "create project constitution", "set up the project for agents", "initialize agent config", "let's configure the project", or any request to fill in the project's AGENTS.md or create its constitution. Reads the codebase first, then produces both a filled-in AGENTS.md and memory/constitution.md in a single gated session with explicit approval before writing either file. This is the one-time project setup step that should happen before any spec-driven-feature work.
---

# Init Project

Bootstraps a project's agent configuration in one session by scanning the
actual codebase and producing two generated files:

1. `AGENTS.md` — generated from `templates/agents.template.md`, filled with
   real values specific to this project; loaded into every agent session
2. `memory/constitution.md` — generated from `templates/constitution.template.md`,
   containing universal always-true principles for this project

`AGENTS.md` is an **output**, not a source file. The template lives in
`templates/agents.template.md` and should never be edited directly at the
root. Re-run this skill to regenerate it if the project changes significantly.

Three gated phases: **Investigate → Draft AGENTS.md → Draft Constitution**.
Never skip an approval gate or merge two phases into one turn.

## What goes where (keep this distinction sharp throughout)

| Belongs in **AGENTS.md** | Belongs in **constitution.md** |
|---|---|
| Commands (build, test, lint, run) | Architectural principles (always true) |
| Tech stack and versions | Test-first mandate |
| Project structure | Simplicity / anti-abstraction rules |
| Git/PR workflow | Security and compliance policies |
| Model routing | Quality gates for every PR |
| Performance idioms specific to this stack | Governance / amendment process |
| Brownfield area details | |

If something is only sometimes true, or only applies to certain features, it
belongs in AGENTS.md or a spec — not the constitution.

## Behavioral guardrails (active for the entire session)

- **Investigate before asking.** Read the codebase first. Every question you
  ask should be something you genuinely cannot answer by reading files. If
  you can infer it (e.g., "I see `pytest` in requirements.txt — is tests/ the
  right location?"), confirm briefly rather than asking open-endedly.
- **No guessing.** Anything you cannot infer and the user doesn't answer →
  mark `[NEEDS CLARIFICATION: specific question]`. Never fill a placeholder
  with a fabricated value.
- **No over-populating.** A short, accurate AGENTS.md beats a long generic
  one. A short constitution enforced consistently beats a long one that gets
  ignored. Push back on conditional or feature-specific content that doesn't
  belong in these files.
- **Conservative.** Do not write either file until the user explicitly
  approves the draft. Treat this like schema changes — hard to walk back once
  agents start reading it.

## Before starting

1. Confirm both templates exist:
   - `templates/agents.template.md` — template for AGENTS.md
   - `templates/constitution.template.md` — template for the constitution
   If either is missing, stop and tell the user.
2. Check whether a real `AGENTS.md` already exists and looks filled in (not
   the stub). If it does, ask: **regenerate from scratch** or **amend**?
3. Check whether `memory/constitution.md` (or any constitution path referenced
   in the existing AGENTS.md) already exists. Same question if so.

---

## Phase 1 — Investigate

Do this before asking the user a single question. Scan the project and build
a profile. Look for:

- **Package / build files**: `package.json`, `pyproject.toml`, `pom.xml`,
  `Cargo.toml`, `go.mod`, `Gemfile`, `build.gradle`, etc. — extract language,
  runtime version, framework, key dependencies.
- **Test infrastructure**: test directories (`tests/`, `spec/`, `__tests__/`),
  test runner config (`pytest.ini`, `jest.config.*`, `vitest.config.*`).
- **CI/CD**: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile` — extract
  what commands are run in CI (build, lint, test).
- **Project structure**: top-level directories and what they appear to contain.
- **Existing docs**: `README.md`, `docs/`, `ADR/`, any architecture notes.
- **Git config**: branch protection hints, PR templates (`.github/`).
- **Existing AGENTS.md**: note which sections are filled vs. still placeholder.

After the scan, prepare a brief summary of what you found and what you still
need to ask about. Group your questions by AGENTS.md section — don't dump
them all at once. Work through them two or three at a time.

**Key questions to resolve per section (ask only what you can't infer):**

*Commands* — you likely found build/test/lint commands in CI or package files;
confirm edge cases (single-test invocation, local run command).

*Tech Stack* — confirm specific versions if not in lockfiles; ask about key
libraries that shape how code should be written (ORM, HTTP client, state
management, etc.).

*Project Structure* — describe what you see; ask the user to correct or
annotate anything ambiguous.

*Code Style* — ask for a real example snippet that shows the preferred style,
or ask where existing idiomatic code lives so you can reference it.

*Git / PR Workflow* — branch naming pattern, commit message format, PR
requirements (CI gate, minimum reviewers, issue link).

*Boundaries* — ask what agents should always do without asking, what requires
human sign-off, and what's a hard stop. Give examples to make the question
concrete.

*Performance & Efficiency* — ask what the highest-frequency bulk operation is
(DB writes, API calls, batch jobs) and whether there's a known idiom for it.
Ask if there's a null/empty-check utility they want used consistently.

*Model Routing* — ask which model tiers are available and which phases should
use which tier (Specify/Plan vs. Tasks/routine vs. quick edits).

*Brownfield areas* — ask if there are areas with no test coverage where agents
should write characterization tests before touching anything.

Once you have enough to fill in the template accurately, move to Phase 2.

---

## Phase 2 — Draft AGENTS.md

Fill in the AGENTS.md template from your investigation and the user's answers:

1. Replace every `[bracketed placeholder]` with a real value or remove the
   section if it doesn't apply to this project.
2. Remove **every** HTML comment (`<!-- ... -->`) — these are authoring
   instructions, not content. They must not appear in the committed file.
3. Remove any section that genuinely doesn't apply (e.g., Multi-Repo if the
   project is self-contained) rather than leaving it with placeholder text.
4. The Performance & Efficiency section is high-leverage — even if you only
   have the bulk-operation idiom and the null-check convention, include them.
   These are the patterns agents most often get wrong by default.
5. Self-check: would an agent reading this file learn something it couldn't
   already infer from general training data? If a line would be true of any
   project, cut it.

**Stop. Present the full draft to the user.** Highlight any `[NEEDS
CLARIFICATION]` markers and any sections where you made a judgment call.
Ask for explicit approval — or amendments — before proceeding. Do not write
anything to disk yet.

---

## Phase 3 — Draft Constitution

Only after the user has approved the AGENTS.md draft.

Use `templates/constitution.template.md` as the base. You already learned a
lot about this project in Phase 1 — use it. Ask only what remains unresolved:

**Article I — Architecture pattern:**
> "What is the primary architectural boundary for new features — do they start
> as standalone modules before being wired in, or is there a different pattern
> you enforce?"

**Article II — Observability:**
> "How should components expose their behaviour — CLI interfaces, admin
> endpoints, structured logs? Is there a standard you want on every feature?"

*(Articles III and V are pre-populated in the template — confirm the user
wants them as-is or amended.)*

**Article IV — Testing strategy:**
> "For integration tests, do you prefer real services/databases over mocks?
> Are contract tests required before any cross-boundary implementation?"

**Additional constraints:**
> "Any security, compliance (GDPR, HIPAA, SOC 2), or performance floors that
> apply to every feature without exception?"

**Quality gates:**
> "What must be true for every PR — specific CI checks, minimum reviewers,
> coverage floor?"

**Governance:**
> "Who owns the constitution and has authority to amend it?"

Apply the same filter as AGENTS.md: if a principle is only sometimes true, or
only applies to certain features, note that it belongs in AGENTS.md or a spec
instead.

Once drafted:
1. Fill in the template, replacing all bracketed placeholders.
2. Remove every HTML comment (`<!-- ... -->`).
3. Remove any Article whose placeholder was never filled and isn't needed.
4. Set **Version** to `1.0.0`, **Ratified** to today's date.

**Stop. Present the full draft to the user.** Highlight any `[NEEDS
CLARIFICATION]` markers and judgment calls. Require explicit approval before
writing. Do not write either file to disk until both are approved.

---

## Writing files (after both are approved)

Write in this order:

1. **AGENTS.md** — write to the project root, replacing the stub. This file
   is generated output; `templates/agents.template.md` remains the source.
2. **constitution.md** — confirm the save path with the user (default:
   `memory/constitution.md`). Create the `memory/` directory if needed.
3. Verify AGENTS.md's Specs section references the correct constitution path;
   update if the save location differs from what was drafted.

Then confirm to the user:
- Both files written and their paths
- Constitution version and ratification date
- Reminder: run `mirror-agents.sh` (or `.ps1`) to sync AGENTS.md to
  `.agents/` and `.codex/` (this project uses mirroring)
- Next step: use `spec-driven-feature` to start the first feature

## What this skill does not do

- It does not create feature specs, plans, or tasks — those are per-feature.
- It does not skip approval gates even if the drafts look complete — a
  constitution that hasn't been read and approved by a human is not ratified,
  and an AGENTS.md that hasn't been confirmed may contain wrong commands.
