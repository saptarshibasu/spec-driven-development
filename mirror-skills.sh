#!/usr/bin/env bash
# mirror-skills.sh — propagate canonical skills into every tool directory.
#
# Single source of truth: .agents/skills/. The .claude/, .github/, and .codex/
# skill dirs are byte-for-byte mirrors of it (ADR-0001), because not every
# runtime auto-discovers .agents/ yet. Run this AFTER you add or edit a skill
# under .agents/skills/ — it pushes the change into the three mirrors. Never
# hand-edit a mirror; it will be overwritten.
#
# This is the slimmed successor to the old setup.sh. The scaffolding/seeding
# steps that script used to do were redundant: a fresh clone of this kit already
# carries every directory, pointer, and stub they created (see README Quickstart).
#
# Idempotent. Cross-platform twin: mirror-skills.ps1 (Windows/PowerShell).
# Usage: bash mirror-skills.sh

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CANON="$ROOT/.agents/skills"

if [ ! -d "$CANON" ] || [ -z "$(ls -A "$CANON" 2>/dev/null)" ]; then
  echo "✖ $CANON is empty or missing — nothing to mirror." >&2
  echo "  Copy this kit's .agents/skills/ in first." >&2
  exit 1
fi

for tool_skills in \
  "$ROOT/.claude/skills" \
  "$ROOT/.github/skills" \
  "$ROOT/.codex/skills"; do
  mkdir -p "$tool_skills"
  for skill_path in "$CANON"/*/; do
    skill_name="$(basename "$skill_path")"
    rm -rf "${tool_skills:?}/$skill_name"
    cp -R "$skill_path" "$tool_skills/$skill_name"
  done
done

# Keep bundled shell scripts executable across all copies (.ps1 needs no bit).
find "$CANON" "$ROOT/.claude/skills" "$ROOT/.github/skills" "$ROOT/.codex/skills" \
     -name '*.sh' -exec chmod +x {} + 2>/dev/null || true

echo "Mirrored $(find "$CANON" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skill(s) → .claude, .github, .codex"
