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

## Skill-specific additions

Each skill may extend these with its own guardrails — for example:

- `spec-driven-feature` adds **No over-engineering** (only build what's
  directly requested).
- `init-project` and `amend-constitution` add **No over-populating** (short
  and accurate beats long and generic).
- `sync-agents-md` adds **Evidence or nothing** (every claim must trace to a
  file you read) and several file-scoping guardrails.

## Maintenance

When editing a guardrail, update the wording here first, then propagate the
change to each skill's `## Behavioral guardrails` section. The text must be
identical in every skill so there's a single authoritative wording to update.

## See also

- `docs/context-engineering.md` — explains prompt caching mechanics and why
  the always-loaded tier should be ruthlessly small.
