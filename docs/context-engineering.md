# Context Engineering

Context engineering is the practice of deliberately deciding what a coding
agent sees on every inference call — which instructions, which files, which
slice of history, which tool results — so the model spends its limited
attention on what actually matters. It is the discipline that sits underneath
everything else in this repository: the spec/plan/tasks split, the thin
pointer files, the glossary-by-reference, and the "every line must earn its
place" rule in `AGENTS.md` are all context-engineering decisions.

This document explains the reasoning so you can make new decisions the
templates didn't anticipate, rather than just following them.

## The core constraint: attention is finite, and it rots

A larger context window is not a larger *working memory*. Models have a finite
attention budget, and accuracy degrades non-uniformly as input grows — a
phenomenon now commonly called **context rot**. Performance drops even on
simple retrieval tasks once the window fills, and irrelevant "distractor"
content makes it worse, not merely neutral. The practical consequence: every
token you add has a cost even when it is correct, because it dilutes attention
on everything else.

This reframes the goal. You are not trying to *give the agent everything it
might need*. You are trying to give it **the smallest set of
high-signal tokens that lets it act correctly**, and nothing else.

The empirical record backs the caution. Studies of real agent context files
find that carefully human-written ones produce only modest task-success gains
(on the order of a few percent) and can *increase* step count and cost, while
machine-generated, kitchen-sink context files often **degrade** success
relative to no context file at all. A focused ~400-token instruction file
routinely outperforms a sprawling 4,000-token one. Bigger is not better; more
specific is better.

## The four levers

Anthropic's framing of context engineering is a useful checklist. On every
call you are managing four kinds of content:

1. **System / instructions** — `AGENTS.md`, the constitution, skill
   definitions. Always-loaded, so the most expensive per unit of value. This
   is where the "could the model already infer this?" test bites hardest.
2. **Retrieved knowledge** — the specific spec, the specific source files, the
   glossary entry, an ADR. Pulled in on demand for the task at hand.
3. **History** — prior turns and tool results accumulating in the window.
   The thing that rots first on long tasks.
4. **Tools** — tool definitions and their outputs. Verbose tool results are a
   silent context sink; a tool that returns 2,000 lines when 20 would do is a
   context-engineering bug.

The rest of this document is how the four levers map onto an SDD project.

## How this repo applies it

**Tier your instructions by load frequency.** The most important single idea.

| Tier | Where | Loaded | Rule |
|---|---|---|---|
| Always-true, every session | `memory/constitution.md`, `AGENTS.md` | Every call | Ruthlessly short. Every line must be unguessable from training. |
| Repo-specific, conditional | `docs/*.md`, `.github/instructions/*.instructions.md` | On demand / by path glob | Keep narrow; reference by name from AGENTS.md, don't inline. |
| Feature-specific | `specs/<NNN>/spec.md`, `plan.md`, `tasks.md` | Only when working that feature | Pull in explicitly; never auto-load all specs. |

The whole point of the thin-pointer files (`CLAUDE.md`,
`.github/copilot-instructions.md`) and of pointing at `docs/glossary.md`
*instead of inlining 50 terms* is to keep the always-loaded tier small. A 50-
term glossary inlined into AGENTS.md is 50 terms paid for on every call,
including the thousands of calls that touch none of them.

**Separate WHAT from HOW so each can be loaded alone.** A spec that contains no
tech detail can be read by a planning agent without dragging implementation
context along; a plan can be read without re-deriving the requirements. The
split is not bureaucracy — it is two independently loadable context units.

**Make retrieval explicit, not ambient.** Specs are deliberately *not*
auto-loaded into every prompt. The agent pulls in the one spec relevant to the
current task. This is selective retrieval: relevance metadata (the feature
number, the folder name) lets the right unit be fetched instead of everything
being blindly included.

**Treat tool output as context you are paying for.** Prefer tools and commands
that return scoped results. `grep` for the symbol rather than reading the whole
file; read the 30 lines you need with an offset rather than 2,000. A subagent
that does a noisy search and returns only its *conclusion* keeps the noise out
of the main window entirely — that is what the `Explore` / search agents are
for.

## Managing long-running tasks: compaction, notes, sub-agents

On a long implementation the window fills and rot sets in. Three complementary
techniques keep an agent effective past that point:

- **Compaction.** When the conversation nears the limit, summarize it and
  restart with the summary. Prefer *reversible* compaction — drop content the
  agent can re-fetch from the environment later (a file it can re-read) — over
  *lossy* summarization of reasoning, which is harder to recover. The
  `spec-driven-feature` skill's Phase 4 guidance ("if approaching a context
  limit, write a brief progress summary to a scratch file before stopping") is
  exactly this, done manually and durably.
- **Structured note-taking.** Persist decisions and progress to a file
  (`tasks.md` checkboxes, a scratch progress note) instead of relying on them
  staying in-window. The note survives a compaction or a fresh session.
- **Sub-agents.** Delegate a self-contained, context-heavy chunk (a broad
  search, a focused investigation) to a subagent with its own window; only its
  result returns to the parent. This is how you do a 200-file sweep without
  spending 200 files of the main agent's attention.

## A practical checklist

When something goes wrong, suspect context before suspecting the model:

- Is the always-loaded tier (`AGENTS.md` + constitution) under control, or has
  it accreted generic advice the model already knows?
- Did the agent get the *specific* spec/file it needed, or is it guessing
  because the relevant unit was never retrieved?
- Is irrelevant content (a whole file when 20 lines were needed, a verbose
  tool dump, a stale earlier turn) crowding the window?
- On a long task, has the agent compacted/checkpointed, or is it running on a
  rotting window?
- Could a subagent have absorbed the noisy part and returned only a conclusion?

## See also

- `docs/token-efficiency.md` — the cost side of the same coin, with concrete
  tactics for spending fewer tokens per unit of work.
- `docs/harness-engineering.md` — guides and sensors that keep the agent on
  track; context engineering supplies the *guides* half.
- `docs/model-selection-and-token-optimization-in-sdd.md` — routing each SDD
  phase to the right model.
- `docs/guardrails.md` — the canonical universal guardrail wording embedded in
  every skill; identical text across prompts is a direct cache-efficiency win.

## References

- [Effective context engineering for AI agents — Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Context Rot in AI Coding Agents — MindStudio](https://www.mindstudio.ai/blog/context-rot-ai-coding-agents-how-to-prevent)
- [Context Engineering: A Practical Guide — Sourcegraph](https://sourcegraph.com/blog/context-engineering)
- [Agent READMEs: An Empirical Study of Context Files for Agentic Coding (arXiv 2511.12884)](https://arxiv.org/abs/2511.12884)
- [On the Impact of AGENTS.md Files on the Efficiency of AI Coding Agents (arXiv 2601.20404)](https://arxiv.org/html/2601.20404v2)
