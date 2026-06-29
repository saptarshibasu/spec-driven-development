# Efficient Code Generation and Performance Pitfalls

This is the reasoning behind `AGENTS.md`'s **Performance & Efficiency**
section. It explains *why* coding agents systematically generate a particular
class of slow code, and what to put in your repo so they stop.

## Why agents default to slow code

A model generates the shape of code that is most common in its training
distribution for a given task description. For "do X to each item," the most
common shape — across the entire public corpus — is a naive per-item loop. The
model is not failing to *know* a better way; nothing in a typical prompt or
spec signals that the *grain* of the operation (per-row vs. bulk) is a design
decision at all. Absent that signal, it produces the statistically average
solution, which is frequently the slow one.

The fix is therefore not "the model should be smarter." It is **context
engineering**: put the signal in the place the model always reads. State your
project's actual performance idioms in `AGENTS.md`, with a real before/after
snippet, so the better shape becomes the one the prompt points to.

This matters because performance is the single most commonly *omitted* section
of real agent context files — present in only a small fraction of them, versus a
large majority for build and architecture sections — even though it measurably
changes output when present. The cheapest performance win available to most
teams is simply *writing the idiom down*.

## The high-frequency, high-cost pitfalls

### 1. Row-by-row instead of bulk (the big one)

The most frequent and most expensive pattern. A loop issuing one query / one
request / one write per item, where a single bulk operation would do.

```text
# Slow — N round trips
for order in orders:
    db.execute("UPDATE orders SET status=? WHERE id=?", (status, order.id))

# Fast — one round trip
db.execute("UPDATE orders SET status=? WHERE id IN (...)", ...)   # or bulk_update / executemany
```

Typical speedup is 3–100× depending on volume and round-trip cost. Name your
stack's actual bulk idiom in `AGENTS.md` (`bulk_create`/`bulk_update`,
`UPDATE ... WHERE id IN (...)`, `executemany`, `saveAll`, a batch endpoint) so
the agent reaches for it by default.

### 2. N+1 queries through an ORM

Fetch a list, then lazily load a relation inside the loop → one query becomes
N+1. Agents introduce this constantly because the lazy-loading code *looks*
clean. The fix is eager loading / a join / a batched fetch. Name the specific
relationships in your repo where this bites, and — crucially — name a
**mechanical detector** (a query-count assertion in a test, or a framework
tool like Bullet / Prosopite) and treat *that* as the enforcement. A prose rule
re-read each session is a far weaker guarantee than a test that fails.

### 3. Re-fetching data already in scope

Calling the same expensive query, API, or computation multiple times in one
flow because each call site fetches independently. Fetch once, pass it down.

### 4. Bypassing an existing cache or index

Going to the source when a cache layer already holds the value, or writing a
query that can't use an existing index. The agent doesn't know the cache or
index exists unless you tell it — so tell it, by name.

### 5. Hand-rolled checks where a utility exists

`x != null && !x.isEmpty()` reinvented per file instead of the project's
null-safety utility (`StringUtils.hasText`, `ObjectUtils.isEmpty`, an
`Optional`/null-safe operator, your own helper). Not always a *speed* problem,
but a consistency-and-correctness one: the utility usually handles edge cases a
bespoke check misses. Name the canonical utility so one doesn't get invented
per file.

## What to actually put in AGENTS.md

The section should be short, specific, and — wherever possible — back every
prose rule with a mechanical sensor. A template:

```markdown
## Performance & Efficiency

- Bulk over row-by-row: use `<your bulk idiom>`, not a per-item loop.
  [before/after snippet from this codebase]. Enforced by `<query-count test>`.
- N+1: eager-load `<relation>` via `<mechanism>`. Detector: `<Bullet/Prosopite/
  query-count assertion>`.
- Null-safety: use `<canonical utility>`, not hand-rolled null checks.
- [Any other recurring inefficiency you've actually seen an agent introduce
  here — real incident + reason +, if possible, the test that catches it.]
```

Two rules of thumb that make this section earn its keep:

1. **A real before/after snippet beats a prose rule** more here than anywhere
   else — it shows the exact shape you want repeated.
2. **Name the enforcement, not just the rule.** Performance regressions are
   exactly the kind of thing that should be a failing test (a query-count
   assertion, a benchmark gate in CI), because they are invisible in a passing
   functional test. Move every rule you can from feedforward prose to a
   computational sensor — see `docs/harness-engineering.md`.

## See also

- `AGENTS.md` → Performance & Efficiency — where this guidance gets applied
  per-repo.
- `docs/harness-engineering.md` — turning prose performance rules into tests
  that fail (computational sensors).
- `docs/token-efficiency.md` — efficiency of the *agent's* token spend, the
  same mindset applied to the generation process rather than the generated code.
