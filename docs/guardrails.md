# Behavioral Guardrails

These are the canonical universal guardrails that apply to every skill and
agent in this kit. Skill and agent files embed them verbatim so the wording is
identical across all prompts — a single source here makes future edits
propagate consistently.

This is enforced, not just nominal: `scripts/check-guardrails.sh` (run in CI
by `agent-harness.yml`) extracts the three delimited blocks below and fails
the build if any canonical file under `.agents/agents/` or `.agents/skills/`
has a `## Behavioral guardrails` section whose first three bullets don't
match the applicable block byte-for-byte. Do not change the wording inside a
`GUARDRAILS:*` delimiter without also updating every file that embeds it —
the checker will tell you which ones still need it.

## The three universal guardrails (skill variant)

Skills run in the top-level session and can pause to talk to the human
directly. This is the wording every `.agents/skills/*/SKILL.md` file's
`## Behavioral guardrails` section must start with.

<!-- GUARDRAILS:skill -->
- **No guessing.** Where input leaves something unspecified, write
  `[NEEDS CLARIFICATION: specific question]` and surface it — never silently
  invent an assumption.
- **Investigate before claiming.** Never make statements about the codebase
  without first reading the relevant files. If a claim requires looking at
  code, look first.
- **Conservative by default.** Recommend before you write; stop and ask before
  anything irreversible (deleting files, force-pushing, dropping tables,
  external service calls).
<!-- /GUARDRAILS:skill -->

## Sub-agent variant

Agents under `.agents/agents/` (`code-reviewer`, `debugger`, `implementor`,
etc.) are invoked as sub-agents by a skill or another agent — they return one
report to their caller and cannot themselves pause a conversation with the
human. Two of the three universal guardrails need different wording there so
the agent isn't holding an instruction it has no way to execute:

- **Conservative by default** — skills say "stop and ask before anything
  irreversible." Agents instead say: flag anything irreversible and **return
  it to the caller as a question** instead of proceeding. The caller (a skill
  running at the top level, or a human session) is the one that can actually
  ask.
- **No guessing** — skills say "write `[NEEDS CLARIFICATION: ...]`." For the
  two read-only agents with no Write/Edit tool (`code-reviewer`,
  `artifact-analyzer`), change "write" to "state ... in your report" — they
  have no file to write the marker into, only a returned report. Agents that
  do hold Write/Edit keep "write" as-is.

Most agents (`debugger`, `docs-writer`, `implementor`, `planner`, `specifier`,
`task-decomposer`, `test-writer` — anything with a Write/Edit tool) use this
block:

<!-- GUARDRAILS:agent -->
- **No guessing.** Where input leaves something unspecified, write
  `[NEEDS CLARIFICATION: specific question]` and surface it — never silently
  invent an assumption.
- **Investigate before claiming.** Never make statements about the codebase
  without first reading the relevant files. If a claim requires looking at
  code, look first.
- **Conservative by default.** Recommend before you write; flag anything
  irreversible (deleting files, force-pushing, dropping tables, external
  service calls) and return it to the caller as a question instead of
  proceeding — a sub-agent cannot pause to ask the human directly.
<!-- /GUARDRAILS:agent -->

The two read-only agents (`code-reviewer`, `artifact-analyzer` — no
Write/Edit tool) use this block instead:

<!-- GUARDRAILS:agent-readonly -->
- **No guessing.** Where input leaves something unspecified, state
  `[NEEDS CLARIFICATION: specific question]` in your report and surface it —
  never silently invent an assumption. (This agent is read-only — no
  Write/Edit tool — so the marker goes in the returned report, not a file.)
- **Investigate before claiming.** Never make statements about the codebase
  without first reading the relevant files. If a claim requires looking at
  code, look first.
- **Conservative by default.** Recommend, never write. Flag anything
  irreversible (deleting files, force-pushing, dropping tables, external
  service calls) and return it to the caller as a question — a sub-agent
  cannot pause to ask the human directly.
<!-- /GUARDRAILS:agent-readonly -->

When adding a new agent under `.agents/agents/`, use the sub-agent wording
above, not the skill wording. After editing any canonical agent file, run
`scripts/mirror-agents.sh` (or `.ps1`) to regenerate `.claude/agents/`,
`.codex/agents/`, and `.github/agents/` — never hand-edit those generated
copies (ADR-0001).

## Skill-specific additions

Each skill may extend these with its own guardrails — for example:

- `develop-feature` adds **No over-engineering** (only build what's
  directly requested).
- `init-project` and `amend-constitution` add **No over-populating** (short
  and accurate beats long and generic).
- `sync-agents-md` adds **Evidence or nothing** (every claim must trace to a
  file you read) and several file-scoping guardrails.
- `implementor` and `specifier` add **Search before creating** / **Search
  before assuming a gap** — search the codebase broadly, more than one
  plausible name or location, before concluding a capability doesn't already
  exist. The internal-code analog of the constitution's "never guess, always
  verify" rule for external dependencies.

## Maintenance

When editing a guardrail, update the matching `GUARDRAILS:*` block here
first, then propagate the change to every skill or agent file that embeds
that block. The text must be identical everywhere so there's a single
authoritative wording to update. Run `scripts/check-guardrails.sh` (or
`.ps1`) after editing — it will list every canonical file whose guardrails
section still doesn't match, so you don't have to grep for stragglers by
hand. A skill or agent may add its own extra bullets after the shared block
(e.g. `develop-feature`'s **No over-engineering**), but must not alter the
wording of the three shared bullets — extend, don't inline-edit.

## See also

- `docs/context-engineering.md` — explains prompt caching mechanics and why
  the always-loaded tier should be ruthlessly small.
