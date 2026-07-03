# ADR-0005: Cross-session agent memory — learnings.md, gated AGENTS.md self-correction, test-intent docstrings, search-before-create

**Status**: Accepted
**Date**: 2026-07-02
**Deciders**: Repository maintainers

## Context

Every drafting and implementation agent in this kit (`specifier`, `planner`,
`task-decomposer`, `test-writer`, `implementor`, `debugger`, `code-reviewer`)
runs in its own fresh context per invocation — deliberately, so one phase's
back-and-forth doesn't bleed into the next (see `docs/model-selection-and-
token-optimization-in-sdd.md`). That isolation is a feature for review
independence, but it has a cost: a discovery an agent makes mid-task —
a build command that looked right but wasn't, "the config actually lives in
X, not where the plan assumed," a flaky test's real cause — has nowhere to
go except the final report. If the session ends, or the next story's
`implementor` is invoked fresh, that discovery is gone. It gets
re-discovered, or worse, re-broken.

Geoffrey Huntley's "Ralph Wiggum" agentic-loop pattern (an agent that
restarts from a fresh context every iteration, deliberately, by design) hits
this problem constantly and has converged on a handful of cheap countermeasures:
an append-only `progress.txt`-style learnings file; letting the agent update
its own persistent instructions file when it gets a command wrong twice;
requiring a docstring on every test explaining *why* it exists, so a future
iteration can tell "the test is wrong" from "the code regressed"; and a
standing "search before you conclude something isn't implemented" rule, to
stop bad ripgrep conclusions from producing duplicate implementations.

This kit already had the isolation-per-phase design and the "propose, human
approves" gate model (Specify/Plan/Tasks are each drafted by a fresh agent
and never self-approve) and the constitution's "never guess, always verify"
rule for *external* dependencies (`AGENTS.md`'s Multi-Repo section). It had
no equivalent for (1) memory that outlives one story's fresh context, (2) a
path for a repo-fact-level `AGENTS.md` drift to get fixed by the agent that
noticed it rather than waiting for a manual `sync-agents-md` pass, (3) a way
for a test's *intent* to survive past the session that wrote it, or (4) a
"never guess" rule for *internal* code that might already exist. Four
targeted, low-ceremony additions close these gaps without disturbing the
gate model that's already in place.

## Decision

### 1. `specs/<NNN>/learnings.md` — append-only, ungated

A fifth per-feature file, scaffolded alongside `spec.md`/`plan.md`/
`tasks.md`/`decision-log.md` by `develop-feature`'s Step 0 (both
`start-feature.sh` and `start-feature.ps1`), from the new
`templates/learnings.template.md`. Unlike the other four, it has **no Status
header, no approval gate, and no `decision-log.md` row** — it is a low-
ceremony scratchpad, not a fifth gated artifact.

`implementor` and `debugger` read it (if the caller passes a path and it has
entries) before starting work on a story, and append to it as they go — not
only in their final report, so a mid-story discovery survives even if the
session ends before the report is written. Entries are append-only: a
superseded discovery gets a new entry noting what changed, never an edit or
delete of the old one. `develop-feature` passes the path into every
`implementor`/`debugger` invocation (Phases 4 and 5's debugger loop) and
mentions it during feature resume.

Scoped to `implementor`/`debugger` only, not every agent — those two are the
ones doing exploratory, code-level work where a wrong-turn command or a
misplaced assumption is likely; `specifier`/`planner`/`task-decomposer` write
from already-curated inputs and have less of this kind of discovery to make.

### 2. Gated `AGENTS.md` self-correction

`implementor` and `debugger` each get a short "propose, don't write" rule: if
a command from `AGENTS.md` turned out wrong and a second attempt found the
right one, note it in the report as a one-line proposed correction (file,
section, old → new) — never edit `AGENTS.md` directly. `develop-feature`
relays the proposal to the human at the point it's returned (Phase 4 step 2;
the debugger loop in Phase 5) and only applies it after explicit approval,
either directly for a one-line fix or via `docs-writer`/`sync-agents-md` for
anything larger. `templates/agents.template.md`'s Boundaries section notes
this as an "Ask first" item so a project's real `AGENTS.md` documents the
convention too.

This deliberately does *not* give the agent write access to `AGENTS.md` the
way Ralph's original pattern does — that would bypass the "agent proposes,
human approves" gate every other document in this kit goes through. It's the
same gate model as Specify/Plan/Tasks, applied to a single-line repo-fact
fix instead of a whole document, and it's a cheaper, earlier catch than
waiting for the next manual `sync-agents-md` run.

### 3. Test-intent docstrings

`test-writer` gets a new hard rule: every test carries a one- to two-line
docstring or adjacent comment naming the acceptance-criterion ID it covers
(`FR-004`, `SC-002`, or an acceptance-scenario number) and *why the test
matters* — what breaks if it's wrong or missing. `tests/README.md` documents
the convention, the constitution template's Article III gets a corollary
bullet tying it explicitly to "never weaken a failing test," and
`code-reviewer`'s Test integrity check now looks for the docstring as part
of that same check.

This directly strengthens the existing "never weaken or delete a failing
test" rule: that rule only works if someone (a human, or a later
`debugger`/`implementor` run in a fresh context) can actually tell a wrong
test from a genuine regression. Without the reasoning that produced the
test, that judgment call degrades into a guess. The docstring is what
survives the context boundary that the reasoning otherwise wouldn't.

### 4. Search before concluding something isn't implemented

`implementor` and `specifier` each get one new Behavioral guardrail bullet —
"Search before creating" / "Search before assuming a gap": search the
codebase broadly (more than one plausible name or location) before
concluding a capability doesn't already exist, whether that conclusion leads
to writing new code (`implementor`) or specifying a requirement that treats
the capability as missing (`specifier`). `docs/guardrails.md` documents it
as a skill-specific addition, alongside the existing ones.

This is explicitly framed as the internal-code twin of the constitution's
existing "cross-repo contracts — never guess, always verify" rule
(`memory/constitution.template.md`'s Additional Constraints, resolved via
`AGENTS.md`'s Multi-Repo section): that rule stops an agent from fabricating
an external dependency's shape; this one stops it from fabricating an
absence inside the repo it can already see in full. Unlike Ralph's original
formulation, this does **not** instruct the agent to dispatch a sub-agent for
the search — `implementor`/`specifier` are themselves invoked as sub-agents
in this kit's harness and, per their own "Escalation" sections, cannot
invoke another agent; the rule is scoped to thorough grep/glob within the
agent's own turn, not a sub-agent fan-out.

## Consequences

- One new per-feature file (`learnings.md`) and one new template to
  maintain, but it's intentionally cheap: no Status field, no gate, no
  `decision-log.md` row, so it doesn't add a review checkpoint anywhere.
- `AGENTS.md` can now drift-correct itself one line at a time between
  `sync-agents-md` runs, without weakening the human-approval gate — the
  proposal still needs a yes.
- Every test now costs a couple of extra lines (the docstring); the payoff is
  that a Should-this-test-change judgment call has evidence to work from
  instead of context-free guessing, in `code-reviewer`, `debugger`, and any
  future session.
- `implementor`/`specifier` do a bit more searching before writing, which
  costs some tokens on every task — the same trade-off the constitution
  already accepted for the external-dependency version of this rule, on the
  premise that a duplicate implementation costs far more to unwind later.

## Alternatives considered

- **Let `implementor`/`debugger` write `AGENTS.md` directly** (Ralph's
  original behavior) — rejected: bypasses the "agent proposes, human
  approves" gate that every other document in this kit goes through; a
  wrong self-correction would be far more expensive than the manual
  `sync-agents-md` cadence it's meant to supplement.
- **Fold `learnings.md` into `decision-log.md`** — rejected: `decision-log.md`
  is a committed, gated audit trail of human-approved decisions; forcing
  ungated, in-progress discoveries into the same file would blur that
  distinction and add ceremony to something meant to be low-friction.
- **Have `implementor`/`specifier` dispatch a sub-agent to search** (Ralph's
  literal wording) — rejected: contradicts this kit's existing constraint
  that a sub-agent cannot invoke another agent (see both agents'
  `Escalation`/`Distinct from` sections); thorough grep/glob within the same
  turn achieves the same "don't assume absence" goal without that
  contradiction.
- **Apply the docstring rule kit-wide via the constitution's universal
  guardrails** — rejected: it's specific to `test-writer`'s output, not a
  behavior every skill needs; it belongs with the other test-first rules in
  Article III, referenced from `test-writer.md`, not duplicated into the
  three universal guardrails in `docs/guardrails.md`.
