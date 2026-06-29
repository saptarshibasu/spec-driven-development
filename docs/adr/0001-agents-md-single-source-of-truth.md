# ADR-0001: AGENTS.md is the single source of truth for agent instructions

**Status**: Accepted
**Date**: 2026-06-25
**Deciders**: Repository maintainers

## Context

Coding agents read their instructions from tool-specific locations: Claude Code
reads `CLAUDE.md` and `.claude/`, GitHub Copilot reads
`.github/copilot-instructions.md` and `.github/`, Codex reads `.codex/`, and an
emerging cross-tool convention reads a root `AGENTS.md` and `.agents/`. A team
using more than one tool — or switching tools — risks maintaining the same
conventions in three or four places, where they inevitably drift out of sync.
Drifted instructions are worse than none: an agent confidently follows a stale
rule.

## Decision

We will treat the root **`AGENTS.md`** as the one canonical instruction file.
Every tool-specific instruction file (`CLAUDE.md`,
`.github/copilot-instructions.md`, and any future equivalent) is a **thin
pointer** that redirects to `AGENTS.md` and contains no conventions of its own.
Domain vocabulary lives once in `docs/glossary.md` and is referenced, not
inlined. Skills are kept byte-identical across `.agents/`, `.claude/`,
`.github/`, and `.codex/` by mirroring from a single canonical copy
(`.agents/skills/`) rather than hand-editing each.

Subagents follow the same single-source rule, with one twist: each tool reads
agent definitions in a different format (Claude `.md` with `tools`/`model`
front-matter, Copilot `.agent.md`, Codex `.toml`), so a byte-for-byte mirror is
impossible. Instead the canonical agent is authored once as Markdown in
`.agents/agents/<name>.md`, and `mirror-agents.sh` / `mirror-agents.ps1`
**generate** each tool's native file from it. The rule is unchanged — edit the
canonical copy, never a generated one — only the propagation mechanism differs
(generate vs. copy).

## Consequences

- One file to update for a convention change; pointers never need editing.
- New tools are onboarded by adding a one-line pointer, not by re-authoring
  rules.
- The cost: skill and agent copies must be kept in sync mechanically (skills via
  `mirror-skills.sh` / `.ps1`, agents via `mirror-agents.sh` / `.ps1`) rather than
  edited in place — editing a generated copy by hand reintroduces exactly the
  drift this decision prevents.
- `AGENTS.md` is loaded on every call, so it must stay short and specific; this
  decision concentrates the token-budget discipline in one place (see
  `docs/context-engineering.md`).

## Alternatives considered

- **Maintain full instructions per tool** — rejected: guaranteed drift,
  multiplied token cost, no single place to reason about the rules.
- **Consolidate to `.agents/` only and drop the tool-specific dirs** —
  rejected for now: not all runtimes auto-discover `.agents/` skills yet, so it
  would break discovery for some tools. Revisit when discovery converges.
