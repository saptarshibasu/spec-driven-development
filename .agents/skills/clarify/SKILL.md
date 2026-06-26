---
name: clarify
description: Use after a draft spec exists but before planning, to surface and resolve ambiguity — triggers on phrases like "clarify the spec", "are there gaps in this spec", "what's ambiguous here", "review my spec for missing details", or when about to run plan on a spec that still has open questions. Asks a small number of targeted questions one at a time, then writes the answers back into spec.md. Do not use to write a spec from scratch (use spec-driven-feature) or for plan/tasks-level questions.
---

# Clarify

Hardens a draft `spec.md` *before* it reaches planning, by finding the places
where an implementer would otherwise have to guess and getting the human to
decide. This is the cheapest quality gate in the whole pipeline: an ambiguity
caught here costs one question; the same ambiguity caught in implementation
costs a rebuild.

## When to run

After a spec draft exists (hand-written or from `spec-driven-feature`) and
before `plan`. If the spec still contains `[NEEDS CLARIFICATION]` markers, this
skill is the way to clear them.

## Behavioral guardrails

- **Ask, don't assume.** Every question must be a real decision the spec leaves
  open, not a rhetorical one. If you can answer it correctly from the spec or
  the codebase, it isn't a clarification — go look instead of asking.
- **One or two questions at a time.** Do not dump a questionnaire. The point is
  a focused conversation, not a form.
- **Cap it.** Ask at most ~5 questions per pass. If more than five real
  ambiguities exist, the spec isn't ready for clarification — say so and send it
  back for more drafting.
- **Read-only until the end.** Do not edit `spec.md` until the user has answered;
  then write the resolutions in, don't paraphrase them away.

## Step 1 — Scan for ambiguity

Read the spec and the relevant parts of the codebase. Build a candidate list,
prioritised by blast radius (how much downstream work a wrong guess would
corrupt). Look specifically for:

- Existing `[NEEDS CLARIFICATION: ...]` markers — these are pre-identified and
  go to the top of the list.
- **Underspecified behaviour:** error cases, empty/boundary inputs, concurrency,
  idempotency, ordering, pagination limits — the things specs routinely omit.
- **Ambiguous acceptance criteria:** "fast", "secure", "user-friendly" with no
  measurable target.
- **Unstated assumptions** about auth, data ownership, multi-tenancy, scale.
- **Scope edges:** things a reasonable reader might assume are in or out but the
  Out of Scope section doesn't pin down.

Reduce the list to the highest-impact ~5. Discard anything you can resolve
yourself by reading — those are not questions.

**Reason explicitly before you ask.** For each candidate, think through *what
would break downstream if you guessed wrong* — that reasoning is how you rank by
blast radius and how you decide whether it's a real question or something you
should just go read. Do this thinking before writing any question.

## Step 2 — Ask, one or two at a time

For each, ask a concrete, decision-shaped question with options where natural:

> "When a user submits a duplicate order, should the system reject it (409),
> silently dedupe, or accept both? The spec doesn't say, and it changes the
> data model."

Always state *why it matters* in one clause — it helps the user answer well and
proves the question is load-bearing.

## Step 3 — Write resolutions back into the spec

Once answered:

1. Replace each `[NEEDS CLARIFICATION]` marker with the decided behaviour, in the
   right section (a requirement becomes an FR; an assumption goes under
   Assumptions; a scope edge goes to Out of Scope).
2. For ambiguities that had no marker, add the decision to the appropriate
   section so the spec now states it explicitly.
3. Do not invent detail beyond what the user decided — if an answer raises a new
   question, surface it rather than guessing.
4. Re-run the spec's own Spec Completeness Checklist.

**Example write-back** — user answered "reject duplicates with a 409":

```diff
- **FR-004**: System MUST handle duplicate order submissions
-   [NEEDS CLARIFICATION: reject, dedupe, or accept both?]
+ **FR-004**: System MUST reject a duplicate order submission with HTTP 409
+   and a machine-readable error code; no second order is created.
```

Resolve into the right section — a behaviour decision becomes an FR (as above),
a default you chose goes under Assumptions, an excluded case goes to Out of Scope.

## Step 4 — Report

Tell the user what was resolved, what (if anything) remains open, and whether
the spec is now ready for `plan`. If unresolved markers remain because the user
deferred them, say so plainly — do not silently leave the spec looking done
when it isn't.

## What this skill does not do

- It does not write a spec from scratch — that's `spec-driven-feature`.
- It does not move on to `plan` or `tasks` — clarification is its whole job.
- It does not invent answers to its own questions to seem efficient.
