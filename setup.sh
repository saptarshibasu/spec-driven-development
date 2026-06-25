#!/usr/bin/env bash
# setup.sh — scaffold the spec-driven development folder structure.
#
# Run once per project, from the project root. It creates every directory
# and stub file in the reference structure, then prints what to do next.
#
# Usage: bash setup.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "Setting up spec-driven development structure in: $ROOT"
echo ""

# ── Directory skeleton ──────────────────────────────────────────────────────

mkdir -p \
  "$ROOT/.github/instructions" \
  "$ROOT/.github/skills/spec-driven-feature/scripts" \
  "$ROOT/.github/agents" \
  "$ROOT/.github/workflows" \
  "$ROOT/.claude/skills/spec-driven-feature/scripts" \
  "$ROOT/.claude/agents" \
  "$ROOT/.codex/skills/spec-driven-feature/scripts" \
  "$ROOT/.codex/agents" \
  "$ROOT/memory" \
  "$ROOT/specs/contracts" \
  "$ROOT/docs/adr" \
  "$ROOT/tests/contract" \
  "$ROOT/tests/integration" \
  "$ROOT/tests/unit" \
  "$ROOT/tests/characterization"

# ── .gitkeep for intentionally empty directories ────────────────────────────

for dir in \
  ".github/workflows" \
  "specs/contracts" \
  "docs/adr" \
  "tests/contract" \
  "tests/integration" \
  "tests/unit" \
  "tests/characterization"; do
  touch "$ROOT/$dir/.gitkeep"
done

# ── AGENTS.md (if not present — don't overwrite a filled-in one) ────────────

if [ ! -f "$ROOT/AGENTS.md" ]; then
  cp "$ROOT/templates/constitution.template.md" "$ROOT/AGENTS.md" 2>/dev/null || true
  echo "  Created AGENTS.md — fill in the bracketed placeholders"
fi

# ── Tool pointer files ───────────────────────────────────────────────────────

if [ ! -f "$ROOT/CLAUDE.md" ]; then
  cat > "$ROOT/CLAUDE.md" <<'EOF'
<!-- This file is a thin pointer. All agent instructions live in AGENTS.md. -->
See [AGENTS.md](./AGENTS.md) for all project conventions, boundaries, and context.
EOF
fi

if [ ! -f "$ROOT/.github/copilot-instructions.md" ]; then
  cat > "$ROOT/.github/copilot-instructions.md" <<'EOF'
<!-- This file is a thin pointer. All agent instructions live in AGENTS.md. -->
See [AGENTS.md](../AGENTS.md) for all project conventions, boundaries, and context.
EOF
fi

# ── Path-scoped Copilot instruction example ──────────────────────────────────

if [ ! -f "$ROOT/.github/instructions/sample.instructions.md" ]; then
  cat > "$ROOT/.github/instructions/sample.instructions.md" <<'EOF'
---
applyTo: "src/**"
---
<!-- Path-scoped rules for src/. See AGENTS.md for global conventions. -->
<!-- Example: specific coding patterns, file naming rules for this subtree. -->
EOF
fi

# ── Constitution stub ────────────────────────────────────────────────────────

if [ ! -f "$ROOT/memory/constitution.md" ]; then
  cp "$ROOT/templates/constitution.template.md" "$ROOT/memory/constitution.md"
  echo "  Created memory/constitution.md — fill in the bracketed placeholders"
fi

# ── Spec-driven-feature SKILL.md (all three tool directories) ───────────────

SKILL_CONTENT='---
name: spec-driven-feature
description: Use when starting spec-driven development on a new feature — triggers on phrases like "create a spec for X", "let'\''s spec out Y", "start a new feature: Z", "use SDD for this", or "write a spec before we code". Scaffolds a new specs/<NNN-feature-slug>/ folder from this project'\''s templates/ folder and walks Specify -> Plan -> Tasks, asking for explicit approval before each phase. Do not use for a trivial one-line fix — ask the user first if it'\''s unclear whether this task needs one.
---

# Spec-Driven Feature

Runs the Specify → Plan → Tasks workflow described in this project'\''s
`AGENTS.md`, populating `specs/<NNN-feature-slug>/{spec.md,plan.md,tasks.md}`
from the canonical templates in `templates/`. Three gated phases — never
skip a gate, and never merge two phases into one turn.

## Before starting

Confirm `templates/spec.template.md`, `templates/plan.template.md`, and
`templates/tasks.template.md` exist at the project root. If they do not,
stop and tell the user to copy this repo'\''s `templates/` folder first.

## Step 0 — Scaffold

Run the bundled script from this skill'\''s own directory:

```bash
scripts/start-feature.sh "<feature description>"
```

Claude Code exposes this skill'\''s directory as `${CLAUDE_SKILL_DIR}`.
Other tools: use whatever path your tool gives you to this skill'\''s folder.

If bash is unavailable: find the highest `NNN-` prefix under `specs/`,
increment it, slugify the description into kebab-case, create
`specs/<NNN>-<slug>/`, and copy the three templates in as `spec.md`,
`plan.md`, `tasks.md`.

## Phase 1 — Specify

1. Open the newly created `spec.md`.
2. Fill in Problem Statement, User Stories (P1/P2/...), Acceptance Scenarios,
   Edge Cases, Functional and Non-Functional Requirements, Success Criteria,
   and Out of Scope.
3. Mark anything unspecified as `[NEEDS CLARIFICATION: question]` — never
   silently invent an assumption.
4. Run the Spec Completeness Checklist before presenting the draft.
5. **Stop. Ask for explicit approval before touching `plan.md`.**

## Phase 2 — Plan

Only after Phase 1 is approved.

1. Read `AGENTS.md` (tech stack, conventions) and `memory/constitution.md`
   (architectural principles).
2. Fill in Technical Context, Project Structure, and the Constitution Check.
   If anything fails the check, fill in Complexity Tracking with justification.
3. **Stop. Ask for explicit approval before touching `tasks.md`.**

## Phase 3 — Tasks

Only after Phase 2 is approved.

1. Read the approved `spec.md` and `plan.md`.
2. Generate `tasks.md`: Setup → Foundational → User Story 1 (MVP) →
   User Story 2 → ... → Polish. Mark parallel tasks `[P]`. Test tasks
   come before implementation tasks within every story.
3. **Stop.** Tell the user the artifacts are ready and implementation
   can begin phase by phase. Do not start writing code.

## What this skill deliberately does not do

- Write source code — only `spec.md`, `plan.md`, and `tasks.md`.
- Skip a gate without making the user explicitly aware of the choice.
- Invent templates — see "Before starting."
'

for skill_dir in \
  ".github/skills/spec-driven-feature" \
  ".claude/skills/spec-driven-feature" \
  ".codex/skills/spec-driven-feature"; do
  if [ ! -f "$ROOT/$skill_dir/SKILL.md" ]; then
    echo "$SKILL_CONTENT" > "$ROOT/$skill_dir/SKILL.md"
    echo "  Created $skill_dir/SKILL.md"
  fi
done

# ── start-feature.sh (all three tool directories) ───────────────────────────

SCRIPT_CONTENT='#!/usr/bin/env bash
# start-feature.sh — deterministic scaffolding for a new spec-driven feature.
#
# Picks the next feature number, slugifies the description, creates
# specs/<NNN-slug>/, and copies the three canonical templates into it with
# the header fields pre-filled. Does NOT write spec/plan/task content —
# that is the agent'"'"'s job, per SKILL.md.
#
# Usage: start-feature.sh "<feature description>"

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: start-feature.sh \"<feature description>\"" >&2
  exit 1
fi

DESCRIPTION="$*"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPECS_DIR="$REPO_ROOT/specs"
TEMPLATES_DIR="$REPO_ROOT/templates"

for f in spec.template.md plan.template.md tasks.template.md; do
  if [ ! -f "$TEMPLATES_DIR/$f" ]; then
    echo "Missing $TEMPLATES_DIR/$f — copy this repo'\''s templates/ folder first." >&2
    exit 1
  fi
done

mkdir -p "$SPECS_DIR"

LAST_NUM=$(find "$SPECS_DIR" -maxdepth 1 -type d -name '"'"'[0-9][0-9][0-9]-*'"'"' 2>/dev/null \
  -exec basename {} \; | sed -E '"'"'s/^([0-9]{3})-.*/\1/'"'"' | sort -n | tail -1)
if [ -z "$LAST_NUM" ]; then
  NEXT_NUM="001"
else
  NEXT_NUM=$(printf "%03d" $((10#$LAST_NUM + 1)))
fi

SLUG=$(echo "$DESCRIPTION" \
  | tr '"'"'[:upper:]'"'"' '"'"'[:lower:]'"'"' \
  | tr -cs '"'"'a-z0-9'"'"' '"'"'-'"'"' \
  | sed -E '"'"'s/^-+//; s/-+$//'"'"' \
  | cut -d'"'"'-'"'"' -f1-5)

FEATURE_SLUG="${NEXT_NUM}-${SLUG}"
FEATURE_DIR="$SPECS_DIR/$FEATURE_SLUG"

if [ -d "$FEATURE_DIR" ]; then
  echo "Refusing to overwrite existing $FEATURE_DIR" >&2
  exit 1
fi
mkdir -p "$FEATURE_DIR/contracts"

TODAY="$(date +%Y-%m-%d)"
for doc in spec plan tasks; do
  cp "$TEMPLATES_DIR/${doc}.template.md" "$FEATURE_DIR/${doc}.md"
  sed -i.bak \
    -e "s/\[###-feature-name\]/${FEATURE_SLUG}/g" \
    -e "s/\[FEATURE NAME\]/${DESCRIPTION}/g" \
    -e "s/\[FEATURE\]/${DESCRIPTION}/g" \
    -e "s/\[DATE\]/${TODAY}/g" \
    "$FEATURE_DIR/${doc}.md"
  rm -f "$FEATURE_DIR/${doc}.md.bak"
done

echo "Created $FEATURE_DIR"
echo "  spec.md   <- fill in next (Phase 1: Specify)"
echo "  plan.md   <- do not fill in until spec.md is approved"
echo "  tasks.md  <- do not fill in until plan.md is approved"
'

for scripts_dir in \
  ".github/skills/spec-driven-feature/scripts" \
  ".claude/skills/spec-driven-feature/scripts" \
  ".codex/skills/spec-driven-feature/scripts"; do
  if [ ! -f "$ROOT/$scripts_dir/start-feature.sh" ]; then
    echo "$SCRIPT_CONTENT" > "$ROOT/$scripts_dir/start-feature.sh"
    chmod +x "$ROOT/$scripts_dir/start-feature.sh"
    echo "  Created $scripts_dir/start-feature.sh"
  fi
done

# ── Custom agent stubs ───────────────────────────────────────────────────────

if [ ! -f "$ROOT/.github/agents/docs-agent.agent.md" ]; then
  cat > "$ROOT/.github/agents/docs-agent.agent.md" <<'EOF'
# docs-agent

<!-- Copilot custom agent for documentation tasks.
     Selectable from the agent-picker in VS Code, via `/agent`,
     plain language, or `--agent=` in the CLI.
     See AGENTS.md for scope and boundaries. -->
EOF
fi

if [ ! -f "$ROOT/.claude/agents/code-reviewer.md" ]; then
  cat > "$ROOT/.claude/agents/code-reviewer.md" <<'EOF'
# code-reviewer

<!-- Claude Code custom agent for code review.
     See AGENTS.md for scope and boundaries. -->
EOF
fi

if [ ! -f "$ROOT/.codex/agents/reviewer.toml" ]; then
  cat > "$ROOT/.codex/agents/reviewer.toml" <<'EOF'
[agent]
name = "reviewer"
# Codex custom agent for code review. See AGENTS.md for scope.
EOF
fi

# ── docs/glossary.md ─────────────────────────────────────────────────────────

if [ ! -f "$ROOT/docs/glossary.md" ]; then
  cat > "$ROOT/docs/glossary.md" <<'EOF'
# Glossary

Domain-specific terms for this project. Referenced from AGENTS.md —
do not inline into AGENTS.md directly.

| Term | Definition |
|------|-----------|
|      |           |
EOF
fi

echo ""
echo "Done. Next steps:"
echo ""
echo "  1. Fill in AGENTS.md — replace every [bracketed placeholder]"
echo "     with a fact specific to your repo. Delete generic lines."
echo ""
echo "  2. Fill in memory/constitution.md — project-wide principles."
echo "     Use templates/constitution.template.md as the starting point."
echo ""
echo "  3. Add domain terms to docs/glossary.md."
echo ""
echo "  4. Start your first feature:"
echo "     .github/skills/spec-driven-feature/scripts/start-feature.sh \"<description>\""
echo ""
echo "  5. Commit everything: git add -A && git commit -m \"chore: add SDD structure\""
