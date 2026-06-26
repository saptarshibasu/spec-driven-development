<div align="center">

# 🧭 Spec-Driven Development — Starter Kit

**A lightweight, customizable accelerator for spec-driven development with AI coding agents.**
No install, no CLI — just files you adapt to your stack. Specs before code, gates before merge, and a context file that earns every token.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Method](https://img.shields.io/badge/method-Spec--Driven%20Development-6f42c1.svg)](#-the-workflow)
[![Agents](https://img.shields.io/badge/agents-Claude%20·%20Copilot%20·%20Codex-2ea44f.svg)](#-whats-inside)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#)

</div>

---

Clone it, fill in the placeholders, and you have an opinionated structure for **spec-driven development (SDD)**: a constitution, gated spec→plan→tasks templates, skills and subagents, hooks, CI, and a `docs/` knowledge base on the engineering that makes agents actually productive.

> [!TIP]
> **The one idea behind everything here:** an agent's context is a budget, not a junk drawer. Every line in `AGENTS.md`, every doc, every tool must earn its place. Empirical studies find kitchen-sink context files can *hurt* performance — so this kit optimizes for *the smallest set of high-signal guidance that makes the agent act correctly.*

## 🔄 The workflow

Each feature flows through gated phases. **An agent never advances a gate without explicit human approval.**

```mermaid
flowchart TD
    K["📜 Constitution<br/><i>always-true principles</i>"]:::gov
    S["1 · Specify · spec.md<br/><b>WHAT & WHY</b> — no tech"]:::phase
    CL["Clarify<br/><i>optional</i>"]:::gate
    CK["Checklist<br/><i>optional</i>"]:::gate
    P["2 · Plan · plan.md<br/><b>HOW</b> — stack & design"]:::phase
    T["3 · Tasks · tasks.md<br/><b>ordered, tests-first</b>"]:::phase
    I["Implement<br/><i>red → green → refactor</i>"]:::impl
    R["🔍 Review<br/><i>code-reviewer agent</i>"]:::sensor
    B["📝 SCRATCH.md<br/><i>resume breadcrumb · gitignored</i>"]:::scratch

    K -. governs every phase .-> S
    S -->|✋ approve| P -->|✋ approve| T -->|✋ approve| I --> R
    S -. optional sharpen .-> CL
    CL -.-> CK
    CK -.-> S
    S -. writes at each gate .-> B
    P -.-> B
    T -.-> B
    B -. read on resume .-> S

    classDef gov fill:#6f42c1,color:#fff,stroke:#4c2889
    classDef phase fill:#0969da,color:#fff,stroke:#0a4b8c
    classDef gate fill:#bf8700,color:#fff,stroke:#7d5800
    classDef impl fill:#1a7f37,color:#fff,stroke:#0f5323
    classDef sensor fill:#cf222e,color:#fff,stroke:#8b1a22
    classDef scratch fill:#6e7781,color:#fff,stroke:#424a53
```

A spec that survives a framework swap unchanged was written correctly. Specs are pure **what/why**; the **how** lives in the plan; tasks are *generated* from both.

**What you actually run, and when:**

1. **Setup (once per project)** — run `create-constitution` to ratify principles, `sync-agents-md` to fill `AGENTS.md` from your repo, then `git config core.hooksPath .githooks` to arm the pre-commit sensor.
2. **Start a feature** — run `spec-driven-feature`. It scaffolds `specs/<NNN>/` (calling `start-feature.sh` on macOS/Linux or `start-feature.ps1` on Windows) and drafts `spec.md` (Specify), marking open questions as `[NEEDS CLARIFICATION]`.
3. **(Optional) Sharpen the spec at the approval gate** — `spec-driven-feature` pauses after the draft and waits for you. If it left `[NEEDS CLARIFICATION]` markers or the spec needs tightening, run `clarify` and/or `checklist` *here*; otherwise just answer any open questions inline. Neither is a required step. **You approve the spec.**
4. **Plan, then tasks — same run** — once you approve, the skill continues *on its own* to `plan.md`, pauses for approval, then generates `tasks.md`. You don't relaunch it; each "stop" is a pause-for-approval, not an exit.
5. **Implement** — red → green → refactor, one story at a time; lean on the `test-writer` and `debugger` agents as needed.
6. **Review & commit** — the `code-reviewer` agent checks the diff against spec + constitution; on commit, `.githooks/pre-commit` blocks secrets, unresolved markers, and runs your lint/tests.

Steps 2–6 repeat per feature; step 1 is one-time (re-run `sync-agents-md` whenever the project drifts).

> [!NOTE]
> **Interrupted mid-feature?** Nothing is lost — your progress lives in that feature's `specs/<NNN>/spec.md`, `plan.md`, and `tasks.md`, and the skill keeps a gitignored `SCRATCH.md` breadcrumb updated **at each gate** (current phase, what's next, open questions). To resume, just re-invoke `spec-driven-feature` for the same feature (don't re-run `start-feature` — it won't overwrite an existing feature): it reads the breadcrumb plus the filled-in documents and picks up at the next unapproved gate. Even an abrupt kill mid-phase is covered, because the breadcrumb is written as it goes — not only on a graceful stop.

## 🛰️ The harness model

The kit is built as a **harness** ([Martin Fowler's term](https://martinfowler.com/articles/harness-engineering.html)): *guides* that steer the agent before it acts, and *sensors* that catch it after. Both halves ship — you wire the sensors to your stack.

```mermaid
flowchart TB
    subgraph FF["🧭 Feedforward · guides (before)"]
        direction LR
        A["AGENTS.md + constitution"]
        SK["skills: spec-driven-feature,<br/>clarify, checklist"]
        TPL["templates/"]
    end
    subgraph FB["🛰️ Feedback · sensors (after)"]
        direction LR
        TS["✅ tests · contract tests<br/><i>your stack — out of scope here</i>"]:::byo
        SA["🔎 linters · type-checkers<br/>SAST · dependency/SCA (vuln) scan<br/><i>your stack — out of scope here</i>"]:::byo
        HK[".githooks/pre-commit<br/><i>secret scan (shipped) + your lint/tests · local</i>"]
        CI["CI · agent-harness.yml<br/><i>runs them on every PR · slot provided</i>"]
        AG["🧠 code-reviewer agent<br/><i>inferential backstop</i>"]
    end
    FF ==> AGENT(("🤖 coding<br/>agent")) ==> FB
    FB -. self-correct .-> AGENT
    AGENT -. writes / reads breadcrumb .-> SC["📝 SCRATCH.md<br/><i>resume state · gitignored</i>"]:::cont

    classDef ff fill:#ddf4ff,stroke:#0969da,color:#0a3069
    classDef fb fill:#ffebe9,stroke:#cf222e,color:#6e0a1e
    classDef cont fill:#eaeef2,stroke:#6e7781,color:#24292f
    classDef byo fill:#fff8e6,stroke:#bf8700,color:#5c4400,stroke-dasharray:4 3
    class FF ff
    class FB fb
```

> [!NOTE]
> **Mechanize what you can, infer what you must.** A prose rule the agent re-reads each session is the *weakest* guarantee. Promote the ones that matter into a hook or a test. See [`docs/harness-engineering.md`](docs/harness-engineering.md).

## 🚀 Quickstart

```bash
git clone https://github.com/saptarshibasu/spec-driven-development.git my-project-sdd
cd my-project-sdd
```

A fresh clone already carries every directory, pointer, stub, and skill mirror —
there is no scaffolding step to run. (If you later edit or add a skill under
`.agents/skills/`, re-mirror it into the tool dirs with `bash mirror-skills.sh`,
or `pwsh ./mirror-skills.ps1` on Windows.)

Then, in order:

1. **Fill in `AGENTS.md`** — replace every `[placeholder]` with a fact specific to your repo; delete anything an agent could infer from training. (The `sync-agents-md` skill can draft this from your codebase.)
2. **Ratify the constitution** — run the `create-constitution` skill (or edit `memory/constitution.md`).
3. **Add domain terms** to `docs/glossary.md`.
4. **Enable the hook** — `git config core.hooksPath .githooks`. (On Windows, Git runs the POSIX `pre-commit` via Git Bash; a native `pre-commit.ps1` is also provided.)
5. **Start a feature** — *"start a new feature: &lt;description&gt;"* (the `spec-driven-feature` skill).

## 📦 What's inside

### 🛠️ Skills — workflow commands *(canonical in `.agents/skills/`, mirrored to every tool)*

| Skill | When you run it | What it does |
|---|---|---|
| `create-constitution` | Once, at setup | Builds/ratifies `memory/constitution.md` from the template. |
| `sync-agents-md` | At setup, then to re-sync | Fills in `AGENTS.md` + `docs/glossary.md` from the actual repo, and later flags drift — evidence-based, never guessed. |
| `spec-driven-feature` | Start of every feature | Scaffolds `specs/<NNN>/` (via `start-feature.sh` / `.ps1`) and walks Specify → Plan → Tasks with approval gates. |
| `clarify` | After the spec draft | Surfaces spec ambiguities, asks a few targeted questions, writes answers back. |
| `checklist` | Before approving the spec | "Unit tests for the requirements" — complete, clear, consistent, measurable? |

### 🤖 Agents — the sensor half *(examples in `.claude/agents/`; adapt per runtime)*

| Agent | Role |
|---|---|
| `code-reviewer` | Inferential review vs. spec, constitution, conventions. Read-only. |
| `test-writer` | Red-first tests from a spec/task; stops at red. |
| `debugger` | Root-cause in its own discardable context; returns cause + minimal fix. |
| `docs-agent` | (Copilot) keeps docs truthful and in sync with the code. |
| `reviewer` | (Codex) the `code-reviewer` equivalent for the Codex runtime — `.codex/agents/reviewer.toml`. |

### 📚 Engineering reference — `docs/` *(read on demand, never auto-loaded)*

| Read when you're… | Doc |
|---|---|
| Deciding what goes in AGENTS.md vs. a doc vs. a spec | [`context-engineering.md`](docs/context-engineering.md) |
| Setting up guides + sensors around the agent | [`harness-engineering.md`](docs/harness-engineering.md) |
| Cutting cost/latency without cutting the controls | [`token-efficiency.md`](docs/token-efficiency.md) |
| Choosing a model per phase | [`model-selection-and-token-optimization-in-sdd.md`](docs/model-selection-and-token-optimization-in-sdd.md) |
| Stopping agents writing slow code (N+1, per-row loops) | [`efficient-code-generation-and-performance-pitfalls.md`](docs/efficient-code-generation-and-performance-pitfalls.md) |
| Connecting MCP servers (and the 5–7 cap) | [`mcp.md`](docs/mcp.md) |
| Turning prose rules into enforced hooks | [`hooks.md`](docs/hooks.md) |

<details>
<summary>📂 <b>Full directory layout</b></summary>

```
<project-root>/
├── AGENTS.md                      # Always-loaded canonical instructions — keep short & specific
├── CLAUDE.md                      # Thin pointer → AGENTS.md
├── .mcp.json.example              # Curated MCP config — copy to .mcp.json, trim (docs/mcp.md)
├── mirror-skills.sh / .ps1        # Re-mirror canonical skills → .claude/.github/.codex after edits
│
├── .agents/skills/                # CANONICAL skills — mirror-skills mirrors → .claude/.github/.codex
│   ├── spec-driven-feature/       #   (edit here only; never hand-edit a mirror — ADR-0001)
│   ├── clarify/  ·  checklist/  ·  create-constitution/  ·  sync-agents-md/
│
├── .githooks/pre-commit / .ps1    # Secret scan · spec-ambiguity block · lint/test slot
│
├── .github/                       # Copilot: copilot-instructions.md, instructions/, skills/,
│   │                              #   agents/docs-agent.agent.md
│   └── workflows/agent-harness.yml#   Example CI feedback harness
├── .claude/                       # Claude Code: skills/ + agents/{code-reviewer,test-writer,debugger}
├── .codex/                        # Codex: skills/ + agents/reviewer.toml
│
├── memory/constitution.md         # Project-wide principles (rarely changes)
│
├── templates/                     # spec · plan · tasks · constitution · checklist
│   └── research · data-model · quickstart      # optional per-feature artifacts
│
├── specs/<NNN-feature>/           # spec.md · plan.md · tasks.md (+ optional research/data-model/…)
│   └── contracts/                 # this feature's API/event contracts
│
├── docs/                          # 5 engineering guides + mcp.md + hooks.md + glossary.md + adr/
├── src/                           # your source tree
└── tests/                         # contract · integration · unit · characterization
```

</details>

## 💡 Why it's structured this way

> [!IMPORTANT]
> **`AGENTS.md` is the single source of truth.** Every tool file (`CLAUDE.md`, `.github/copilot-instructions.md`) is a thin pointer to it. Update one file, not four. ([ADR-0001](docs/adr/0001-agents-md-single-source-of-truth.md))

- **Spec ≠ plan.** Mixing *what* and *how* makes agents anchor on implementation before requirements are stable.
- **Tasks are generated, not hand-written.** With a locked spec and reviewed plan, an agent derives `tasks.md` deterministically.
- **The constitution is short on purpose.** Only what's *always* true. Conditional rules go in `AGENTS.md`; feature rules go in specs.
- **Every artifact is a context unit.** Specs aren't auto-loaded — the agent pulls in only the one it needs. ([`context-engineering.md`](docs/context-engineering.md))

## Related: spec-kit

[GitHub spec-kit](https://github.com/github/spec-kit) is GitHub's toolkit for spec-driven development — a `specify` CLI with commands for constitution, specify, clarify, plan, tasks, and implement, plus integrations for many AI coding agents.

## 📖 Further reading

- [Distilled AI-Assisted Development Guidelines](https://medium.com/@sapbasu/distilled-ai-assisted-development-guidelines-351ac9ab0154) — the companion article
- [Harness engineering for coding agents](https://martinfowler.com/articles/harness-engineering.html) — Martin Fowler
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic
- [Agent READMEs: an empirical study of context files](https://arxiv.org/abs/2511.12884) — what helps vs. hurts
- [How to write a great AGENTS.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) — GitHub, 2,500+ repos
- [spec-kit](https://github.com/github/spec-kit) · [awesome-copilot](https://github.com/github/awesome-copilot)

---

<div align="center">

Licensed under [Apache 2.0](LICENSE) · Contributions welcome

</div>
