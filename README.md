# Spec-Driven Development — Starter Kit

Companion repository for the Medium article [**Distilled AI-Assisted Development Guidelines**](https://medium.com/@sapbasu/distilled-ai-assisted-development-guidelines-351ac9ab0154).

This repo is a ready-to-copy folder structure for teams practising **spec-driven development (SDD)** with AI coding agents (Claude, Copilot, Cursor, etc.). Clone it into your project and fill in the bracketed placeholders — the templates are designed so that every generic line gets replaced with something true and specific to your codebase.

---

## What's in here

```
<project-root>/
├── AGENTS.md                          # Always-loaded by every agent — the canonical
│                                      #  instruction file; keep it specific and short
├── CLAUDE.md                          # Optional — thin pointer to AGENTS.md.
│                                      #  Only add if your tool can't read AGENTS.md
│                                      #  directly (most modern tools can)
│
├── .agents/                           # CANONICAL skills (tool-agnostic). This is
│   └── skills/                        #  the SOURCE copy; setup.sh mirrors it into
│       ├── spec-driven-feature/       #  .claude/.github/.codex so every tool sees
│       │   ├── SKILL.md               #  identical definitions. Edit skills HERE,
│       │   └── scripts/               #  then re-run setup.sh — never hand-edit a
│       │       └── start-feature.sh   #  mirror (see docs/adr/0001-*).
│       └── create-constitution/
│           └── SKILL.md
│
├── .github/                           # GitHub Copilot
│   ├── copilot-instructions.md        # Thin pointer to AGENTS.md
│   ├── instructions/
│   │   └── sample.instructions.md     # Path-scoped Copilot rules — one file per
│   │                                  #  path glob, declared with `applyTo:` frontmatter
│   ├── skills/                        # ← mirror of .agents/skills/
│   ├── agents/
│   │   └── docs-agent.agent.md        # Example custom agent (docs upkeep)
│   └── workflows/
│       └── agent-harness.yml          # Example CI feedback harness (see docs/
│                                      #  harness-engineering.md) — adapt to your stack
│
├── .claude/                           # Claude Code
│   ├── skills/                        # ← mirror of .agents/skills/
│   └── agents/
│       └── code-reviewer.md           # Example review subagent (inferential sensor)
│
├── .codex/                            # OpenAI Codex
│   ├── skills/                        # ← mirror of .agents/skills/
│   └── agents/
│       └── reviewer.toml              # Example review agent
│
├── memory/
│   └── constitution.md                # Project-wide principles — rarely changes,
│                                      #  always loaded before architecture decisions.
│                                      #  Copy from templates/constitution.template.md
│
├── templates/                         # Canonical document templates — AGENTS.md
│   ├── constitution.template.md       #  points here. Never invent a different
│   ├── spec.template.md               #  structure for these documents
│   ├── plan.template.md
│   ├── tasks.template.md
│   └── checklist.template.md          # Optional — for repeatable review passes
│                                      #  (security, a11y, migration-readiness, etc.)
│
├── specs/
│   ├── 001-<feature-name>/
│   │   ├── spec.md                    # What & why — no tech detail, no API shapes
│   │   ├── plan.md                    # How — written after spec is approved
│   │   ├── tasks.md                   # Task breakdown, grouped by user story;
│   │   │                              #  generated from plan + spec, not hand-written
│   │   ├── research.md                # Optional — open questions resolved during
│   │   │                              #  planning that didn't fit in the spec
│   │   ├── data-model.md              # Optional — conceptual data model for this
│   │   │                              #  feature (no ORM detail — just the concepts)
│   │   ├── quickstart.md              # Optional — key validation scenarios for fast
│   │   │                              #  smoke-testing during implementation
│   │   └── contracts/                 # Optional — this feature's API/event contracts
│   ├── 002-<feature-name>/
│   │   └── ...                        # Same shape — one folder per feature, numbered
│   └── contracts/
│       └── <upstream-dependency>.md   # Cross-cutting contract snapshots for
│                                      #  dependencies this repo consumes but doesn't
│                                      #  own (e.g. model classes from a shared lib).
│                                      #  Do not hand-edit — flag as stale if outdated
│
├── docs/                              # Deep reference — read on demand, NOT loaded
│   │                                  #  into every session (see context-engineering.md)
│   ├── README.md                      # Index of the docs below
│   ├── context-engineering.md         # What the agent sees per call; context rot
│   ├── harness-engineering.md         # Feedforward guides + feedback sensors
│   ├── token-efficiency.md            # Most correct work per token
│   ├── model-selection-and-token-optimization-in-sdd.md   # Per-phase model routing
│   ├── efficient-code-generation-and-performance-pitfalls.md  # Why agents write slow code
│   ├── glossary.md                    # Domain vocabulary — pointed to (not inlined)
│   │                                  #  from AGENTS.md's Domain Language section
│   ├── adr/
│   │   ├── 0000-template.md           # Copy this for a new ADR
│   │   └── 0001-<decision>.md         # Architecture Decision Records — check here
│   │                                  #  before changing any cross-cutting pattern
│   └── <topic>.md                     # Add your own deep-reference material here;
│                                      #  reference by name from AGENTS.md (not inlined)
│
├── src/
│   └── ...                            # Your actual source tree — see AGENTS.md's
│                                      #  Project Structure and Tech Stack sections
│
└── tests/
    ├── contract/                      # Written before implementation, per tasks.md
    ├── integration/
    ├── unit/
    └── characterization/              # Brownfield only — capture current behaviour
                                       #  before changing it; kept separate from
                                       #  ordinary feature tests so their special
                                       #  status stays visible
```

---

## The three-phase workflow

Each feature follows a strict gate sequence. An agent is not allowed to advance to the next phase without explicit human approval.

| Phase | Artifact | What it contains | Who writes it |
|---|---|---|---|
| **1 — Specify** | `specs/<NNN-feature>/spec.md` | WHAT and WHY. User stories, acceptance criteria, requirements, success metrics, out-of-scope. **No tech detail.** | Human-led, agent assists |
| **2 — Plan** | `specs/<NNN-feature>/plan.md` | HOW. Stack, architecture, file layout, constitution check. Generated by agent against the locked spec. | Agent, human reviews |
| **3 — Tasks** | `specs/<NNN-feature>/tasks.md` | Ordered, parallelism-annotated task list. Generated from plan + spec. Test tasks always come first within each story. | Agent, human reviews |

The constitution (`templates/constitution.template.md`) sits above all three phases — it contains principles that apply to every feature, every session, without exception.

---

## How to use these templates

### 1. Bootstrap a new project

```bash
git clone https://github.com/sapbasu/spec-driven-development.git my-project-sdd
cd my-project-sdd
bash setup.sh          # creates all directories, skill files, and stubs
```

Or copy the files into an existing repo and run `setup.sh` from its root. Then:

1. **Fill in `AGENTS.md`** — replace every `[bracketed placeholder]` with a fact that is true and specific to your repo. Delete any section that doesn't apply. Delete instructional comments once you're done. Every line should be something an agent could *not* already infer from training.
2. **Ratify a constitution** — fill in `memory/constitution.md` (seeded from `templates/constitution.template.md` by `setup.sh`). Point to it from `AGENTS.md`.
3. **Populate the glossary** — add your domain terms to `docs/glossary.md`.
4. The `spec-driven-feature` and `create-constitution` skills are installed in `.agents/skills/` (canonical) and mirrored into `.github/skills/`, `.claude/skills/`, and `.codex/skills/` by `setup.sh`. Edit them only in `.agents/` and re-run `setup.sh` to re-sync — never hand-edit a mirror.
5. **Wire up the feedback half of your harness** — fill in `.github/workflows/agent-harness.yml` with your real lint/test commands (the same ones named in `AGENTS.md`), and set the model for the example review agents. See `docs/harness-engineering.md`.

### 2. Start a feature

Use the `spec-driven-feature` skill (prompt: *"start a new feature: <description>"*). It scaffolds the folder and three template files, then walks you through each phase with explicit approval gates. To do it manually:

```
specs/
└── 001-<feature-name>/
    ├── spec.md        ← copy from templates/spec.template.md
    ├── plan.md        ← do not fill in until spec.md is approved
    └── tasks.md       ← do not fill in until plan.md is approved
```

Work through the spec with your agent. Keep it pure WHAT/WHY — no API shapes, no file names, no tech stack. Once the spec is approved, generate `plan.md`, then `tasks.md`.

### 3. Implement

Tasks in `tasks.md` are your implementation queue. Within each user story, tests come first — always red before green.

---

## Key design decisions in the templates

**`AGENTS.md` is the single source of truth for agent instructions.** All IDEs, agent runtimes, and CI tools point here; the per-tool files (`.github/copilot-instructions.md`, `CLAUDE.md`) are one-liners that redirect to it. You update one file, not three.

**Spec and plan are intentionally separate.** A spec that survives a framework swap unchanged was written correctly. Mixing "what" and "how" in a single document leads agents to anchor on implementation choices before the requirements are even stable.

**Tasks are generated, not written from scratch.** Once you have a locked spec and a reviewed plan, an agent can generate `tasks.md` deterministically. Writing tasks by hand before the plan exists is premature and usually wrong.

**The constitution is short on purpose.** It contains only what is always true. Per-feature decisions go in specs; per-repo conventions go in `AGENTS.md`. If a principle only applies sometimes, it doesn't belong in the constitution.

---

## Engineering reference (`docs/`)

The folder structure above is the *what*. These five guides are the *why* — the engineering principles that make agents productive, and what to wire up next. They are deep-reference material: read on demand, not loaded into every session.

| Guide | Read it when |
|---|---|
| [`docs/context-engineering.md`](docs/context-engineering.md) | Deciding what goes in AGENTS.md vs. a doc vs. a spec; an agent is underperforming and you suspect a bloated or rotting context. |
| [`docs/harness-engineering.md`](docs/harness-engineering.md) | Setting up the guides + sensors around your agent; deciding what to mechanize (tests/lint) vs. leave to review. |
| [`docs/token-efficiency.md`](docs/token-efficiency.md) | Costs or latency are high; you want the most correct work per token without cutting the controls that prevent re-work. |
| [`docs/model-selection-and-token-optimization-in-sdd.md`](docs/model-selection-and-token-optimization-in-sdd.md) | Configuring AGENTS.md's Model Routing — which model for Specify/Plan vs. routine work. |
| [`docs/efficient-code-generation-and-performance-pitfalls.md`](docs/efficient-code-generation-and-performance-pitfalls.md) | Filling in AGENTS.md's Performance & Efficiency section; agents keep generating per-row loops or N+1 queries. |

These tie back into the structure: context engineering shapes `AGENTS.md` and the tiering of instructions; harness engineering is embodied by the templates, gates, the `code-reviewer` agent, and `.github/workflows/agent-harness.yml`; the model-routing and performance docs are the reasoning behind those two `AGENTS.md` sections.

---

## Further reading

- [Distilled AI-Assisted Development Guidelines](https://medium.com/@sapbasu/distilled-ai-assisted-development-guidelines-351ac9ab0154) — the article this repo accompanies; includes the full reference SKILL.md and start-feature.sh
- [AWS re:Invent 2025 — AI-Driven Development Lifecycle (AI-DLC)](https://youtu.be/1HNUH6j5t4A?si=RdaprHyWKS78UlmO) — the methodology this playbook builds on
- [Harness engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html) — Martin Fowler on feedforward and feedback harnesses
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic on the attention budget, compaction, and note-taking
- [Agent READMEs: An Empirical Study of Context Files for Agentic Coding](https://arxiv.org/abs/2511.12884) — what's actually in real context files, and what helps vs. hurts
- [How to write a great AGENTS.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) — lessons from 2,500+ repos (GitHub)
- [Claude prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) — Anthropic's guide to writing effective prompts; directly applicable to AGENTS.md and spec writing
- [Claude Code documentation](https://docs.claude.com) — if you're using Claude as your agent runtime
- [GitHub Copilot custom instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot) — how Copilot reads `.github/copilot-instructions.md`
- [spec-kit](https://github.com/github/spec-kit/tree/main) — GitHub's own spec templates; a close relative of the templates in this repo
- [awesome-copilot](https://github.com/github/awesome-copilot) — curated Copilot instructions, skills, and agents from the community
