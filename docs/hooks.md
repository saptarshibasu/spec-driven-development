# Hooks

Hooks are how you turn a rule the agent *should* follow into a rule that is
*enforced* — deterministically, at zero token cost. In the harness-engineering
model (`harness-engineering.md`), hooks are computational controls: they never
hallucinate and they fire whether or not anyone remembered the rule. Every time
you catch yourself re-explaining the same constraint to an agent, ask whether it
should be a hook instead.

There are two complementary kinds.

## 1. Git hooks (tool-agnostic — start here)

Git hooks run on git events regardless of which agent or editor produced the
change, so they protect the repo from humans and agents alike. This kit ships a
[`.githooks/pre-commit`](../.githooks/pre-commit) that:

- blocks committed secrets (coarse patterns — wire in `gitleaks`/`trufflehog`
  for real coverage),
- blocks committing a spec that still has an unresolved `[NEEDS CLARIFICATION]`
  marker,
- keeps `CLAUDE.md` / `copilot-instructions.md` thin (ADR-0001), and
- has a commented slot for your stack's lint + fast tests — fill it with the
  *same* commands named in `AGENTS.md` so local, hook, and CI checks are
  identical.

Enable it once per clone (hooks aren't installed automatically, by design):

```bash
git config core.hooksPath .githooks
```

Bypass deliberately, never habitually:

```bash
git commit --no-verify
```

Keep pre-commit **fast** — anything slow belongs in CI
(`.github/workflows/agent-harness.yml`), which is the backstop that runs even
when someone uses `--no-verify`.

## 2. Agent runtime hooks (richer, tool-specific)

Some agent runtimes fire hooks around their own actions — before a tool call,
after an edit, on session start. These can enforce things git hooks can't, e.g.
*block an agent from editing an approved spec*, auto-format after every write, or
inject a reminder at session start.

- **Claude Code** supports event hooks (`PreToolUse`, `PostToolUse`, etc.)
  configured in settings — e.g. a `PreToolUse` hook that rejects edits to
  `specs/**/spec.md` once a feature is locked, or a `PostToolUse` hook that runs
  the formatter after every `Edit`/`Write`.
- Other runtimes expose similar mechanisms under their own names.

These are intentionally not shipped here because their format is tool-specific
and they run with real permissions — configure them per your runtime, and treat
any hook that runs commands as trusted code.

## Where each rule should live

| Rule | Best home |
|---|---|
| No secrets in VCS | git pre-commit (+ CI) |
| Spec must be clarified before commit | git pre-commit |
| Lint/format/type-check | git pre-commit (fast) + CI |
| Full test suite | CI |
| Don't edit a locked spec | agent runtime hook (PreToolUse) |
| Auto-format after edits | agent runtime hook (PostToolUse) |
| Conventions an agent should *know* | `AGENTS.md` (feedforward) — but mechanize any that keep being violated |

The throughline: a prose rule an agent re-reads each session is the weakest
guarantee. Promote the ones that matter into a hook or a test.
