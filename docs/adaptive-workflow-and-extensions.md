# Adaptive Workflow & Extensions

Two related ideas let this kit scale its rigor to the work in front of it
instead of applying one fixed ceremony to everything: **workflow tracks** (adapt
the *breadth and depth* of the pipeline) and **opt-in extensions** (adapt the
*constraints* a feature must satisfy). Both are driven by the
`spec-driven-feature` skill and recorded in each feature's `decision-log.md`.

Both are adapted from AWS Labs' **AI-DLC** (AI-Driven Development Life Cycle,
MIT-0) — specifically its principle that an AI-native workflow should *adapt to
the problem rather than force the problem to adapt to the process*, and its
opt-in extension mechanism. See ADR-0002 for what we took, what we changed, and
why.

## Why adapt at all

A fixed spec → plan → tasks pipeline is the right default, but applied to *every*
change it produces two failure modes:

- **Over-ceremony on the small stuff.** A one-line config fix does not need a
  problem statement, user stories, and a constitution gate review. Generating
  them wastes tokens and trains everyone to rubber-stamp gates — which erodes the
  gates that matter.
- **Under-rigor on the big stuff.** A new service or a change to untested legacy
  code needs *more* than the default: research, a data model, characterization
  tests, an ADR. A flat pipeline gives it the same depth as a CRUD endpoint.

The fix is to make depth a **decision the agent proposes and the human approves**,
once, at the start — not a constant. This keeps the kit's core discipline ("earn
every token") while preserving human-in-the-loop control.

## The four tracks

| Track | Use when | Artifacts | Model |
|---|---|---|---|
| **A · Trivial — Direct change** | Trivial, localized, no design choice (typo, copy, config value, dep bump, obvious one-liner) | None — no feature folder; rationale in the commit message | Fast/cheap |
| **B · Simple — Patch** | Localized bug fix or small enhancement, no new architecture | `spec.md` (short) + `tasks.md`; **no `plan.md`** | Mid-tier |
| **C · Moderate — Feature** *(default)* | A normal new capability | Full `spec.md` + `plan.md` + `tasks.md` | Strong for Specify/Plan |
| **D · Complex — Architecture / brownfield** | New service, cross-cutting change, or touching untested legacy | Full pipeline + `research.md`/`data-model.md` as needed + **ADR** + characterization tests first | Strongest |

The agent recommends exactly one track with a one-line rationale and the precise
artifact list; the human confirms or overrides. The choice — and any later
promotion (B→C when a design decision surfaces) — is logged. When unsure between
two tracks, the agent picks the heavier one; over-rigor is cheaper to trim than
under-rigor is to recover.

This is the breadth-and-depth elasticity AI-DLC calls "Principle 10 (no
hard-wired, opinionated workflows)," expressed as four named, reviewable tracks
rather than a free-form judgment, so the routing itself is auditable.

The track also governs the **Analyze gate** — the non-destructive spec ↔ plan ↔
tasks cross-check that runs before implementation: skipped on A, a light
spec↔tasks pass on B, run on C, run extended on D. Same principle, depth scales
with the work. See `docs/adr/0003-analyze-gate.md`.

## Opt-in extensions

An **extension** is a pack of blocking rules layered onto a feature on demand —
security, compliance, property-based testing, accessibility. The mechanism and
authoring format live in `.agents/extensions/README.md`; the short version:

- Each pack is a rules file (`<pack>.md`, rules with stable IDs like `SEC-01` and
  a **Verification** section) plus a tiny `<pack>.opt-in.md` question.
- At feature start the skill scans only the `*.opt-in.md` prompts and asks the
  human. Opting in loads the full rules and makes them **blocking** at every gate
  and at review; opting out (also recorded) loads nothing. A pack with no opt-in
  file is always enforced.
- The `code-reviewer` agent re-checks opted-in rules by ID; an unmet
  Verification condition is a Blocker unless the decision log shows a human
  accepted the risk.

This is how a security or compliance regime enters the workflow without taxing
`AGENTS.md` or the constitution — which are read on *every* call — with rules
that only some features need.

### Where extensions sit in the harness

Extensions are **feedback sensors** (see `harness-engineering.md`) that the route
turns on selectively. Today they're mostly *inferential* — the model checks each
Verification condition — but every rule is written so its checks can be promoted
to a *computational* control (a SAST job, a lint rule, a CI gate) as you build
one. That is the kit's standing rule restated: **mechanize what you can, infer
what you must.** The shipped `security/baseline` pack is a directional reference,
not a finished security policy — customise it to your threat model.

## The decision log ties it together

Every adaptive choice is recorded in the feature's committed
`specs/<NNN>/decision-log.md`: the approved track, the extension opt-ins, and
each gate approval, plus any deviation made during implementation. This is the
*end-to-end traceability* AI-DLC emphasizes, and it is deliberately **distinct
from live resume state**, which lives in each document's **Status** header:

| | `decision-log.md` | document **Status** header |
|---|---|---|
| Purpose | Durable record of *what was decided and why* | The live *resume* signal: `Draft` → `Approved` per gate |
| Lifetime | Committed; outlives the feature | Committed with the document; reflects current state |
| Audience | Future agents/humans, audits | The next session that resumes this work |

Cross-cutting decisions (a pattern other features will follow) still go in a full
**ADR** under `docs/adr/`; the decision log just points to the ADR number. The
log is for decisions local to one feature.

## See also

- `.agents/extensions/README.md` — extension authoring format and lifecycle.
- `harness-engineering.md` — guides vs. sensors; where tracks and extensions fit.
- `model-selection-and-token-optimization-in-sdd.md` — per-track model routing.
- `docs/adr/0002-adaptive-workflow-and-extensions.md` — the decision record.

## References

- [Open-sourcing AI-DLC adaptive workflows — AWS](https://aws.amazon.com/blogs/devops/open-sourcing-adaptive-workflows-for-ai-driven-development-life-cycle-ai-dlc/)
- [awslabs/aidlc-workflows](https://github.com/awslabs/aidlc-workflows) (MIT-0)
- [AI-DLC methodology — AWS](https://aws.amazon.com/blogs/devops/ai-driven-development-life-cycle/)
