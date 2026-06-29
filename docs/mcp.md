# MCP Servers

Model Context Protocol (MCP) servers give an agent extra tools — fetching live
docs, driving a browser, talking to GitHub. They are powerful, and they are
easy to overdo. This doc is the opinionated short version: **use a small,
curated set; don't build your own unless you have a real reason.**

A starter config lives at [`.mcp.json.example`](../.mcp.json.example). Copy it
to `.mcp.json`, trim it, and supply secrets via environment variables.

## The one rule that matters most: keep the set small

Every connected server adds tool definitions to the agent's context on every
call, and gives the model more ways to go wrong. The consistent finding across
2026 surveys is that **more than ~5–7 servers degrades performance** through
tool bloat — the same context-budget problem described in
[`context-engineering.md`](context-engineering.md), applied to tools. Start with
two or three that match your daily workflow and add only when a real, recurring
need appears. A server you use once a month is costing you tokens on every other
session.

## Recommended set for spec-driven development

| Server | Why it earns a slot | Notes |
|---|---|---|
| **Context7** | Fetches **version-specific** library docs at query time and injects them into context. Stale/guessed library APIs are the single biggest source of AI coding errors — this is the most directly useful server for code quality, and it reinforces this repo's "never guess a dependency's API" rule. | The most-used MCP server in the ecosystem. Lowest-risk, highest-value first pick. |
| **Playwright** | Lets the agent actually drive a browser to write and run integration/E2E tests — the *behaviour* sensor that's hardest to mechanize (see `harness-engineering.md`). | Pairs naturally with the `test-writer` agent for web features. |
| **GitHub** | PR creation/review, issue management, code search across repos — removes the copy-paste loop. Useful once your workflow lives in PRs. | Needs a scoped token via `${GITHUB_TOKEN}`. Grant least privilege. |

Servers to add **only if your runtime lacks the capability**: a **filesystem**
server (skip it — most coding agents, including Claude Code, already have file
access) and a **git** server (skip it — agents run git through bash; add only if
you want structured git output the model parses more reliably).

## Should you build your own MCP server?

Usually **no**. For a tool-agnostic starter kit, a bespoke server is maintenance
burden and another thing to keep in sync. Build one only when **all** of these
hold:

1. There's a **deterministic, repo-specific capability** the agent needs
   repeatedly (not a one-off).
2. It's **better as a typed tool** than as a skill calling a script — i.e. the
   agent benefits from structured input/output, not just running a command.
3. A **skill + script can't do it cleanly** already.

Candidates that *might* clear the bar for an SDD project: a "spec/task status"
query tool (what's the current feature, which tasks are open), or the
cross-repo **dependency resolver** described in `AGENTS.md`'s Multi-Repo section
(resolve a dependency's source from a sibling repo / source jar / decompiled
jar). Even then, try a skill first — most "I need a tool" needs are met by a
script the agent runs, which costs no always-loaded tool budget.

## Security

- **Never inline secrets** in `.mcp.json`. Use `${ENV_VAR}` expansion and keep
  the real `.mcp.json` out of version control if it contains anything sensitive
  (the example file is safe to commit; a filled-in one may not be).
- **Least privilege** on tokens — a GitHub token scoped to the repos and actions
  the agent actually needs.
- **Treat third-party servers as untrusted code** running with your
  credentials. Prefer official/widely-used servers; review what a server can do
  before connecting it.

## References

- [github/spec-kit — MCP-aware SDD workflow](https://github.com/github/spec-kit)
- [Best MCP Servers for Coding (2026) — Morph](https://www.morphllm.com/best-mcp-servers-coding)
- [Best MCP Servers 2026, ranked by use case + security risks](https://www.shareuhack.com/en/posts/best-mcp-servers-guide-2026)
