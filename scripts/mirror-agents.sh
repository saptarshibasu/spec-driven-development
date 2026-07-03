#!/usr/bin/env bash
# mirror-agents.sh — propagate canonical agents into every tool directory.
#
# Single source of truth: .agents/agents/. Unlike skills (which are byte-for-byte
# mirrors), each tool reads agents in its own format, so this script GENERATES the
# per-tool file from the canonical definition instead of copying it:
#
#   .agents/agents/<name>.md   (canonical: YAML front-matter + Markdown body)
#     → .claude/agents/<name>.md         Claude Code   (verbatim — same format)
#     → .github/agents/<name>.agent.md   Copilot       (name+description+model front-matter + body)
#     → .codex/agents/<name>.toml        Codex         ([agent] table + instructions)
#
# Run this AFTER you add or edit an agent under .agents/agents/. Never hand-edit a
# generated file in .claude/.github/.codex — it will be overwritten. Edit the
# canonical .md only (ADR-0001). CI re-runs this and fails if the committed files
# drift from a fresh generation.
#
# Fails loudly (exit 1) rather than emitting a subtly-wrong file: unknown tool
# names, front-matter it can't parse as single-line scalars, or a body that would
# break the Codex TOML string are all hard errors.
#
# Idempotent. Cross-platform twin: mirror-agents.ps1 (Windows/PowerShell) — both
# must emit byte-identical files or CI's drift guard will fail.
# Usage: bash scripts/mirror-agents.sh
# (rev: hardened with fail-loud validation)

set -euo pipefail

die() { echo "✖ $*" >&2; exit 1; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CANON="$ROOT/.agents/agents"

if [ ! -d "$CANON" ] || ! ls "$CANON"/*.md >/dev/null 2>&1; then
  die "$CANON has no *.md agents — nothing to mirror."
fi

CLAUDE_DIR="$ROOT/.claude/agents"
COPILOT_DIR="$ROOT/.github/agents"
CODEX_DIR="$ROOT/.codex/agents"
mkdir -p "$CLAUDE_DIR" "$COPILOT_DIR" "$CODEX_DIR"

# Wipe previously generated files (keep .gitkeep) so deletions propagate.
find "$CLAUDE_DIR" "$COPILOT_DIR" "$CODEX_DIR" -type f \
     \( -name '*.md' -o -name '*.toml' \) ! -name '.gitkeep' -delete 2>/dev/null || true

# Map a Claude tool name to its Codex equivalent. Unknown names are a hard error
# so a typo or a newly-introduced tool can't silently pass through mis-mapped.
codex_tool() {
  case "$1" in
    Read)  echo read ;;
    Grep)  echo grep ;;
    Glob)  echo grep ;;
    Bash)  echo shell ;;
    Edit)  echo edit ;;
    Write) echo write ;;
    *)     die "unknown tool '$1' (add it to codex_tool() in mirror-agents.{sh,ps1})" ;;
  esac
}

# Map a canonical model tier to Copilot's `model` front-matter value.
# Copilot doesn't understand Claude Code's tier aliases (opus/sonnet); it wants
# model-picker names, and accepts an array tried in order until an available
# model is found — so entries your org hasn't enabled degrade gracefully.
# EDIT the values below to match your org's enabled models
# (https://docs.github.com/en/copilot/reference/ai-models/supported-models).
# Keep in sync with Convert-CopilotModel in mirror-agents.ps1.
copilot_model() {
  case "$1" in
    opus)   echo "['Claude Opus 4.8', 'Claude Sonnet 5']" ;;
    sonnet) echo "['Claude Sonnet 5', 'Claude Sonnet 4.6']" ;;
    haiku)  echo "['Claude Haiku 4.5', 'Claude Sonnet 5']" ;;
    *)      die "unknown model tier '$1' (add it to copilot_model() in mirror-agents.{sh,ps1})" ;;
  esac
}

# Map a canonical model tier to a Codex model + reasoning effort. Codex runs
# OpenAI models, so the tier's intent (strong reasoning vs fast execution) maps
# to model choice + model_reasoning_effort rather than a name-alike. EDIT to
# match the models your Codex plan offers
# (https://developers.openai.com/codex/config-reference). Keep in sync with
# Convert-CodexModel/Convert-CodexEffort in mirror-agents.ps1.
codex_model() {
  case "$1" in
    opus)   echo "gpt-5.4" ;;
    sonnet) echo "gpt-5.4" ;;
    haiku)  echo "gpt-5.4-mini" ;;
    *)      die "unknown model tier '$1' (add it to codex_model() in mirror-agents.{sh,ps1})" ;;
  esac
}
codex_effort() {
  case "$1" in
    opus)   echo "high" ;;
    sonnet) echo "medium" ;;
    haiku)  echo "medium" ;;
    *)      die "unknown model tier '$1' (add it to codex_effort() in mirror-agents.{sh,ps1})" ;;
  esac
}

# Read a single-line front-matter scalar ("key: value"). Returns the raw
# value, surrounding quotes included. Errors if the key is declared but has no
# inline value (e.g. a YAML block list) — single-line scalars only.
frontmatter_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    /^---[[:space:]]*\r?$/ { d++; next }
    d==1 && $0 ~ "^"key":" {
      sub("^"key":[[:space:]]*", "")
      sub(/[[:space:]]*\r?$/, "")
      found=1; print; exit
    }
    END { if (!found) exit 3 }
  ' "$file"
}

# Print the Markdown body (everything after the second `---`).
body_after_frontmatter() {
  awk '
    /^---[[:space:]]*\r?$/ { d++; if (d==2) { started=1; next } }
    started { print }
  ' "$1"
}

Q3="'''"

count=0
for src in "$CANON"/*.md; do
  base="$(basename "$src")"
  head -n1 "$src" | grep -qE '^---[[:space:]]*\r?$' \
    || die "$base does not start with a '---' front-matter block."

  name="$(frontmatter_value "$src" name)"        || die "$base: missing 'name'."
  desc="$(frontmatter_value "$src" description)"  || die "$base: missing 'description'."
  tools="$(frontmatter_value "$src" tools)"       || die "$base: missing 'tools'."
  model="$(frontmatter_value "$src" model)"       || die "$base: missing 'model'."

  [ -n "$name" ]  || die "$base: 'name' is empty."
  [ -n "$desc" ]  || die "$base: 'description' is empty."
  [ -n "$tools" ] || die "$base: 'tools' is empty (block-list YAML is unsupported — use 'tools: A, B')."
  [ -n "$model" ] || die "$base: 'model' is empty."
  [ "$name" = "$(basename "$src" .md)" ] \
    || die "$base: front-matter name '$name' must match the filename."

  body="$(body_after_frontmatter "$src")"
  case "$body" in
    *"$Q3"*) die "$base: body contains a triple single-quote, which would break the Codex TOML string." ;;
  esac

  # 1) Claude — canonical format, copied verbatim.
  cp "$src" "$CLAUDE_DIR/$name.md"

  # 2) Copilot — name + description + mapped model in front-matter, then the body.
  {
    printf -- '---\n'
    printf 'name: %s\n' "$name"
    printf 'description: %s\n' "$desc"
    printf 'model: %s\n' "$(copilot_model "$model")"
    printf -- '---\n'
    body_after_frontmatter "$src"
  } > "$COPILOT_DIR/$name.agent.md"

  # 3) Codex — TOML table. Tools mapped + de-duplicated; body as instructions.
  codex_tools=""
  seen=" "
  IFS=',' read -ra _tools <<< "$tools"
  for t in "${_tools[@]}"; do
    t="$(printf '%s' "$t" | xargs)"; [ -z "$t" ] && continue
    ct="$(codex_tool "$t")"
    case "$seen" in
      *" $ct "*) ;;
      *) codex_tools="${codex_tools:+$codex_tools, }\"$ct\""
         seen="$seen$ct " ;;
    esac
  done
  # YAML double-quoted scalar: strip the outer quotes — its \" and \\ escapes
  # are already valid TOML basic-string escapes, so the inner text passes
  # through verbatim. Plain (unquoted) scalar: escape it for TOML.
  case "$desc" in
    \"*\") esc_desc="${desc#\"}"; esc_desc="${esc_desc%\"}" ;;
    *)     esc_desc="$(printf '%s' "$desc" | sed 's/\\/\\\\/g; s/"/\\"/g')" ;;
  esac
  {
    printf '# Codex custom agent - generated from .agents/agents/%s by mirror-agents.\n' "$base"
    printf '# Do not hand-edit; edit the canonical .md and re-run the mirror (ADR-0001).\n\n'
    printf '[agent]\n'
    printf 'name = "%s"\n' "$name"
    printf 'description = "%s"\n' "$esc_desc"
    printf '# Mapped from canonical tier "%s" - adjust the tier mapping in scripts/mirror-agents.{sh,ps1}.\n' "$model"
    printf 'model = "%s"\n' "$(codex_model "$model")"
    printf 'model_reasoning_effort = "%s"\n' "$(codex_effort "$model")"
    printf 'tools = [%s]\n\n' "$codex_tools"
    printf 'instructions = %s\n' "$Q3"
    body_after_frontmatter "$src"
    printf '%s' "$Q3"
  } > "$CODEX_DIR/$name.toml"

  count=$((count + 1))
done

echo "Mirrored $count agent(s) → .claude (.md), .github (.agent.md), .codex (.toml)"
