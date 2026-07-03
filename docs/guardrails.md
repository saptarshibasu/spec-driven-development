# Behavioral Guardrails

These are the canonical universal guardrails that apply to every skill in this
kit. Skill files embed them verbatim so the wording is identical across all
prompts — a single source here makes future edits propagate consistently.

## The three universal guardrails

- **No guessing.** Where input leaves something unspecified, write
  `[NEEDS CLARIFICATION: specific question]` and surface it — never silently
  invent an assumption.
- **Investigate before claiming.** Never make statements about the codebase
  without first reading the relevant files. If a claim requires looking at
  code, look first.
- **Conservative by default.** Recommend before you write; stop and ask before
  anything irreversible (deleting files, force-pushing, dropping tables,
  external service calls).

## Sub-agent variant

Skills run in the top-level session and can pause to talk to the human
directly. Agents under `.agents/agents/` (`code-reviewer`, `debugger`,
`implementor`, etc.) are invoked as sub-agents by a skill or another agent —
they return one report to their caller and cannot themselves pause a
conversation with the human. Two of the three universal guardrails need
different wording there so the agent isn't holding an instruction it has no
way to execute:

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

When editing a guardrail, update the wording here first, then propagate the
change to each skill's `## Behavioral guardrails` section. The text must be
identical in every skill so there's a single authoritative wording to update.

## See also

- `docs/context-engineering.md` — explains prompt caching mechanics and why
  the always-loaded tier should be ruthlessly small.
