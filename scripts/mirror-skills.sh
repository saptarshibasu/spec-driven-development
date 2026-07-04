#!/usr/bin/env bash
# mirror-skills.sh — propagate canonical skills into every tool directory.
#
# Single source of truth: .agents/skills/. The .claude/, .github/, and .codex/
# skill dirs are mirrors of it (ADR-0001), because not every runtime
# auto-discovers .agents/ yet. Run this AFTER you add or edit a skill under
# .agents/skills/ — it pushes the change into the three mirrors. Never
# hand-edit a mirror; it will be overwritten.
#
# Every file is copied byte-for-byte EXCEPT each skill's top-level SKILL.md,
# whose empty `<!-- GUARDRAILS:skill --><!-- /GUARDRAILS:skill -->` marker
# (see docs/guardrails.md) gets expanded with the canonical "No guessing /
# Investigate before claiming / Conservative by default" bullets at mirror
# time. The canonical .agents/skills/*/SKILL.md never carries the bullets
# itself — there is nothing to hand-copy and nothing left to drift.
#
# This is the slimmed successor to the old setup.sh. The scaffolding/seeding
# steps that script used to do were redundant: a fresh clone of this kit already
# carries every directory, pointer, and stub they created (see README Quickstart).
#
# Idempotent. Cross-platform twin: mirror-skills.ps1 (Windows/PowerShell).
# Usage: bash scripts/mirror-skills.sh

set -euo pipefail

die() { echo "✖ $*" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CANON="$ROOT/.agents/skills"
GUARDRAILS_DOC="$ROOT/docs/guardrails.md"

if [ ! -d "$CANON" ] || [ -z "$(ls -A "$CANON" 2>/dev/null)" ]; then
  echo "✖ $CANON is empty or missing — nothing to mirror." >&2
  echo "  Copy this kit's .agents/skills/ in first." >&2
  exit 1
fi

[ -f "$GUARDRAILS_DOC" ] || die "$GUARDRAILS_DOC not found — guardrails canon is missing."

# Pull the canonical "skill" guardrails block out of docs/guardrails.md.
GUARDRAILS_SKILL_CANON="$(awk -v start="<!-- GUARDRAILS:skill -->" -v end="<!-- /GUARDRAILS:skill -->" '
  index($0, start) == 1 { f=1; next }
  index($0, end) == 1 { f=0 }
  f { print }
' "$GUARDRAILS_DOC")"
[ -n "$GUARDRAILS_SKILL_CANON" ] || die "$GUARDRAILS_DOC has no (or an empty) GUARDRAILS:skill block."

# Expand a mirrored SKILL.md's empty guardrails marker in place. Fails loudly
# if the marker is missing (or was hand-edited into a stale copy instead) so
# an unmirrored guardrails edit can't silently ship.
expand_skill_guardrails() {
  local file="$1"
  grep -qF '<!-- GUARDRAILS:skill -->' "$file" \
    || die "$file: missing a '<!-- GUARDRAILS:skill --> ... <!-- /GUARDRAILS:skill -->' marker pair."
  local tmp
  tmp="$(mktemp)"
  awk -v start="<!-- GUARDRAILS:skill -->" -v end="<!-- /GUARDRAILS:skill -->" -v canon="$GUARDRAILS_SKILL_CANON" '
    index($0, start) == 1 { print; print canon; f=1; next }
    index($0, end) == 1 { f=0 }
    !f { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

for tool_skills in \
  "$ROOT/.claude/skills" \
  "$ROOT/.github/skills" \
  "$ROOT/.codex/skills"; do
  mkdir -p "$tool_skills"
  for skill_path in "$CANON"/*/; do
    skill_name="$(basename "$skill_path")"
    rm -rf "${tool_skills:?}/$skill_name"
    cp -R "$skill_path" "$tool_skills/$skill_name"
    skill_md="$tool_skills/$skill_name/SKILL.md"
    [ -f "$skill_md" ] || die "$skill_md missing after mirroring $skill_name."
    expand_skill_guardrails "$skill_md"
  done
done

echo "Mirrored $(find "$CANON" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skill(s) → .claude, .github, .codex"
