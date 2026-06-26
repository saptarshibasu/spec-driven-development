#!/usr/bin/env bash
# setup.sh — scaffold the spec-driven development folder structure.
#
# Run once per project, from the project root. It creates the directory
# skeleton, seeds the thin pointer/constitution/glossary stubs if they are
# missing, and mirrors the canonical skills into every tool directory so all
# agents see the same definitions. Then it prints what to do next.
#
# Design note: this script is DRY by construction. The skills it installs are
# NOT embedded here — there is exactly one canonical copy, under `.agents/`,
# and the others (`.claude/`, `.github/`, `.codex/`) are mirrored from it.
# Editing a skill means editing the `.agents/` copy and re-running this script,
# never hand-editing one of the mirrors (see docs/adr/0001-*).
#
# Idempotent: safe to re-run. It never overwrites a filled-in AGENTS.md,
# constitution, or glossary.
#
# Usage: bash setup.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "Setting up spec-driven development structure in: $ROOT"
echo ""

# ── Directory skeleton ──────────────────────────────────────────────────────

mkdir -p \
  "$ROOT/.agents/skills" \
  "$ROOT/.github/instructions" \
  "$ROOT/.github/skills" \
  "$ROOT/.github/agents" \
  "$ROOT/.github/workflows" \
  "$ROOT/.claude/skills" \
  "$ROOT/.claude/agents" \
  "$ROOT/.codex/skills" \
  "$ROOT/.codex/agents" \
  "$ROOT/memory" \
  "$ROOT/specs/contracts" \
  "$ROOT/docs/adr" \
  "$ROOT/src" \
  "$ROOT/tests/contract" \
  "$ROOT/tests/integration" \
  "$ROOT/tests/unit" \
  "$ROOT/tests/characterization"

# ── .gitkeep for intentionally empty directories ────────────────────────────

for dir in \
  ".github/workflows" \
  "specs/contracts" \
  "src" \
  "tests/contract" \
  "tests/integration" \
  "tests/unit" \
  "tests/characterization"; do
  [ -z "$(ls -A "$ROOT/$dir" 2>/dev/null)" ] && touch "$ROOT/$dir/.gitkeep"
done

# ── AGENTS.md (must come from this kit — never fabricate it) ─────────────────

if [ ! -f "$ROOT/AGENTS.md" ]; then
  echo "  ⚠  AGENTS.md is missing. Copy it from this starter kit's root into"
  echo "     your project — it is the canonical instruction file and this"
  echo "     script will not invent one. (It is its own template; fill in the"
  echo "     bracketed placeholders after copying.)"
fi

# ── Tool pointer files (thin redirects to AGENTS.md) ────────────────────────

if [ ! -f "$ROOT/CLAUDE.md" ]; then
  cat > "$ROOT/CLAUDE.md" <<'EOF'
<!-- This file is a thin pointer. All agent instructions live in AGENTS.md. -->
See [AGENTS.md](./AGENTS.md) for all project conventions, boundaries, and context.
EOF
  echo "  Created CLAUDE.md (pointer)"
fi

if [ ! -f "$ROOT/.github/copilot-instructions.md" ]; then
  cat > "$ROOT/.github/copilot-instructions.md" <<'EOF'
<!-- This file is a thin pointer. All agent instructions live in AGENTS.md. -->
See [AGENTS.md](../AGENTS.md) for all project conventions, boundaries, and context.
EOF
  echo "  Created .github/copilot-instructions.md (pointer)"
fi

# ── Path-scoped Copilot instruction example ──────────────────────────────────

if [ ! -f "$ROOT/.github/instructions/sample.instructions.md" ]; then
  cat > "$ROOT/.github/instructions/sample.instructions.md" <<'EOF'
---
applyTo: "src/**"
---
<!-- Path-scoped rules for src/. Injected ONLY when working on matching files,
     so subtree-specific rules cost no tokens elsewhere. Global conventions
     stay in AGENTS.md — do not duplicate them here. Rename per subtree. -->
EOF
  echo "  Created .github/instructions/sample.instructions.md"
fi

# ── Constitution stub (seeded from template, never overwritten) ──────────────

if [ ! -f "$ROOT/memory/constitution.md" ]; then
  if [ -f "$ROOT/templates/constitution.template.md" ]; then
    cp "$ROOT/templates/constitution.template.md" "$ROOT/memory/constitution.md"
    echo "  Created memory/constitution.md — fill in the bracketed placeholders"
  else
    echo "  ⚠  templates/constitution.template.md missing — cannot seed constitution"
  fi
fi

# ── Glossary stub ────────────────────────────────────────────────────────────

if [ ! -f "$ROOT/docs/glossary.md" ]; then
  cat > "$ROOT/docs/glossary.md" <<'EOF'
# Glossary

Domain-specific terms for this project. Referenced from AGENTS.md —
do not inline into AGENTS.md directly.

| Term | Definition |
|------|-----------|
|      |           |
EOF
  echo "  Created docs/glossary.md"
fi

# ── Mirror canonical skills (.agents → .claude, .github, .codex) ────────────
#
# Single source of truth: .agents/skills/. The other tool directories are
# byte-for-byte mirrors so every agent runtime sees identical definitions.

CANON="$ROOT/.agents/skills"
if [ -d "$CANON" ] && [ -n "$(ls -A "$CANON" 2>/dev/null)" ]; then
  for tool_skills in \
    "$ROOT/.claude/skills" \
    "$ROOT/.github/skills" \
    "$ROOT/.codex/skills"; do
    mkdir -p "$tool_skills"
    # Copy each canonical skill dir over, preserving the executable bit on scripts.
    for skill_path in "$CANON"/*/; do
      skill_name="$(basename "$skill_path")"
      rm -rf "${tool_skills:?}/$skill_name"
      cp -R "$skill_path" "$tool_skills/$skill_name"
    done
  done
  # Ensure any bundled scripts stay executable across all copies.
  find "$ROOT/.agents/skills" "$ROOT/.claude/skills" \
       "$ROOT/.github/skills" "$ROOT/.codex/skills" \
       -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  echo "  Mirrored skills from .agents/skills into .claude, .github, .codex"
else
  echo "  ⚠  .agents/skills is empty — copy this kit's .agents/skills/ in first."
  echo "     Skills were NOT mirrored. (This kit ships spec-driven-feature and"
  echo "     create-constitution there.)"
fi

# ── Custom agent example stubs (only if absent) ──────────────────────────────

if [ ! -f "$ROOT/.claude/agents/code-reviewer.md" ] && \
   [ -z "$(ls -A "$ROOT/.claude/agents" 2>/dev/null | grep -v '^\.gitkeep$' || true)" ]; then
  echo "  ℹ  No custom agents found. This kit ships example agents"
  echo "     (.claude/agents/code-reviewer.md, .github/agents/docs-agent.agent.md,"
  echo "     .codex/agents/reviewer.toml) — copy them in if you want them."
fi

# ── Keep agent dirs tracked when empty ───────────────────────────────────────

for dir in ".github/agents" ".claude/agents" ".codex/agents"; do
  [ -z "$(ls -A "$ROOT/$dir" 2>/dev/null)" ] && touch "$ROOT/$dir/.gitkeep"
done

echo ""
echo "Done. Next steps:"
echo ""
echo "  1. Fill in AGENTS.md — replace every [bracketed placeholder] with a"
echo "     fact specific to your repo. Delete generic lines and the comments."
echo ""
echo "  2. Ratify memory/constitution.md — project-wide principles. Use the"
echo "     create-constitution skill, or edit templates/constitution.template.md."
echo ""
echo "  3. Add domain terms to docs/glossary.md."
echo ""
echo "  4. Skim docs/ — context-engineering, harness-engineering, token-efficiency,"
echo "     model routing, and performance pitfalls explain the 'why' behind this"
echo "     structure and what to wire up next (tests, lint, CI)."
echo ""
echo "  5. Start your first feature with the spec-driven-feature skill, or:"
echo "     .agents/skills/spec-driven-feature/scripts/start-feature.sh \"<description>\""
echo ""
echo "  6. Commit everything: git add -A && git commit -m \"chore: add SDD structure\""
