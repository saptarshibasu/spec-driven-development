#!/usr/bin/env bash
# check-guardrails.sh - drift sensor for the shared "Behavioral guardrails" block.
#
# docs/guardrails.md is the nominal canon for the three universal guardrails
# (No guessing / Investigate before claiming / Conservative by default), but
# every skill and agent embeds its own verbatim copy - editing the canon
# doesn't update anything, and nothing used to catch the two texts drifting
# apart. This script is that sensor.
#
# It extracts the three canonical variants (skill / agent / agent-readonly)
# from the delimited "<!-- GUARDRAILS:<variant> -->" blocks in
# docs/guardrails.md, then compares the first three bullets of every
# "## Behavioral guardrails" section under .agents/agents/*.md and
# .agents/skills/*/SKILL.md against the variant that applies to it:
#
#   - .agents/skills/*/SKILL.md always uses the "skill" variant.
#   - .agents/agents/*.md uses "agent" if its tools: front-matter includes
#     Write or Edit, otherwise "agent-readonly" (it can only return a report).
#
# A skill or agent may append extra bullets after the shared three (e.g.
# develop-feature's "No over-engineering") - those are untouched. Only the
# first three bullets are checked; any difference there (including a skill
# hand-editing the shared wording, as init-project once did) is a hard fail.
#
# Usage: bash scripts/check-guardrails.sh

set -euo pipefail

die() { echo "x $*" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CANON_DOC="$ROOT/docs/guardrails.md"
AGENTS_DIR="$ROOT/.agents/agents"
SKILLS_DIR="$ROOT/.agents/skills"

[ -f "$CANON_DOC" ] || die "$CANON_DOC not found - nothing to check against."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Pull one delimited canonical block out of docs/guardrails.md.
extract_canon() {
  local variant="$1"
  awk -v start="<!-- GUARDRAILS:$variant -->" -v end="<!-- /GUARDRAILS:$variant -->" '
    index($0, start) == 1 { f=1; next }
    index($0, end) == 1 { f=0 }
    f { print }
  ' "$CANON_DOC"
}

for variant in skill agent agent-readonly; do
  extract_canon "$variant" > "$WORK/canon.$variant"
  [ -s "$WORK/canon.$variant" ] \
    || die "docs/guardrails.md has no (or an empty) GUARDRAILS:$variant block."
done

# Pull the first three bullets out of a file's "## Behavioral guardrails"
# section (allowing an optional parenthetical in the heading, and any lead-in
# prose before the first bullet - e.g. develop-feature's "active from Step R
# through Phase 5" paragraph). Trailing blank lines before the next heading
# are trimmed so files with no extra bullets compare cleanly.
extract_section() {
  local file="$1"
  awk '
    /^## Behavioral guardrails/ { insec=1; next }
    insec && /^## / { exit }
    insec {
      if ($0 ~ /^- \*\*/) { bullets++ }
      if (bullets > 3) { exit }
      if (bullets >= 1) { lines[n++] = $0 }
    }
    END {
      while (n > 0 && lines[n-1] ~ /^[[:space:]]*$/) n--
      for (i = 0; i < n; i++) print lines[i]
    }
  ' "$file"
}

# tools: front-matter (single-line scalar) for an agent file.
agent_tools() {
  awk '
    /^---[[:space:]]*\r?$/ { d++; next }
    d==1 && /^tools:/ {
      sub(/^tools:[[:space:]]*/, "")
      sub(/[[:space:]]*\r?$/, "")
      print; exit
    }
  ' "$1"
}

fail=0

check_file() {
  local file="$1" variant="$2" rel
  rel="${file#$ROOT/}"

  [ -f "$file" ] || die "$rel: no such file."
  grep -q '^## Behavioral guardrails' "$file" \
    || { echo "::error::$rel has no '## Behavioral guardrails' section."; fail=1; return; }

  extract_section "$file" > "$WORK/got"
  if ! diff -u "$WORK/canon.$variant" "$WORK/got" > "$WORK/diff.$$"; then
    echo "::error::$rel guardrails section doesn't match the canonical '$variant' block in docs/guardrails.md:"
    cat "$WORK/diff.$$"
    fail=1
  fi
  rm -f "$WORK/diff.$$"
}

# Agents: pick the variant from the tools front-matter (Write/Edit present or not).
shopt -s nullglob
for f in "$AGENTS_DIR"/*.md; do
  tools="$(agent_tools "$f")"
  case "$tools" in
    *Write*|*Edit*) variant=agent ;;
    *)              variant=agent-readonly ;;
  esac
  check_file "$f" "$variant"
done

# Skills: always the "skill" variant.
for f in "$SKILLS_DIR"/*/SKILL.md; do
  check_file "$f" skill
done
shopt -u nullglob

if [ "$fail" -ne 0 ]; then
  echo "::error::Guardrail drift detected. Update docs/guardrails.md's canonical" \
       "GUARDRAILS block first, then copy the exact wording into every file" \
       "listed above (see docs/guardrails.md section Maintenance)." >&2
  exit 1
fi

echo "All agent/skill guardrail sections match their canonical docs/guardrails.md block."
