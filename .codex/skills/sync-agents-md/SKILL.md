---
name: sync-agents-md
description: Use when filling in AGENTS.md from a real project for the first time, or re-syncing it later as the project drifts — triggers on phrases like "fill in AGENTS.md", "bootstrap AGENTS.md", "generate AGENTS.md from the codebase", "update AGENTS.md", "resync AGENTS.md", "is AGENTS.md still accurate", or "audit AGENTS.md for drift". Reads the actual repo (build files, CI, directory layout) and fills or corrects AGENTS.md and docs/glossary.md from evidence, marking anything it cannot verify rather than guessing. Requires explicit approval before writing. Do not use to write the constitution (use create-constitution) or per-feature specs (use spec-driven-feature), and never write project facts into the thin pointer files (CLAUDE.md, copilot-instructions.md).
---

# Sync AGENTS.md

Fills in or re-syncs `AGENTS.md` (and `docs/glossary.md`) from the **actual
state of the repository**, not from training-data guesses. Two modes, chosen
automatically and confirmed with the user:

- **Bootstrap** — AGENTS.md is still mostly the template (bracketed
  placeholders present). Replace placeholders with facts read from the repo.
- **Resync** — AGENTS.md is already filled in. Diff it against current reality
  and propose corrections for what has drifted, preserving human-written prose.

Both modes end at an approval gate. Nothing is written to disk until the user
approves the draft.

## Why this skill exists

The kit ships AGENTS.md as a template and leaves "fill in every placeholder" as
a manual step — by design, it never fabricates project facts. And as the project
changes — commands, dependencies, directory layout, CI — AGENTS.md silently goes
stale, which is worse than empty because every agent session trusts it. This
skill closes both gaps from evidence.

## Behavioral guardrails (active for the entire session)

- **Evidence or nothing.** Every line written into AGENTS.md must trace to a
  file you actually read (a build file, lockfile, CI workflow, the directory
  tree, an existing doc). If you cannot ground a fact, do **not** write a
  plausible-sounding one — write `[NEEDS VERIFICATION: what to check and where]`.
  This is the same no-fabrication rule the constitution applies to cross-repo
  signatures.
- **Respect AGENTS.md's own ground rule.** Every line should be something an
  agent could NOT infer from training. Do not add generic advice ("write clean
  code," "follow best practices") — if a line would be true of any repo, leave
  it out. Prefer deleting a section to filling it with filler.
- **Never thicken the pointer files.** Project facts go in AGENTS.md only.
  Never write conventions into `CLAUDE.md` or `.github/copilot-instructions.md`
  — the pre-commit hook and CI block those from growing past a pointer
  (ADR-0001).
- **Stay in lane.** Universal principles → `create-constitution`, not here.
  Feature requirements → `spec.md`, not here. Path-scoped subtree rules →
  `.github/instructions/*.instructions.md`, not AGENTS.md.
- **Preserve human prose on resync.** Treat existing filled-in text as
  authoritative unless the repo contradicts it. Touch only the lines that have
  actually drifted; never rewrite a section wholesale to "tidy" it.
- **Conservative by default.** Do not modify any file until the user approves
  the draft.

## Before starting

1. Confirm `AGENTS.md` exists at the repo root. If it does not, tell the user
   to copy it from this kit first — this skill fills it in, it does not author
   the template from scratch.
2. Decide the mode: count unresolved `[bracketed placeholders]` in AGENTS.md.
   Many remaining → **Bootstrap**; few or none → **Resync**. State which mode
   you picked and why, and let the user override.
3. Read `memory/constitution.md` (or the path AGENTS.md references) so you do
   not duplicate constitution material into AGENTS.md.

## Evidence sources (read these before writing anything)

Gather facts from whatever applies; do not assume an ecosystem — detect it.

- **Commands & tech stack:** `package.json` scripts, `pom.xml` /
  `build.gradle`, `pyproject.toml` / `Makefile` / `tox.ini`, `go.mod`,
  `Cargo.toml`, `Gemfile`, etc. Take the *exact* build/test/lint/run commands
  with their flags — AGENTS.md's Commands section is referenced constantly and
  must be exactly right.
- **Versions & key libraries:** lockfiles and manifest version pins. Record
  specific versions, not categories ("React 18 + Vite + Tailwind," not "React
  project").
- **Project structure:** the real top-level directory tree (`git ls-files`,
  not a guess). Describe what actually lives in each path.
- **Git / PR workflow:** branch names and commit-message shape from `git log`,
  plus `CONTRIBUTING*`, PR templates, and CODEOWNERS if present.
- **CI / required checks:** `.github/workflows/*` (and this kit's
  `agent-harness.yml`) for what blocks a merge.
- **Boundaries & brownfield areas:** directories with no tests, generated
  code, vendored dirs — candidates for the ⚠️ Ask-first / 🚫 Never tiers and
  for characterization-test flags.
- **Glossary:** domain terms that recur in code/docs but an outsider would not
  know.

For every fact, note its source so the draft can cite it and a later reader
need not redo the investigation.

## Mode A — Bootstrap

1. Walk AGENTS.md section by section. For each placeholder, fill it from the
   evidence above, or mark `[NEEDS VERIFICATION: …]` if the repo does not
   answer it. Delete whole sections that genuinely do not apply rather than
   leaving them generic (the template itself instructs this).
2. Fill `docs/glossary.md` with any real domain terms found; leave it with the
   empty header row if none are clear.
3. Do **not** remove the template's own instructional HTML comments silently —
   leave the ones guiding still-unfilled sections, remove the ones whose
   section you completed (matching how the other skills strip guidance from
   finished output).
4. Produce a short **source map**: for each section, the file(s) the content
   came from, and a list of every `[NEEDS VERIFICATION]` you left for the user.

## Mode B — Resync

1. Re-derive the same facts from the current repo.
2. Build a **drift report** — a table of: section · current AGENTS.md claim ·
   what the repo actually shows now · proposed edit. Include placeholders that
   were never filled.
3. Flag, but do not auto-change, anything where the repo is ambiguous or where
   the existing prose may reflect a human decision the files do not capture
   (e.g. an intentional Ask-first boundary). Ask the user.
4. Prepare edits that change only the drifted lines.

## Approval gate (both modes)

**Stop. Present the full draft (Bootstrap) or the drift report (Resync) and
ask for explicit approval**, including resolution of any `[NEEDS VERIFICATION]`
markers. Call out every judgement call. Only after approval, write the file(s).

## Verify before finishing

Add a verification pass after writing:

- Re-scan committed AGENTS.md for leftover `[bracketed placeholders]` — none
  should remain except intentional `[NEEDS VERIFICATION]` markers the user
  accepted.
- Sanity-check that each command in the Commands section actually exists in the
  source it came from (the script name is really in `package.json`, the Make
  target really exists). Where cheap and safe, dry-run `--help` to confirm the
  tool is present. Do not run build/test suites as part of this skill.
- Confirm no project facts leaked into `CLAUDE.md` or
  `.github/copilot-instructions.md`.

## What this skill deliberately does not do

- It does not write or amend the constitution — that is `create-constitution`,
  and universal principles do not belong in AGENTS.md.
- It does not populate `spec.md` / `plan.md` / `tasks.md`.
- It does not invent the AGENTS.md template, and it does not fabricate facts to
  make a section look complete — an unverifiable line is marked, not guessed.

## Keeping it current

Resync is worth running on a cadence (e.g. a scheduled task, or wired into CI
as a warning when AGENTS.md's commands no longer match the build files). Offer
this to the user after a succe