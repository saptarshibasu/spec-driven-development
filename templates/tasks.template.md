<!--
  TEMPLATE — generated FROM plan.md + spec.md, not written from scratch.
  One per feature, at specs/<NNN-feature-name>/tasks.md. Tasks are grouped
  by user story so each story is independently implementable, testable,
  and shippable as its own increment.

  Format: [ID] [P?] [Story] Description, with exact file paths.
  [P] = can run in parallel (different files, no dependency on other [P] tasks
  in the same group). [Story] = which user story (US1, US2...) this task
  belongs to, for traceability.

  Once the task list below is filled in, delete this instructional comment —
  it guided drafting, it is not part of the task list itself.
-->

# Tasks: [FEATURE NAME]

**Input**: `spec.md` (required), `plan.md` (required), `data-model.md` /
`contracts/` if present.

## Phase 1: Setup

- [ ] T001 [Project init / scaffolding per plan.md]
- [ ] T002 [P] [Dependency installation]
- [ ] T003 [P] [Lint/format config]

## Phase 2: Foundational (blocks all user stories)

**⚠️ No user-story work starts until this phase is complete.**

- [ ] T004 [Shared schema/migration]
- [ ] T005 [P] [Shared auth/middleware, if needed]
- [ ] T006 [Base models all stories depend on]

**Checkpoint**: foundation ready — user stories can now proceed, in parallel
if staffed.

## Phase 3: User Story 1 — [Title] (Priority: P1) 🎯 MVP

**Goal**: [what this story delivers, one line]
**Independent Test**: [how to verify this story on its own]

### Tests for User Story 1 — write first, confirm they fail

- [ ] T007 [P] [US1] Contract test for [endpoint] in `tests/contract/...`
- [ ] T008 [P] [US1] Integration test for [user journey] in `tests/integration/...`

### Implementation for User Story 1

- [ ] T009 [P] [US1] [Model] in `src/models/...`
- [ ] T010 [US1] [Service] in `src/services/...` (depends on T009)
- [ ] T011 [US1] [Endpoint/feature] in `src/...`
- [ ] T012 [US1] Validation + error handling
- [ ] T013 [US1] Logging for this story's operations

**Checkpoint**: User Story 1 is fully functional and independently testable.

## Phase 4: User Story 2 — [Title] (Priority: P2)

[Same shape as Phase 3.]

**Checkpoint**: User Stories 1 and 2 both work independently.

## Phase N: Polish & Cross-Cutting

- [ ] [Docs updates]
- [ ] [Refactoring/cleanup]
- [ ] [Performance pass across all stories]
- [ ] [Security hardening]

## Dependencies

- Setup → Foundational → (User stories, parallel or priority order) → Polish
- Within a story: tests before implementation; models before services;
  services before endpoints; story complete before moving to the next.

## Implementation Strategy

**MVP first**: Setup → Foundational → User Story 1 only → stop, validate,
deploy/demo if ready, *then* continue to the next story. Don't build all
stories before validating the first one works end-to-end.
