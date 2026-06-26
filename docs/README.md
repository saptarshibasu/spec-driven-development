# docs/

Deep-reference material — one file per topic, referenced *by name* from
`AGENTS.md` and the constitution rather than inlined, so the always-loaded
context stays small (see `context-engineering.md` for why).

## Reference guides

| File | What it covers |
|---|---|
| [`context-engineering.md`](context-engineering.md) | Deciding what the agent sees on every call: tiering instructions by load frequency, context rot, selective retrieval, compaction. The *why* behind this repo's structure. |
| [`harness-engineering.md`](harness-engineering.md) | Feedforward guides + feedback sensors around the agent; computational vs. inferential controls; mapping the SDD workflow onto a harness. |
| [`token-efficiency.md`](token-efficiency.md) | Practical tactics for the most correct work per token — scoped reads, subagents, closing feedback loops early. |
| [`model-selection-and-token-optimization-in-sdd.md`](model-selection-and-token-optimization-in-sdd.md) | Routing each SDD phase to the right model; the two-way cost asymmetry. The reasoning behind AGENTS.md's Model Routing section. |
| [`efficient-code-generation-and-performance-pitfalls.md`](efficient-code-generation-and-performance-pitfalls.md) | Why agents default to slow code (per-row loops, N+1) and what to put in AGENTS.md to stop it. Reasoning behind the Performance & Efficiency section. |

## Project reference

| File / dir | What it covers |
|---|---|
| [`glossary.md`](glossary.md) | Domain vocabulary, referenced from AGENTS.md's Domain Language section. |
| [`adr/`](adr/) | Architecture Decision Records. Copy [`adr/0000-template.md`](adr/0000-template.md) for new decisions; check here before changing a cross-cutting pattern. |

## How these are meant to be used

These docs are *not* loaded into every agent session — that would defeat the
token discipline they describe. They are pulled in on demand: `AGENTS.md` and
the constitution point at them by name, and an agent (or a human) reads the one
relevant to the task at hand. Keep it that way when you add a doc: put the
deep material here, and add a one-line by-name pointer wherever it's relevant.
