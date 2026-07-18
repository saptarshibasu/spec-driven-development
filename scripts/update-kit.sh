#!/usr/bin/env bash
# update-kit.sh — copy this kit's kit-owned files into a project.
#
# Run FROM this kit checkout (the script locates its own kit root — it does
# not matter what your shell's cwd is); pass the target project's path as the
# argument. Always copies the kit-owned paths as they stand in this checkout
# right now — there is no version tracking and no comparison against what the
# project already has, beyond a per-file content diff so unchanged files are
# skipped.
#
# The kit-owned path list this reads from is .agents/kit-manifest.conf — see
# that file for the full path-by-path breakdown. In short:
#   - file=/dir= entries are copied (added/updated, never deleted — if
#     upstream removes a file, KIT-CHANGELOG.md calls it out and you remove
#     it from the project by hand).
#   - adr_dir= entries (currently unused) would match kit ADRs by filename.
#   - seed= entries are copied once, only if missing from the target (no
#     prompt, no output beyond the one line reporting the seed) — for
#     org-owned data files a project needs to run kit scripts but must be
#     free to edit, like .agents/model-map.conf. Never overwritten once
#     present, even if the kit's own copy changes upstream.
#   - .claude/, .github/agents/, .github/skills/, .codex/ are regenerated
#     inside the target project by re-running its own (freshly-copied)
#     mirror-agents.sh / mirror-skills.sh, not copied directly.
#   - This script, KIT_VERSION, and KIT-CHANGELOG.md are NOT copied into the
#     project — the kit isn't "installed" as files; it stays in this
#     checkout, and you come back here to run this script again whenever you
#     want to pull in kit changes.
#   - Everything else (AGENTS.md, memory/, specs/, src/, tests/, the
#     project's own ADRs, and anything not listed in kit-manifest.conf) is
#     never touched.
#
# Usage (run from inside this kit checkout):
#   scripts/update-kit.sh <path-to-project> [--dry-run] [--yes]
#
# <path-to-project> is the local folder of the project repo to copy the
# kit's files into — for first-time adoption or to pull in a newer kit
# version, e.g.:
#   git clone https://github.com/<kit-org>/spec-driven-development /tmp/sdd-kit
#   cd /tmp/sdd-kit
#   scripts/update-kit.sh ~/code/my-project
#
# To pick up a newer kit release later: git pull (or checkout a new tag) in
# this checkout, then re-run the same command — same direction, nothing to
# seed or bump in the project first.
#
# --dry-run   Print what would change; write nothing.
# --yes       Skip the confirmation prompt.
#
# Cross-platform twin: update-kit.ps1 — both read the kit-owned path list
# from .agents/kit-manifest.conf in this checkout at run time, so there is
# nothing to hand-sync between the two scripts beyond that data file.

set -euo pipefail

die() { echo "✖ $*" >&2; exit 1; }
info() { echo "  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DEST=""
DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y)  ASSUME_YES=1 ;;
    -*)        die "unknown flag '$arg'" ;;
    *)         [ -z "$DEST" ] || die "unexpected extra argument '$arg'"; DEST="$arg" ;;
  esac
done
[ -n "$DEST" ] || die "usage: $0 <path-to-project> [--dry-run] [--yes]"
[ -d "$DEST" ] || die "'$DEST' is not a directory."
DEST="$(cd "$DEST" && pwd)"
[ "$KIT_ROOT" != "$DEST" ] || die "source and destination are the same directory ('$KIT_ROOT') — pass the path to the project you want to copy the kit INTO, not the kit checkout itself."

KIT_MANIFEST_CONF="$KIT_ROOT/.agents/kit-manifest.conf"
[ -f "$KIT_MANIFEST_CONF" ] || die "$KIT_MANIFEST_CONF not found — is this script running from inside a kit checkout?"

# Kit-owned path lists live in data (.agents/kit-manifest.conf), not code —
# see that file for the format.
KIT_OWNED_FILES=()
KIT_OWNED_DIRS=()
KIT_ADR_DIRS=()
KIT_SEED_FILES=()
while IFS='=' read -r ns path; do
  ns="$(printf '%s' "$ns" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$ns" ] && continue
  case "$ns" in \#*) continue ;; esac
  path="$(printf '%s' "$path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$path" ] && continue
  case "$ns" in
    file)    KIT_OWNED_FILES+=("$path") ;;
    dir)     KIT_OWNED_DIRS+=("$path") ;;
    adr_dir) KIT_ADR_DIRS+=("$path") ;;
    seed)    KIT_SEED_FILES+=("$path") ;;
    *) die "$KIT_MANIFEST_CONF: unknown namespace '$ns' (expected file/dir/adr_dir/seed)" ;;
  esac
done < "$KIT_MANIFEST_CONF"

echo "Copying kit-owned files"
echo "  Kit checkout: $KIT_ROOT"
echo "  Target project: $DEST"
[ "$DRY_RUN" -eq 1 ] && echo "(dry run — no files will be written)"
echo ""

if [ "$ASSUME_YES" -ne 1 ] && [ "$DRY_RUN" -ne 1 ]; then
  read -r -p "This overwrites kit-owned paths in '$DEST'. Continue? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

echo "── Kit-owned files"
if [ "${#KIT_OWNED_FILES[@]}" -gt 0 ]; then
  for f in "${KIT_OWNED_FILES[@]}"; do
    [ -f "$KIT_ROOT/$f" ] || continue
    run mkdir -p "$DEST/$(dirname "$f")"
    if [ -f "$DEST/$f" ] && cmp -s "$KIT_ROOT/$f" "$DEST/$f"; then
      continue
    fi
    info "$f"
    run cp "$KIT_ROOT/$f" "$DEST/$f"
  done
fi

echo "── Kit-owned directories (add/update only, nothing deleted)"
if [ "${#KIT_OWNED_DIRS[@]}" -gt 0 ]; then
  for d in "${KIT_OWNED_DIRS[@]}"; do
    [ -d "$KIT_ROOT/$d" ] || continue
    info "$d/"
    run mkdir -p "$DEST/$d"
    run cp -R "$KIT_ROOT/$d/." "$DEST/$d/"
  done
fi

if [ "${#KIT_ADR_DIRS[@]}" -gt 0 ]; then
  for adr_dir in "${KIT_ADR_DIRS[@]}"; do
    [ -d "$KIT_ROOT/$adr_dir" ] || continue
    echo "── Kit's own ADRs ($adr_dir/, matched by filename)"
    run mkdir -p "$DEST/$adr_dir"
    for f in "$KIT_ROOT/$adr_dir"/*.md; do
      [ -e "$f" ] || continue
      base="$(basename "$f")"
      if [ -f "$DEST/$adr_dir/$base" ] && cmp -s "$f" "$DEST/$adr_dir/$base"; then
        continue
      fi
      info "$adr_dir/$base"
      run cp "$f" "$DEST/$adr_dir/$base"
    done
  done
fi

echo "── Seed files (copied only if missing in the target, never overwritten)"
if [ "${#KIT_SEED_FILES[@]}" -gt 0 ]; then
  for f in "${KIT_SEED_FILES[@]}"; do
    [ -f "$KIT_ROOT/$f" ] || continue
    [ -f "$DEST/$f" ] && continue
    info "$f (seeded)"
    run mkdir -p "$DEST/$(dirname "$f")"
    run cp "$KIT_ROOT/$f" "$DEST/$f"
  done
fi

echo ""
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. Re-run without --dry-run to apply."
  exit 0
fi

echo "── Regenerating .claude/.github/.codex mirrors in the target project"
( cd "$DEST" && bash scripts/mirror-agents.sh && bash scripts/mirror-skills.sh )

echo ""
echo "Kit files copied into: $DEST"
echo "Next steps:"
echo "  1. Review the diff: git -C '$DEST' status; git -C '$DEST' diff"
echo "  2. Read this kit checkout's KIT-CHANGELOG.md for anything that needs"
echo "     manual follow-up (e.g. a new required AGENTS.md section, a"
echo "     template field you should backfill)."
echo "  3. Run the project's test suite, then commit."
