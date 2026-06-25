<!--
  TEMPLATE — the technical "how," kept separate from spec.md's "what/why."
  One per feature, at specs/<NNN-feature-name>/plan.md. Written AFTER the
  spec is stable, by you providing stack/architecture/constraints and having
  the agent generate the plan against the now-fixed spec.

  Once a section below is filled in, delete its instructional comment along
  with it — including this one, once the plan is ready for review.
-->

# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Spec**: `specs/[###-feature-name]/spec.md`

## Summary

[2-3 sentences: the primary requirement from the spec, and the technical
approach chosen to satisfy it.]

## Technical Context

- **Language/Version**: [e.g., Java 17, Python 3.12, TypeScript 5.x]
- **Primary Dependencies**: [e.g., Spring Boot 3, FastAPI, React 18]
- **Storage**: [e.g., PostgreSQL, Redis, N/A]
- **Testing**: [e.g., JUnit 5 + Testcontainers, pytest, Vitest]
- **Target Platform**: [e.g., internal k8s cluster, iOS 17+]
- **Performance Goals**: [domain-specific, e.g., "p95 < 200ms at 1k rps"]
- **Constraints**: [e.g., "must work offline," "<100MB memory"]
- **Scale/Scope**: [e.g., "10k users," "50k LOC existing codebase"]

## Constitution Check

<!-- GATE: must pass before research/design starts; re-check after. -->

- [ ] Complies with [constitution principle I]
- [ ] Complies with [constitution principle III — test-first]
- [ ] Any violation documented below with justification, not silently ignored

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── spec.md
├── plan.md          # this file
├── research.md      # open questions resolved during planning, if any
├── data-model.md     # if this feature has a data model
├── contracts/         # API/event contracts, if any
└── tasks.md           # generated from this plan, not by it
```

### Source Code (repository root)

```text
[Replace with the real, concrete layout for this feature — actual paths,
not generic placeholders. Delete this comment and the bracket text once
filled in.]
```

**Structure Decision**: [Which layout you chose and why, referencing the
real directories above.]

## Complexity Tracking

> Fill ONLY if the Constitution Check above has a violation that needs
> justifying — leave empty otherwise, don't manufacture content here.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| [e.g., 4th top-level module] | [current need] | [why 3 was insufficient] |
