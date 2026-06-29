# Token Efficiency

Tokens are the agent's budget for *both* what it reads and what it writes, and
they map directly to latency and cost. Token efficiency is not penny-pinching —
past a point, fewer tokens means *better* output, because a smaller, cleaner
context is one the model reasons over more accurately (see
`docs/context-engineering.md` on context rot). The goal is the most correct
work per token, not the fewest tokens for their own sake.

This document is the practical, tactic-level companion to the conceptual
context-engineering doc.

## Where tokens actually go

In a typical SDD session, in rough order of spend:

1. **Always-loaded instructions** — `AGENTS.md` + constitution, paid on *every*
   call. A 4,000-token AGENTS.md is 4,000 tokens × thousands of calls.
2. **File reads** — whole files read when a slice would do.
3. **Tool output** — verbose command results, full directory dumps, noisy logs.
4. **Accumulated history** — every prior turn and tool result still in-window.
5. **Re-work** — the most wasteful of all: tokens spent redoing work because an
   error wasn't caught early, or because the agent guessed instead of looking.

The biggest savings come from the top and bottom of that list, not the middle.

## Tactics, highest-leverage first

**Keep the always-loaded tier ruthlessly small.** This is the single highest-
return lever because it multiplies across every call. Apply the AGENTS.md test
literally: if a line would be true of any repo ("write clean code," "follow
best practices"), delete it — it costs tokens every session and trains the
agent to skim the rest. Move conditional rules to path-scoped instruction files
or `docs/`; reference the glossary instead of inlining it.

**Keep the always-loaded prefix *stable*, not just small, so it gets cached.**
Small is only half the lever. Most model APIs (and the agent runtimes built on
them) serve an unchanged prompt prefix from cache at a steep discount — often
around 90% off input on the cached span. `AGENTS.md` + constitution are that
prefix on *every* call, so churn there is doubly expensive: you pay full price
for the edited tokens *and* invalidate the cache for everything after the edit.
So hold the stable tier stable within a session, batch instruction changes
instead of tweaking between turns, and keep fast-changing material out of the
always-loaded header. The whole game is: *cache the stable stuff, scope the
changing stuff.*

**Don't guess — but don't over-read either.** Guessing causes re-work (expensive);
reading the entire repo "to be safe" causes context rot (also expensive). The
middle path: locate precisely (grep/glob for the symbol), then read only the
relevant span (use line offsets). Resolve cross-repo types from source rather
than inventing them *and* rather than reading the whole dependency.

**Spend the planning tokens to save the implementation tokens.** A well-formed
spec and plan are the cheapest tokens in the whole lifecycle, because they
prevent the most expensive kind of waste: building the wrong thing and redoing
it. This is why SDD front-loads thinking. Conversely, do not let planning
sprawl — a plan that re-derives the spec is paying twice.

**Make tool output scoped.** Prefer commands that return what you need:
`grep -n` over reading a file; `--quiet`/summary flags over full logs; a single
failing test over the whole suite while iterating. A tool that dumps 2,000
lines when 20 would do is a token leak you pay on every invocation.

**Turn off tools and MCP servers you aren't using on this project.** Every
connected tool's schema is sent on *every* message, used or not — the same
per-call tax as `AGENTS.md`, paid in tool definitions. `docs/mcp.md`'s 5–7-
server cap is the standing version of this rule; the per-session version is
just as real: if a project never touches the browser, turn the browser server
off for it rather than shipping its schema on every turn.

**Use subagents to quarantine noisy work.** A broad search or a deep
investigation can burn enormous context. Delegate it to a subagent with its own
window; only the conclusion returns to the main thread. The search costs the
same tokens, but they don't pollute — or stay resident in — the main agent's
window for the rest of the task.

**Compact and checkpoint long tasks.** On a long run, summarize and restart, or
write progress to a file and continue fresh, before the window rots. Re-work
caused by a confused, overfull window is far more expensive than the summary.

**Reset the session when the task changes.** History rides along on every
subsequent call, so an old, unrelated thread is pure carry cost — and a
context-rot risk on top of it. Starting a fresh chat on a task switch is the
cheap, blunt version of the compaction tactic above: same goal, no summary
needed when there's nothing worth carrying forward.

**Don't pin reasoning effort to maximum by default.** Reasoning/thinking budget
is output tokens you pay for. Low or medium effort handles routine, well-scoped
work; reserve high effort for genuinely ambiguous tasks where the extra
deliberation actually changes the answer. Maxing it on every turn is the
output-side twin of reading the whole repo "to be safe" — cost with no payoff
when the work is already well-constrained.

**Close feedback loops early.** Every error a linter or test catches *before*
the agent moves on is a re-prompt you don't pay for later. A tight harness (see
`docs/harness-engineering.md`) is also a token-efficiency measure: cheap
deterministic sensors prevent expensive inferential redo.

**Route the model to the work.** Don't pay frontier-model prices for lint fixes
or file renames, and don't let a cheap model make spec/architecture decisions
whose errors propagate downstream. Phase-appropriate routing is covered in
`docs/model-selection-and-token-optimization-in-sdd.md`; reported savings from
disciplined routing run from roughly 40% to over 70% with no quality drop.
Where your platform offers an auto-router (it picks the best-fit model per
turn), prefer it for routine work — some apply a token-multiplier discount on
top of the routing win, so it can be cheaper *and* better-targeted than pinning
one model.

## What NOT to do in the name of "efficiency"

- **Don't drop the failing-test confirmation, the review, or the approval
  gates to "save tokens."** Those controls prevent re-work, which dwarfs their
  cost. Cutting a sensor to save a few hundred tokens routinely costs thousands
  in redo.
- **Don't compress instructions into cryptic shorthand.** Unparseable terseness
  causes mistakes; the win is in *deleting what isn't needed*, not in
  abbreviating what is. Keep AGENTS.md human-readable.
- **Don't strip the *reason* from a convention.** "No field injection — it broke
  unit-testing without a Spring context" generalizes to cases the rule never
  named; "No field injection" alone gets misapplied and causes re-work. The
  reason is high-value tokens, not overhead.

## A quick audit

- Open `AGENTS.md`. For each line ask: could the model infer this from training?
  If yes, delete it. Could it live in a path-scoped or `docs/` file instead? If
  yes, move it.
- Check your most-run agent commands: do any return far more than the agent
  uses? Add scoping flags.
- Are specs being auto-loaded en masse, or pulled in one at a time? Should be
  the latter.
- Is there a fast single-test command in AGENTS.md? If not, the agent is
  burning tokens running the whole suite to check one thing.
- Is the always-loaded prefix *stable* within a session, or are you editing
  `AGENTS.md`/constitution mid-session and invalidating the cache on every turn
  after?
- Are tools or MCP servers you don't need for this project still enabled? Each
  one ships its schema on every message.
- Is reasoning effort pinned high by default? Drop it to low/medium for routine,
  well-scoped work.

## References

- [Effective context engineering for AI agents — Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Context Engineering: Token Optimization and Agent Performance — FlowHunt](https://www.flowhunt.io/blog/context-engineering/)
- [LLM Model Routing: Cost-Quality Optimization (2026)](https://www.digitalapplied.com/blog/llm-model-routing-2026-cost-quality-optimization-engineering-guide)
- [Improving token efficiency in GitHub agentic workflows — GitHub](https://github.blog/ai-and-ml/github-copilot/improving-token-efficiency-in-github-agentic-workflows/)
- [GitHub Well-Architected — Managing AI credits](https://wellarchitected.github.com/library/governance/recommendations/managing-ai-credits/)
