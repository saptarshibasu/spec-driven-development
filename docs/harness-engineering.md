# Harness Engineering

A coding agent is only as good as the *harness* around it — the guides that
steer it before it acts and the sensors that catch it when it drifts. Martin
Fowler and Birgitta Boeckeler (ThoughtWorks) named this practice **harness
engineering**: building feedforward and feedback controls around an agent so
you can trust its output without reading every line yourself.

Spec-driven development *is* a harness. This document makes that explicit, so
you can see which files in this repo are playing which role, and where your
harness has gaps.

## Two kinds of control

**Feedforward (guides)** steer the agent *before* it acts. They encode what
"good" looks like up front so the agent is more likely to produce it the first
time. In this repo: `AGENTS.md`, the constitution, the spec/plan/tasks
templates, the skills, the path-scoped instructions, the glossary.

**Feedback (sensors)** detect problems *after* the agent acts and let it (or
you) self-correct. In this repo this tier is intentionally yours to wire up to
your stack: linters, type checkers, the test suite, contract tests, CI gates,
and the `code-reviewer` agent.

Neither half is sufficient alone. **Feedback-only** gives you an agent that
keeps making the same mistakes because nothing told it the rule — you catch
each one by hand, forever. **Feedforward-only** encodes the rules but never
verifies they were followed — the agent confidently violates a guide and
nothing notices. A working harness has both, and closes the loop: when a sensor
catches a recurring miss, you add a guide so it stops happening.

## Two kinds of enforcement

Cutting the other way, every control is either **computational** or
**inferential**:

- **Computational controls** are deterministic: a linter, a compiler, a test, a
  schema validator, a query-count assertion. They are cheap, fast, repeatable,
  and they never hallucinate. Prefer them whenever the rule *can* be mechanized.
- **Inferential controls** use an LLM's semantic judgment: "does this code
  match the spec's intent?", "is this abstraction justified?", "is this naming
  clear?" They cover the large space of things no linter can check — but they
  cost tokens and can be wrong, so use a different model/family than the one
  that wrote the code, and reserve them for what computation can't reach.

The design rule: **mechanize what you can, infer what you must.** A prose rule
in `AGENTS.md` that an agent re-reads every session is the *weakest* form of
guarantee. If you can turn it into a test that fails, do — that is why the
`Performance & Efficiency` section of `AGENTS.md` ends by telling you to name a
query-count assertion or an N+1 detector and "treat it as the actual
enforcement."

## The harness regulates three things

Fowler's framing distinguishes three dimensions the harness keeps in check.
Worth naming because they fail differently and need different controls:

| Dimension | Question | Strong control type |
|---|---|---|
| **Maintainability** | Is the code clean, conventional, readable? | Computational (lint, format) + inferential (review) |
| **Architecture fitness** | Does it respect the system's structure and boundaries? | Inferential (review against constitution/ADRs) + fitness functions |
| **Functional behaviour** | Does it actually do the right thing? | Computational (tests, contract tests) — and this is the hardest to fully pin down |

Behaviour is the unsolved-est of the three: tests catch what you thought to
assert, not what you forgot. This is why the constitution makes test-first
non-negotiable and why characterization tests exist — they are the behaviour
sensor for code that has none.

## The SDD harness, mapped

Read this as "which file is which control."

```
                    FEEDFORWARD (guides)              FEEDBACK (sensors)
                    ─ steer before acting ─           ─ catch after acting ─

  COMPUTATIONAL     start-feature.sh                  test suite / contract tests
  (deterministic)   (scaffolds correctly every        linters, type checkers
                     time — no model judgment)         CI gates
                                                       query-count / N+1 assertions

  INFERENTIAL       AGENTS.md, constitution           code-reviewer agent
  (LLM judgment)    spec / plan / tasks templates     "confirm the test fails
                    skills (gated workflow)            for the expected reason"
                    glossary, ADRs                     spec-conformance review
```

The approval gates in the `spec-driven-feature` skill (Specify → Plan → Tasks,
each requiring human sign-off) are a deliberate *human-in-the-loop* sensor
placed at the points where a mistake is cheapest to catch and most expensive to
let through. A wrong spec caught at the gate costs a re-draft; the same error
caught after implementation costs the whole feature.

## Building out your feedback half

The guide half of this repo is filled in; the sensor half is mostly yours to
connect, because it is stack-specific. Highest-leverage additions, roughly in
order:

1. **A fast test command the agent can run itself**, named exactly in
   `AGENTS.md` (single-test form too — agents iterate far faster when they can
   run one test, not the whole suite).
2. **Lint + format + type-check in one command**, also in `AGENTS.md`, so the
   agent can self-correct style and type errors before you ever see them.
3. **A CI workflow** that runs the above on every PR — the backstop sensor that
   fires even when the agent skips the local one. See
   `.github/workflows/agent-harness.yml` for a language-agnostic starting point.
4. **Mechanized versions of your recurring prose rules.** Every time the
   reviewer or you catch the same class of mistake twice, ask: can this be a
   test or a lint rule? If yes, move it from feedforward prose to a
   computational sensor.
5. **The `code-reviewer` agent** (`.claude/agents/code-reviewer.md`) as the
   inferential backstop for what 1–4 can't mechanize: spec conformance,
   abstraction creep, test integrity.

## Signs your harness is weak

- The agent repeats a mistake you've corrected before → missing feedforward
  guide (add it to AGENTS.md, or better, mechanize it).
- A guide is routinely violated and nobody notices until late → missing
  feedback sensor for that guide.
- You re-read every diff line-by-line to trust it → too much weight on
  inferential review, not enough computational coverage.
- Tests pass but behaviour is wrong → behaviour sensor is shallow; add
  contract/characterization tests at the boundary that broke.
- A prose rule in AGENTS.md keeps being ignored → it should be a test, not a
  sentence.

## See also

- `docs/context-engineering.md` — the feedforward half in depth: what the agent
  sees before it acts.
- `docs/token-efficiency.md` — a tight harness also *saves* tokens by catching
  errors early instead of re-prompting.
- `memory/constitution.md` — the highest-authority feedforward guide.

## References

- [Harness engineering for coding agent users — Martin Fowler](https://martinfowler.com/articles/harness-engineering.html)
- [awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering)
- [Effective context engineering for AI agents — Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
