# Model Selection and Token Optimization in SDD

`AGENTS.md`'s **Model Routing** section tells an agent which model to use for
which phase. This document is the reasoning behind it: why phase-appropriate
routing matters more in spec-driven development than in ad-hoc coding, and how
to set it up.

The short version: **errors made early propagate; errors made late are
contained.** Spend your strongest (most expensive) model where a mistake would
contaminate everything downstream, and your cheapest model where a mistake is
local and instantly visible. Done well, this is both a quality decision and a
cost decision — reported routing savings run 40–85% with no visible quality
drop.

## Why routing matters more in SDD specifically

SDD is a pipeline: spec → plan → tasks → implementation. Each stage consumes
the previous one's output as ground truth. That structure has a sharp
asymmetry:

- A flaw in the **spec** (wrong requirement, missed edge case, ambiguous
  acceptance criterion) is inherited by the plan, every task, and every line of
  code. You may not notice until implementation or review, by which point
  fixing it means redoing all the stages below it.
- A flaw in a **routine implementation task** (a clumsy loop, a wrong import)
  is local, caught by a test or a linter in seconds, and fixed in place.

So the value of model quality is *not uniform across the pipeline*. The early,
divergence-defining stages are where a stronger model pays for itself many
times over; the late, convergent stages are where a cheaper model is fine
because the harness catches its misses cheaply.

## The routing policy

This mirrors the `AGENTS.md` template; fill the bracketed model names with your
actual tiers.

| Phase | Model tier | Why |
|---|---|---|
| **Specify** | Strongest available | The spec defines what "correct" even means. A subtle error here is invisible and propagates everywhere. Do not rely on auto-selection. |
| **Plan** | Strongest available | Architecture and approach decisions are expensive to reverse once tasks and code depend on them. |
| **Tasks** | Mid-tier (or auto) | Largely mechanical decomposition of an already-good plan. Errors are visible and local. |
| **Implement (routine)** | Mid-tier (or auto) | The plan constrains the space; tests catch regressions. |
| **Characterization tests on legacy** | Strongest available | Treat like Plan, not like ordinary test-writing: you are inferring the *true current behaviour* of code you don't understand, and a wrong assertion here gives false confidence to every later change. |
| **Quick edits / search / formatting / lint fixes** | Cheapest / fast tier | Local, instantly verifiable, high volume. Paying frontier prices here is pure waste. |
| **Code review / verification** | Different model or family than wrote the code | A model is a poor judge of its own blind spots; cross-model review catches what same-model review rubber-stamps. |

## The two-way cost asymmetry

It is tempting to read "use the strong model for Specify/Plan" as the only rule,
but the waste runs both directions:

- **Under-powering the early stages** is the classic, expensive mistake: a weak
  model's spec error costs you the whole feature.
- **Over-powering the late stages** is the quiet, recurring mistake: routing
  every lint fix and file rename to a frontier model. Individually cheap,
  collectively a large fraction of a bill, with zero quality benefit because
  the work is deterministic and verifiable.

A good routing setup avoids both. Complexity-based routers (sending each request
to the cheapest model that can handle it) formalize this; in practice, even a
hand-written per-phase policy like the table above captures most of the gain.

## How to actually route

- **Tool-native per-phase selection.** If your agent runtime lets you pick a
  model per skill, per agent, or per command, set Specify/Plan to the strong
  tier and routine work to mid/auto. This is the cleanest mechanism and the one
  the `AGENTS.md` Model Routing section assumes.
- **Subagents with pinned models.** Give the reviewer subagent a different
  model family than your implementer; give a cheap search subagent the fast
  tier. The `code-reviewer` agent files in this repo leave the model field for
  you to set deliberately.
- **A routing layer / router model.** For high request volumes, a dedicated
  complexity-based router (e.g. RouteLLM-style strong/weak routing) automates
  the dispatch and stays durable when the model lineup changes — routers
  trained on one strong/weak pair tend to hold up when the underlying models
  are swapped, which matters in a market where the lineup changes monthly.
- **If your tooling can't route per phase**, fall back to running Specify/Plan
  as separate, deliberate sessions on your strongest model, and everything else
  on the default — the asymmetry is worth that small friction.

## Token optimization is the same decision, seen from the cost side

Routing *is* token optimization: it is spending expensive tokens only where
they change the outcome. The complementary tactics — small always-loaded
context, scoped reads and tool output, subagents to quarantine noise, compaction
on long tasks — are in `docs/token-efficiency.md`. Together they answer the two
questions every call implicitly poses: *how many tokens, and at what price per
token.*

## See also

- `docs/token-efficiency.md` — the volume side of token spend.
- `docs/context-engineering.md` — why a smaller context is also a better one.
- `AGENTS.md` → Model Routing — the per-repo policy this doc justifies.

## References

- [LLM Model Routing in 2026: Cost-Quality Optimization](https://www.digitalapplied.com/blog/llm-model-routing-2026-cost-quality-optimization-engineering-guide)
- [Best AI Model for Coding Agents in 2026: A Routing Guide — Augment Code](https://www.augmentcode.com/guides/ai-model-routing-guide)
- [RouteLLM: Learning to Route LLMs with Preference Data (arXiv 2406.18665)](https://arxiv.org/html/2406.18665v4)
