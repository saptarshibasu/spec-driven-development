---
name: checklist
description: Use to generate a requirements-quality checklist for a feature — "unit tests for the spec." Triggers on phrases like "make a checklist for this spec", "is this spec ready", "review requirements quality", "security checklist for X", or before planning a high-stakes feature. Produces a filled-in checklist from templates/checklist.template.md that tests whether the REQUIREMENTS are complete/clear/consistent/measurable — not whether the code works. Do not use to test implementation (that's the test suite) or to resolve ambiguity (use clarify).
---

# Checklist

Generates a checklist that tests the **spec**, not the code. Think of each item
as a unit test for a requirement: does it pass the bar of being complete, clear,
consistent, and measurable? A spec that sails through `clarify` can still be
vague or internally contradictory; this gate catches that before planning.

Output goes to `specs/<NNN-feature>/checklist.md` (or a named variant like
`security-checklist.md`), built from `templates/checklist.template.md`.

## When to run

After `clarify`, before `plan`, for any feature with meaningful risk or
ambiguity. Also use it to run a *narrow, repeatable* review pass — security,
accessibility, migration-readiness — the same way across many features.

## Behavioral guardrails

- **Test the requirements, not the implementation.** Every item interrogates the
  spec's quality ("Is the latency target measurable?"), never the code's
  behaviour ("Does the endpoint return 200?"). If an item could only be checked
  by running code, it belongs in the test suite, not here.
- **No trivially-passing items.** If every item always passes, the checklist
  isn't earning its keep. Each item should be one a real spec could fail.
- **Confirm the template exists.** Requires `templates/checklist.template.md`. If
  missing, stop and tell the user.

## Step 1 — Pick the checklist's purpose

Ask the user (or infer from the request) which kind of pass this is:

- **Requirements-quality** (default) — completeness, clarity, consistency,
  measurability of the spec as a whole.
- **Domain pass** — security, accessibility, migration-readiness, performance,
  data-privacy: a focused lens over the same spec.

One checklist = one purpose. Don't blend a security pass into a general-quality
pass.

## Step 2 — Generate items from the spec

Read `spec.md` (and `plan.md` if it exists). Derive concrete, checkable items.
For a requirements-quality pass, cover:

- **Completeness** — Are all user stories given acceptance criteria? Is every
  error/edge case from the Edge Cases section reflected in a requirement? Is Out
  of Scope filled in, not a placeholder?
- **Clarity** — Is each requirement testable and unambiguous? Any "fast",
  "secure", "intuitive" left undefined?
- **Consistency** — Do any requirements contradict each other or the success
  criteria? Do the non-functional targets match what the stories imply?
- **Measurability** — Is every success criterion a number or a binary, not a
  vibe?

For a domain pass, generate items from that domain's known failure modes (e.g.
security: authN/authZ stated per endpoint, secrets handling, input validation,
PII classification, rate limiting).

Write each as `CHK0NN [specific, checkable item]`, grouped by category, using the
template's structure. Strip the template's instructional comments from the
output.

## Step 3 — Run the checklist and report

Go through each item against the spec and mark it: `[x]` pass, `[ ]` fail, with a
one-line note on every *finding* (not on trivial passes). Then:

- Summarise the failures — these are the spec's real gaps.
- Recommend: route ambiguity findings back through `clarify`; route genuine
  missing requirements back to the spec author.
- State whether the spec is checklist-clean enough to plan.

**Example output** (requirements-quality pass, abbreviated):

```markdown
## Measurability
- [x] CHK001 Every success criterion is a number or binary.
- [ ] CHK002 Latency target is quantified.
      ✖ SC-002 says "responses feel fast" — no number. → clarify (suggest p95 target).

## Completeness
- [ ] CHK003 Every user story has acceptance scenarios.
      ✖ US2 has none. → back to author.
- [x] CHK004 Out of Scope is filled in, not a placeholder.
```

> Verdict: 2 of 4 failing — not plan-ready. CHK002 is an ambiguity (route to
> `clarify`); CHK003 is a missing requirement (route to the author).

## What this skill does not do

- It does not test implementation correctness — that's the test suite.
- It does not resolve the gaps it finds — it routes them to `clarify` or the
  author.
