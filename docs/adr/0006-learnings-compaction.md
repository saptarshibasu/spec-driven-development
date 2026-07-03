# ADR-0006: `learnings.md` compaction — human-approved, orchestrator-only

**Status**: Accepted
**Date**: 2026-07-03
**Deciders**: Repository maintainers

## Context

ADR-0005 gave `implementor`/`debugger` a cross-session memory —
`specs/<NNN>/learnings.md` — modeled on the Ralph Wiggum agentic-loop
pattern's append-only `progress.txt`. It imported the memory half of that
pattern but not the other half: Ralph-style loops that run long enough to
need a `progress.txt` also tend to need someone, eventually, to prune it.
ADR-0005 made the file strictly append-only ("never rewrite or delete a
prior entry, even a superseded one") and said nothing about what happens
once it's accumulated dozens of entries across a long feature, or a
Ralph-style resumed one that spans many sessions.

Left alone, that's a monotonically growing file that both `implementor` and
`debugger` are instructed to read in full before starting every story
(ADR-0005, "read it before starting"). Early in a feature this is cheap.
Late in a long feature — or a feature resumed many times — it stops being a
quick scratchpad read and starts being a growing tax on every story's fresh
context, much of it superseded ("X was assumed to live in Y, corrected;
actually it's in Z, corrected again; actually...") or duplicated (the same
gotcha re-discovered and re-appended because the last few entries got long
enough that the new discovery didn't obviously match an old one on a skim).

Ralph's original pattern tolerates this because a single long-running loop
either accepts the cost or the human running it manually edits the file
between sessions. This kit has no equivalent manual step, and per-story
review already happens at a human-gated checkpoint (Phase 5) — the natural
place to also offer garbage collection, rather than leaving it to whoever
notices the file has gotten long.

## Decision

`learnings.md` stays append-only for `implementor`/`debugger` mid-story —
that invariant is what lets them write to it without pausing for a gate, and
it is not weakened by this ADR. What's added is a separate, periodic,
human-approved compaction pass that only the `develop-feature` orchestrator
offers and performs — never a sub-agent, and never unattended:

1. **Trigger point: the Phase 5 checkpoint.** Once a story's Review row is
   committed to `decision-log.md` (`phase-5-review.md` step 3/4), before
   moving to the next story's Phase 3.7, the orchestrator reads the current
   `learnings.md` and decides whether it's worth compacting — real
   duplication or bloat (repeated variants of the same gotcha, entries about
   a command an approved `AGENTS.md` correction has already fixed), not just
   "it has entries." A short, still-distinct file is left alone; compaction
   is an offer, not a mandatory step every story.
2. **What compaction may do:** merge duplicate or near-duplicate entries
   into one; drop an entry whose discovery an **applied** `AGENTS.md`
   correction has already fixed (Phase 4 step 2 or Phase 5 step 2 — the
   proposal was approved and the file already reflects the fix, so the
   entry that flagged the gap has done its job). It may not drop an entry
   just for being old, or one that isn't clearly superseded or duplicated —
   compaction is deduplication and pruning of resolved items, not a size
   trim.
3. **Human approval required, every time.** The orchestrator shows the
   before/after (or a summary of merges/drops for a long file) and only
   rewrites `learnings.md` on explicit approval — the same "propose, human
   approves" gate ADR-0005 already established for `AGENTS.md`
   self-correction, applied to this file instead. Decline leaves the file
   untouched; the story is not blocked either way.
4. **The compaction leaves a trace.** The rewritten file keeps one marker
   entry noting the pass happened, roughly what was merged, and what was
   dropped and why (see `templates/learnings.template.md`'s Compaction
   rules for the exact line format) — so a later read, or a later
   compaction pass, isn't guessing whether entries are just missing.
5. **Resume also checks.** `SKILL.md`'s "Resuming an in-progress feature"
   step now prompts the same offer if a resumed feature's `learnings.md` has
   grown large or repetitive since the last time anyone looked, not only at
   a fresh Phase 5 checkpoint — a Ralph-style feature resumed many times
   across sessions is exactly the case this ADR exists for.

This amends ADR-0005 section 1 (`specs/<NNN>/learnings.md`) only; the rest
of that ADR (gated `AGENTS.md` self-correction, test-intent docstrings,
search-before-create) is unchanged.

## Consequences

- Closes the unbounded-growth gap ADR-0005 left open: a long or
  repeatedly-resumed feature's `learnings.md` no longer grows forever unread
  in full by every fresh `implementor`/`debugger` invocation.
- One more optional step at each Phase 5 checkpoint — cheap when skipped (a
  quick read-and-decline), and it only costs a rewrite when there's real
  duplication or a resolved entry to drop.
- `implementor`/`debugger` are unaffected: they still append freely,
  mid-story, without a gate. The only new constraint is that the file they
  read at the start of a story may occasionally be a compacted version of
  what a prior story left — which is the point.
- Compaction accuracy depends on the orchestrator (not a specialized agent)
  making the merge/drop call. If that proves too coarse in practice —
  merging entries that were actually distinct — the fix is likely a
  dedicated `learnings-compactor` step or agent, not reverting this ADR.

## Alternatives considered

- **Let `implementor`/`debugger` prune their own entries** — rejected:
  reopens exactly the gate ADR-0005 was careful to avoid giving them
  (unattended writes to a shared file with no human check), and a sub-agent
  mid-story has no visibility into what a *different* story's fresh context
  will need next.
- **Auto-compact on a fixed schedule (e.g., every N entries) without human
  approval** — rejected: an automatic merge/drop could silently discard a
  discovery that looked superseded but wasn't (e.g., the "fix" only applies
  to one code path and the original gotcha still applies elsewhere) with no
  one reviewing before it's gone; the whole value of the file is trust that
  what's there is accurate.
- **Keep `learnings.md` strictly append-only forever, accept the growth
  cost** — rejected: this is the status quo ADR-0005 left in place, and it's
  precisely the problem this ADR was written to fix — the file is read in
  full every story, so unbounded growth is an unbounded per-story tax, not
  a one-time cost.
- **Fold compaction into the existing `AGENTS.md` correction approval
  step** — rejected: a correction can be approved without there being
  enough accumulated duplication in `learnings.md` to justify a rewrite, and
  a compaction pass can be worth doing even when no correction was proposed
  this story (e.g., three prior stories independently rediscovered the same
  gotcha in slightly different words). The two are related but not the same
  trigger.
