---
applyTo: "src/**"
---

<!--
  Path-scoped Copilot instructions. These rules are injected ONLY when the
  agent is working on files matching the `applyTo` glob above — this is the
  context-engineering point of this file: keep narrow, subtree-specific rules
  OUT of the always-loaded AGENTS.md so they cost no tokens elsewhere.

  Rename this file per subtree (e.g. `api.instructions.md`, `web.instructions.md`)
  and narrow `applyTo` accordingly. One file per glob. Replace the examples
  below with real rules, or delete this file if you have no path-specific rules.

  Global conventions stay in AGENTS.md — do not duplicate them here.
-->

# Rules for `src/**`

- Example: every public function in this subtree has a docstring stating its
  one responsibility — `[replace with your real rule + reason]`.
- Example: do not add a new top-level package under `src/` without an ADR in
  `docs/adr/` — `[replace with your real rule + reason]`.
