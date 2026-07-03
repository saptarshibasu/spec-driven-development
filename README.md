<div align="center">

# 🧭 Spec-Driven Development — Starter Kit

**A lightweight starter kit for spec-driven development with AI coding agents.**
No install, no CLI — just files you adapt to your stack. Specs before code, humans in the loop, and a workflow that scales to the size of the work.

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Method](https://img.shields.io/badge/method-Spec--Driven%20Development-6f42c1.svg)](#-the-workflow)
[![Agents](https://img.shields.io/badge/agents-Claude%20·%20Copilot%20·%20Codex-2ea44f.svg)](#-whats-inside)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#)

</div>

---

Clone it, fill in the placeholders, and you have an opinionated structure for **spec-driven development (SDD)**: a constitution, gated spec→plan→tasks templates, skills and subagents, hooks, CI, and a `docs/` knowledge base on the engineering that makes agents actually productive.


## 🔄 The workflow

Each feature flows through gated phases. **An agent never advances a gate without explicit human approval.**

```mermaid
%%{init: {'flowchart': {'nodeSpacing': 50, 'rankSpacing': 45, 'subGraphTitleMargin': {'top': 10, 'bottom': 10}}, 'themeVariables': {'fontSize': '16px'}}}%%
flowchart TD
    subgraph CTX["🌐 Always-on context<br/>governs every phase"]
        direction LR
        K["📜 Constitution<br/><i>always-true principles</i>"]:::gov
        AGT["📋 AGENTS.md<br/><i>conventions<br/>commands · structure</i>"]:::gov
        K ~~~ AGT
    end
    RT["🧭 Route<br/><b>pick a track</b><br/>A trivial · B simple<br/>C moderate · D complex<br/>+ opt-in extensions"]:::gate
    S["1 · Specify · spec.md<br/><i>✍️ specifier agent</i><br/><b>WHAT & WHY</b> — no tech"]:::draft
    CL["Clarify Spec<br/><i>optional · answer open questions</i>"]:::opt
    CK["Check Spec<br/><i>optional · is the spec solid?</i>"]:::opt
    P["2 · Plan · plan.md<br/><i>✍️ planner agent</i><br/><b>HOW</b> — stack & design<br/><i>C/D only</i>"]:::draft
    T["3 · Tasks · tasks.md<br/><i>✍️ task-decomposer agent</i><br/><b>ordered, tests-first</b>"]:::draft
    AN["Artifact Analyzer<br/><i>B light · C/D default · skippable up front<br/>do spec, plan & tasks agree?</i>"]:::gate
    TW["🧪 test-writer<br/><i>B/C/D default · skippable<br/>write & confirm failing tests</i>"]:::twriter
    I["⚙️ implementor agent<br/><i>red → green → refactor<br/>one story at a time</i>"]:::impl
    R["🔍 code-reviewer<br/><i>spec · constitution · security</i>"]:::reviewer
    DB["🐛 debugger<br/><i>root cause + minimal fix</i>"]:::debug
    DL["📒 decision-log.md<br/><i>committed audit trail —<br/>every gate approval appended</i>"]:::audit

    RT -->|"✋ A · trivial — direct change,<br/>then review"| R
    RT -->|✋ B / C / D| S
    S -->|✋ approve| P -->|✋ approve| T -->|✋ approve| AN -->|✋ ready| TW -->|✋ red confirmed| I -->|✋ green| R
    R -->|next story| TW
    R -->|"✋ Blockers · user approves round 1<br/>develop-feature runs the loop"| DB
    DB -. "fixes applied → re-check<br/>repeats until clean or stuck" .-> R
    I -. "stuck red · escalation<br/>via develop-feature" .-> DB
    S -. B · skips plan .-> T
    S -. optional sharpen .-> CL
    CL -.-> CK
    CK -.-> S
    AN -. "any finding: back to owning phase" .-> S
    AN -.-> P
    AN -.-> T
    RT -.-> DL

    classDef gov fill:#f3ecfb,color:#4c2889,stroke:#6f42c1
    classDef draft fill:#e0f2f3,color:#154d54,stroke:#1f6f78
    classDef gate fill:#f7f0e0,color:#54421c,stroke:#7a5f28
    classDef opt fill:#f3efe0,color:#4a3a18,stroke:#6a5222,font-style:italic
    classDef impl fill:#dafbe1,color:#0f5323,stroke:#1a7f37
    classDef twriter fill:#ddf4ff,color:#1e4464,stroke:#2a5e88
    classDef reviewer fill:#ffebe9,color:#621616,stroke:#8b2020
    classDef debug fill:#f7ede0,color:#56361e,stroke:#7a4e2a
    classDef audit fill:#eaeef2,color:#24292f,stroke:#6e7781,font-style:italic
```

Specs are pure **what/why**; the **how** lives in the plan; tasks are *generated* from both.

**What you actually run, and when:**

1. **Setup (once per project)** — run `init-project` to scan the codebase and generate both `AGENTS.md` and `memory/constitution.md` with approval gates, then `git config core.hooksPath .githooks` to arm the pre-commit sensor.
2. **Start a feature** — run `develop-feature`. It first **right-sizes the work**: it proposes a workflow track (A · trivial / B · simple / C · moderate / D · complex) and scans `.agents/extensions/` for opt-in rule packs (e.g. a security baseline), and waits for you to approve the route. Then it scaffolds `specs/<NNN>/` (calling `start-feature.sh` on macOS/Linux or `start-feature.ps1` on Windows) and delegates drafting `spec.md` (Specify) to the `specifier` agent, marking open questions as `[NEEDS CLARIFICATION]`. Trivial changes route to Track A and skip straight to implementation.
3. **(Optional) Sharpen the spec at the approval gate** — `develop-feature` pauses after the draft and waits for you. If it left `[NEEDS CLARIFICATION]` markers or the spec needs tightening, run `clarify-spec` and/or `check-spec` *here*; otherwise just answer any open questions inline. Neither is a required step. **You approve the spec.**
4. **Plan, then tasks — same run** — once you approve, the skill continues *on its own*, delegating `plan.md` to the `planner` agent, pausing for approval, then delegating `tasks.md` to the `task-decomposer` agent. You don't relaunch it; each "stop" is a pause-for-approval, not an exit.
5. **Artifact Analyzer (gate, Tracks C/D — default-on, skippable)** — before implementation, the skill runs `artifact-analyzer`: a **non-destructive** cross-artifact check that every requirement maps to a task and that spec, plan, and tasks don't contradict each other. It *reports*, never rewrites — findings at **any severity** loop back to **whichever phase owns the fix** (spec, plan, *or* tasks), then re-run; a clean verdict clears the gate. It runs by default on C/D but you can explicitly skip it (the skip is logged in `decision-log.md`, like skipping review). Skipped on Track A; a light spec↔tasks pass on Track B.
Steps 6–8 below repeat **for each user story** in `tasks.md`'s priority order, not once for the whole feature (Tracks B/C/D — each is default-on and skippable per story):

6. **Write failing tests (red)** — after Artifact Analyzer clears, the `test-writer` agent writes that story's tests from the spec's acceptance criteria, runs them, and confirms each fails **for the right reason** (assertion failure or missing implementation — not an import error or typo). Errors ≠ valid red; the agent fixes those before reporting. For a Track D brownfield story, the skill **offers** a characterization pass first (pinning *current* behaviour) — ask-first, never auto-run; your yes/no is logged in `decision-log.md`. The skip (if the user chooses) is recorded in `decision-log.md`.
7. **Implement (green)** — once the story's tests are confirmed red, the `implementor` agent takes over: it writes the smallest code that makes each test pass, task by task, runs the full story-level suite before calling a task done, then refactors with tests kept green. It never writes or weakens a test — an apparently-wrong test is flagged back to you, not edited. When a failure's root cause isn't obvious after one focused look, it stops and returns an escalation request; `develop-feature` runs the `debugger` round and re-invokes the implementor (sub-agents can't invoke each other).
8. **Review & commit (loop until clean)** — the `code-reviewer` agent checks that story's diff against spec, constitution, and conventions, then groups findings by severity. If there are Blockers, `develop-feature` presents all of them and — on your approval for the first round — runs the loop: it invokes the `debugger` on every open Blocker, then re-invokes `code-reviewer` for a re-check scoped to the touched files. This repeats round after round until every Blocker is resolved (`approve`/`approve-with-nits`) or a Blocker stops making progress across two rounds, at which point the loop stops and just that item is escalated to you. On commit, `.githooks/pre-commit` blocks secrets, unresolved markers, tool-pointer files that grow past a pointer, and runs your lint/tests. Once a story is reviewed and committed, the next story starts back at step 6.

Steps 2–8 repeat per feature (and steps 6–8 repeat per story within a feature); step 1 is one-time (re-run `sync-agents-md` whenever the project drifts).


## 🛰️ The harness model

The kit is built as a **harness** ([Martin Fowler's term](https://martinfowler.com/articles/harness-engineering.html)): *guides* that steer the agent before it acts, and *sensors* that catch it after. Both halves ship — you wire the sensors to your stack.

```mermaid
%%{init: {'flowchart': {'nodeSpacing': 15, 'rankSpacing': 18, 'subGraphTitleMargin': {'top': 8, 'bottom': 10}}}}%%
flowchart TB
    subgraph FF["🧭 Feedforward · guides (before)"]
        direction LR
        A["AGENTS.md + constitution<br/><i>always-on context</i>"]
        SK["skills: develop-feature (tracks),<br/><i>clarify-spec, check-spec, create-adr</i>"]
        TW["🧪 test-writer agent<br/><i>red tests before implementation · B/C/D</i>"]
        TPL["templates/<br/><i>spec · plan · tasks</i>"]
    end
    subgraph FB["🛰️ Feedback · sensors (after)"]
        direction LR
        TS["✅ tests · unit · integration · contract<br/><i>your stack — you provide</i>"]:::byo
        SA["🔎 linters · type-checkers<br/>SAST · dependency/SCA (vuln) scan<br/><i>your stack — you provide</i>"]:::byo
        HK[".githooks/pre-commit<br/><i>secret scan (shipped) + your lint/tests · local</i>"]
        CI["CI · agent-harness.yml<br/><i>runs them on every PR · slot provided</i>"]
        AG["🧠 code-reviewer agent<br/><i>inferential backstop · + security</i>"]
        EX["🧩 opt-in extensions<br/><i>blocking rule packs · e.g. SEC-*</i>"]
    end
    FF ==> AGENT(("🤖 coding<br/>agent"))
    AGENT ==> FB
    AGENT ==>|produces| CODE["💻 code · diff<br/><i>output of implementation</i>"]:::out
    FB -. self-correct .-> AGENT
    AGENT -. logs decisions / approvals .-> DL2["📒 decision-log.md<br/><i>committed audit trail</i>"]:::cont

    classDef ff fill:#ddf4ff,stroke:#0969da,color:#0a3069
    classDef fb fill:#ffebe9,stroke:#cf222e,color:#6e0a1e
    classDef cont fill:#eaeef2,stroke:#6e7781,color:#24292f
    classDef byo fill:#fff8e6,stroke:#bf8700,color:#5c4400,stroke-dasharray:4 3
    classDef out fill:#dafbe1,stroke:#1a7f37,color:#0f5323
    class FF ff
    class FB fb
```


## 🚀 Quickstart

```bash
git clone https://github.com/saptarshibasu/spec-driven-development.git my-project-sdd
cd my-project-sdd
```

A fresh clone already carries every directory, pointer, stub, and mirror —
there is no scaffolding step to run. (If you later edit or add a **skill** under
`.agents/skills/`, re-mirror it with `bash mirror-skills.sh` / `pwsh ./mirror-skills.ps1`;
if you edit or add an **agent** under `.agents/agents/`, re-generate the per-tool
copies with `bash mirror-agents.sh` / `pwsh ./mirror-agents.ps1`.)

Then, in order:

1. **Initialize the project** — run the `init-project` skill. It scans your codebase and generates both `AGENTS.md` (from `templates/agents.template.md`) and `memory/constitution.md` (from `templates/constitution.template.md`) with explicit approval gates before writing either file.
2. **Enable the hook** — `git config core.hooksPath .githooks`. (On Windows, Git runs the POSIX `pre-commit` via Git Bash; a native `pre-commit.ps1` is also provided.)
3. **Start a feature** — *"start a new feature: &lt;description&gt;"* (the `develop-feature` skill).

## 📦 What's inside

### 🛠️ Skills — workflow commands *(canonical in `.agents/skills/`, mirrored to every tool)*

| Skill | When you run it | What it does |
|---|---|---|
| `init-project` | Once, at setup | Scans the codebase and generates both `AGENTS.md` and `memory/constitution.md` from their templates, with approval gates before writing either file. |
| `amend-constitution` | To amend the constitution | Updates `memory/constitution.md` section by section; use after `init-project` when principles need revisiting. |
| `sync-agents-md` | To re-sync after drift | Re-fills `AGENTS.md` from the actual repo when the project has changed significantly. |
| `create-adr` | To record an architecture decision | Finds the next ADR number, fills the template from your input, and writes `docs/adr/<NNNN-slug>.md` with approval before writing. |
| `develop-feature` | Start of every feature | Proposes a workflow track (right-sizes depth) + scans opt-in extensions, then scaffolds `specs/<NNN>/` (via `start-feature.sh` / `.ps1`) and orchestrates Specify → Plan → Tasks → Analyze → (Tests red → Implement green → Review, per story) with approval gates — each phase delegated to a dedicated agent (`specifier` / `planner` / `task-decomposer` / `artifact-analyzer` / `test-writer` / `implementor` / `code-reviewer`), each in its own context and model tier; `debugger` rounds on implementation failures and review Blockers are run by the skill itself, since sub-agents can't invoke each other. |
| `clarify-spec` | After the spec draft | Surfaces spec ambiguities, asks a few targeted questions, writes answers back. |
| `check-spec` | Before approving the spec | "Unit tests for the requirements" — complete, clear, consistent, measurable? |

### 🤖 Agents — the sensor half *(canonical in `.agents/agents/`, generated into every tool)*

Defined once as Markdown in `.agents/agents/`; `mirror-agents` emits each tool's
native format — Claude `.md`, Copilot `.agent.md`, Codex `.toml`.

| Agent | Role |
|---|---|
| `specifier` | Drafts `spec.md` (Specify phase, opus model). Investigates the codebase read-only, searches broadly before treating a capability as missing, applies No-guessing (`[NEEDS CLARIFICATION]`), runs the Spec Completeness Checklist itself, writes the file. Never seeks approval — that's `develop-feature`'s gate. |
| `planner` | Drafts `plan.md` (Plan phase, opus model). Reads the approved spec, runs the three constitution gates (Simplicity, Anti-abstraction, Integration-first) with stated reasoning, checks opted-in extension compliance by rule ID. |
| `task-decomposer` | Drafts `tasks.md` (Tasks phase, mid-tier/sonnet model). Mechanical decomposition of an approved spec + plan into Setup → Foundational → per-story (tests-first, `[P]`-marked, `[US#]`-labelled) → Polish. |
| `artifact-analyzer` | Last guide-side gate before implementation (opus model). Cross-checks spec ↔ plan ↔ tasks for coverage gaps, contradictions, orphan tasks, test-first integrity, and constitution violations. Reports findings routed to the owning phase; never edits artifacts. |
| `test-writer` | Invoked after `artifact-analyzer` clears; writes that story's tests from acceptance criteria, runs them, and confirms each fails for the right reason before implementation begins. Every test carries a docstring naming its acceptance-criterion ID and why it matters. Also writes characterization tests for brownfield areas (Track D) — ask-first: only when the human accepts the offer, never automatically. |
| `implementor` | Drafts the code (Implement phase, mid-tier/sonnet model). Searches broadly before assuming code doesn't exist, takes a story's confirmed-red tests and the approved plan/tasks, writes the smallest code to turn each green, refactors with tests kept green, never weakens a test, and returns a `debugger` escalation request on an unclear failure (the orchestrator runs the round). Reads/appends `learnings.md`; may propose (never write) an `AGENTS.md` correction. |
| `code-reviewer` | Inferential review vs. spec, constitution, conventions, and baseline security — including whether each test carries its acceptance-criterion docstring. Completes the full review, then returns all Blockers as a numbered list; `develop-feature` runs the review↔debugger loop (user approval before round 1) and re-invokes the reviewer for a re-check scoped to each round's touched files, until every Blocker is resolved or one stalls for two rounds and is escalated to the human. Read-only. |
| `debugger` | Root-cause in its own discardable context; returns cause + minimal fix. Invoked by the orchestrator — on an implementor's escalation request, or on a reviewer's batched Blockers. Reads/appends `learnings.md`; may propose (never write) an `AGENTS.md` correction. |
| `docs-writer` | Keeps docs truthful and in sync with the code. |

### 📒 Decision log

Every gate approval — and every explicit skip — is appended to `specs/<NNN>/decision-log.md` as a committed audit trail. The log records who approved what, and when; skipped gates are noted alongside the reason. This makes the reasoning behind each feature permanently inspectable.

Alongside it, `specs/<NNN>/learnings.md` is an **ungated** append-only scratchpad — no Status, no approval, no decision-log row. `implementor` and `debugger` read it before a story and append discoveries (a wrong-turn command, a component that lived somewhere the plan didn't expect) as they go, so a fresh-context re-invocation on the next story — or a resumed session — doesn't have to re-learn it.

### 🧩 Extensions — opt-in rule packs *(canonical in `.agents/extensions/`, loaded on demand)*

Blocking rule packs you layer onto a feature only when it needs them — so
constraints that don't belong in the always-loaded `AGENTS.md` or constitution
still get enforced. The `develop-feature` skill scans the packs' tiny
opt-in prompts at feature start; a pack's full rules load only if you opt in, and
the `code-reviewer` agent then enforces them by rule ID.

| Pack | Opt in when | What it enforces |
|---|---|---|
| `security/baseline` | The feature touches auth, secrets, user data, external input, files, or network | `SEC-01`…`SEC-07`: input validation, authz, secret handling, data protection, output encoding, dependency hygiene, secure failure (directional reference — customise to your threat model). |

Add your own under `.agents/extensions/<category>/<pack>/` — format in
[`.agents/extensions/README.md`](.agents/extensions/README.md). Adapted from AWS Labs' AI-DLC (MIT-0).

#
<details>
<summary>📂 <b>Full directory layout</b></summary>

```
<project-root>/
├── AGENTS.md              # generated by init-project; keep short & specific
├── CLAUDE.md              # pointer → AGENTS.md
├── .mcp.json.example      # copy to .mcp.json; trim to 5–7 servers
│
├── .agents/               # canonical sources — edit here only (ADR-0001)
│   ├── skills/            # develop-feature · clarify-spec · check-spec
│   │                      #   init-project · amend-constitution · sync-agents-md · create-adr
│   ├── agents/            # specifier · planner · task-decomposer · artifact-analyzer
│   │                      #   test-writer · implementor · code-reviewer · debugger · docs-writer
│   └── extensions/        # opt-in rule packs (e.g. security/baseline)
│
├── .claude/               # Claude Code: skills/ · agents/*.md (generated)
├── .github/               # Copilot: skills/ · agents/*.agent.md (generated)
│   └── workflows/
│       └── agent-harness.yml  # CI feedback harness
├── .codex/                # Codex: skills/ · agents/*.toml (generated)
│
├── .githooks/
│   ├── pre-commit         # secret scan · ambiguity block · thin-pointer guard · lint/test slot
│   └── pre-commit.ps1
│
├── memory/
│   └── constitution.md    # project-wide principles; governs every phase
│
├── templates/             # spec · plan · tasks · agents · constitution
│                          #   decision-log · learnings · checklist · research · data-model · quickstart
├── specs/
│   └── <NNN-feature>/     # spec.md · plan.md · tasks.md · decision-log.md · learnings.md
│       └── contracts/     # API/event contracts
│
├── docs/
│   └── adr/               # architecture decision records (created by create-adr skill)
│
├── src/                   # your source tree
├── tests/                 # contract/ · integration/ · unit/ · characterization/
│
├── mirror-skills.sh/.ps1  # re-mirror .agents/skills/ → tool dirs after edits
└── mirror-agents.sh/.ps1  # re-generate .agents/agents/ → per-tool formats
```

</details>

## 🧱 Principles

These aren't advice buried in a doc — they're encoded in the constitution and `AGENTS.md` templates, then enforced by the gates, hooks, and CI. You ratify them once and every agent session inherits them.

> [!IMPORTANT]
> **`AGENTS.md` is the single source of truth.** Every tool file (`CLAUDE.md`, `.github/copilot-instructions.md`) is a thin pointer to it. Update one file, not four. The constitution is short on purpose — only what's *always* true. Conditional rules go in `AGENTS.md`; feature rules go in specs.

**Design-first — spec before code.** Every feature starts as a `spec.md` (*what & why*), then `plan.md` (*how*), then a generated `tasks.md`. No implementation until requirements are stable and approved. Spec ≠ plan — mixing *what* and *how* makes agents anchor on implementation before requirements are stable. Tasks are generated from a locked spec and reviewed plan, not hand-written. A spec that survives a framework swap unchanged was written correctly.

**Test-Driven Development is non-negotiable.** Write the test, watch it fail for the right reason, then implement — Red → Green → Refactor, every time. Never delete or weaken a failing test to make the suite pass. The `test-writer` agent writes tests from the spec before implementation begins and stops at red; it never writes implementation code.

**Characterization tests for brownfield.** Before changing any untested legacy behaviour, write tests that pin *current* behaviour first — so modifications are deliberate, not accidental. Brownfield areas are flagged in `AGENTS.md` and planned with the strongest model. In the workflow this is ask-first: `develop-feature` offers the characterization pass per story and logs your decision — it never runs automatically.

**Cross-artifact consistency before implementation.** The `artifact-analyzer` gate (default-on for Tracks C/D, optional light pass on B) cross-checks spec, plan, and tasks as a set before a single line of code is written: every requirement maps to at least one task, no contradictions exist between artifacts, no orphan or duplicate tasks. It reports and routes blockers back to whichever phase owns the fix; it never rewrites artifacts itself. A clean verdict is the green light for implementation.

**Separate agents for separate concerns — each with its own context and model.** The `implementor` agent turns red tests green, one story at a time, in its own fresh context so one story's review feedback never bleeds into the next story's implementation; the `specifier` / `planner` / `task-decomposer` each draft one artifact in their own fresh context, so revising the spec never drags that back-and-forth into the plan or the tasks that follow; the `test-writer` writes tests in its own discardable context so test intent is never contaminated by implementation choices; the `debugger` isolates root cause in a throwaway context and returns only the minimal fix; the `code-reviewer` is read-only and checks the diff against spec, constitution, and conventions, with `develop-feature` looping it against `debugger` until every Blocker clears; the `docs-writer` keeps documentation truthful without touching code. Each agent gets only the context its role needs.

**Roles and model tiers — including model family.** Don't assume every agent should use the same model family as the coding agent. Different families have different strengths: a reasoning-specialist model (e.g. an o-series or thinking model) may outperform a general model for the `debugger` (root-cause analysis in unfamiliar code) and for `develop-feature` on Tracks C/D (deep requirement and design reasoning); a model with strong long-context fidelity suits `code-reviewer` and `docs-writer`; a lighter, faster model is sufficient for `task-decomposer` and routine `implementor` work. Within a family, use the lightest tier that can do the job reliably. Configure the model — family and tier — in each agent's definition file (the `model:` frontmatter in `.agents/agents/*.md`) so it's enforced at invocation, not left to the calling session to decide.

**Guides before, sensors after.** The harness has two halves: feedforward guides (AGENTS.md, constitution, specs, skills) that steer the agent before it acts, and feedback sensors (tests, linters, hooks, CI, code-reviewer) that catch it after.

**Right-size the workflow.** Not every change needs a full spec → plan → tasks pipeline. Track A (trivial) goes straight to implementation; Track B (simple patch) skips the plan; Tracks C/D get the full pipeline plus the artifact-analyzer gate. Match depth to risk.

**Opt-in over always-on.** Constraints that don't apply to every feature (e.g. security rules for features touching auth or user data) live in opt-in extensions, not in the always-loaded `AGENTS.md`. Load them only when needed, keep the base context lean.

**Context is a budget, not a junk drawer.** Every line in `AGENTS.md` must be something the agent cannot infer from training. Generic advice wastes tokens and can hurt performance. Prefer deleting a section to filling it with filler. Every artifact is a context unit — specs aren't auto-loaded; the agent pulls in only the one it needs. Where detail is needed, link to a doc rather than inlining it — the agent fetches it only when the task requires it.

**KV caching — put stable context first.** Inference APIs cache the prefix of the prompt. Structure your context so stable, rarely-changing content (constitution, AGENTS.md, system instructions) comes before dynamic content (the current task, spec excerpt). Maximising cache hits cuts latency and cost significantly on repeated agent calls within a session.

**Caveman prompts for non-negotiable rules.** Subtle prose hints are easy for a model to rationalize away. For rules that must hold without exception — never delete a failing test, never fabricate a method signature, always write the test before the implementation — state them bluntly and repeat them at the point of action. Specificity and repetition beat elegant prose when correctness is non-negotiable.

**Multi-repo — resolve, never guess.** When a dependency's source isn't visible in this repo, resolve it before writing code against it (sibling checkout → source jar → decompile → stop and ask) rather than fabricating a class, field, or method signature you can't see.

**MCP servers: fewer is better.** Each connected MCP server adds to every session's context overhead. Cap at 5–7; remove any server the project doesn't actively use.

**Hooks over prose.** A git hook that blocks a bad commit is more reliable than a rule that asks the agent to remember. Wire your highest-value rules into `.githooks/pre-commit` or CI so they're enforced mechanically, not by trust.

**`.agents/` is the canonical source — never edit the generated copies.** Skills live in `.agents/skills/` and agents in `.agents/agents/`; the per-tool files (`.claude/`, `.github/`, `.codex/`) are generated outputs. Edit the source, then run `mirror-skills.sh` / `mirror-agents.sh` (or the `.ps1` equivalents on Windows) to propagate changes. Editing a generated copy directly means the next mirror run silently overwrites it.

**Resilient by default.** Feature progress is never lost — each document's `Status` header records what's been approved, and re-invoking `develop-feature` resumes from the first unapproved phase. A kill mid-phase leaves the document in `Draft`, so recovery is automatic at the phase level.

**Composable — skills work standalone.** You don't have to enter at step 1. Run `check-spec` against any spec, the `artifact-analyzer` agent against an existing spec + plan + tasks, or `clarify-spec` at any time. The kit works as a full end-to-end workflow or as individual tools dropped into an existing process.

## 📖 Further reading

- [Distilled AI-Assisted Development Guidelines](https://medium.com/@sapbasu/distilled-ai-assisted-development-guidelines-351ac9ab0154) — the companion article
- [Harness engineering for coding agents](https://martinfowler.com/articles/harness-engineering.html) — Martin Fowler
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic
