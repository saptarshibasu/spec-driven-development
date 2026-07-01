# docs/

Deep-reference material — one file per topic, referenced *by name* from
`AGENTS.md` and the constitution rather than inlined, so the always-loaded
context stays small (see `context-engineering.md` for why).

## Reference guides

| File | What it covers |
|---|---|
| [`context-engineering.md`](context-engineering.md) | Deciding what the agent sees on every call: tiering instructions by load frequency, context rot, selective retrieval, compaction. The *why* behind this repo's structure. |
| [`harness-engineering.md`](harness-engineering.md) | Feedforward guides + feedback sensors around the agent; computational vs. inferential controls; mapping the SDD workflow onto a harness. |
| [`adaptive-workflow-and-extensions.md`](adaptive-workflow-and-extensions.md) | Right-sizing the pipeline via four workflow tracks, opt-in extension rule packs, and the per-feature decision log. The reasoning behind the routing step in `develop-feature`. |
| [`token-efficiency.md`](token-efficiency.md) | Practical tactics for the most correct work per token — scoped reads, subagents, closing feedback loops early. |
| [`model-selection-and-token-optimization-in-sdd.md`](model-selection-and-token-optimization-in-sdd.md) | Routing each SDD phase to the right model; the two-way cost asymmetry. The reasoning behind AGENTS.md's Model Routing section. |
| [`efficient-code-generation-and-performance-pitfalls.md`](efficient-code-generation-and-performance-pitfalls.md) | Why agents default to slow code (per-row loops, N+1) and what to put in AGENTS.md to stop it. Reasoning behind the Performance & Efficiency section. |
| [`mcp.md`](mcp.md) | Which MCP servers to connect (and the 5–7 cap), when to build your own, and security. Companion to `.mcp.json.example`. |
| [`hooks.md`](hooks.md) | Git hooks + agent-runtime hooks: turning prose rules into enforced, zero-token controls. Companion to `.githooks/pre-commit`. |
| [`guardrails.md`](guardrails.md) | Universal behavioral guardrails shared across all skills — the always-on rules every skill session inherits. |
| [`implementation-handoff.md`](implementation-handoff.md) | Rules for the agent that executes `tasks.md`: picking up an approved plan and implementing it safely. |

## Project reference

| File / dir | What it covers |
|---|---|
| [`glossary.md`](glossary.md) | Domain vocabulary, referenced from AGENTS.md's Domain Language section. |
| [`adr/`](adr/) | Architecture Decision Records. Use the `create-adr` skill to add new ones; check here before changing a cross-cutting pattern. |
| [`../.agents/extensions/`](../.agents/extensions/) | Opt-in rule packs (e.g. `security/baseline`) layered onto a feature on demand. Authoring format in its own `README.md`; loaded only when opted in. |

## How these are meant to be used

These docs are *not* loaded into every agent session — that would defeat the
token discipline they describe. They are pulled in on demand: `AGENTS.md` and
the constitution point at them by name, and an agent (or a human) reads the one
relevant to the task at hand. Keep it that way when you add a doc: put the
deep material here, and add a one-line by-name pointer wherever it's relevant.
