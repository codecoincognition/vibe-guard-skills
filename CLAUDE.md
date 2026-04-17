# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of four Claude Code skills that audit AI-generated code before it gets pushed. No build system, no dependencies, no runtime — just markdown skill files and a bash install script.

```
skills/
  vibe-guard.md    # Orchestrator: runs all three passes, produces one merged report
  vibe-check.md    # Pass 1: production resilience (N+1, error handling, resource leaks, edge cases)
  vibe-secure.md   # Pass 2: security (secrets, injection, auth gaps, insecure defaults)
  vibe-explain.md  # Pass 3: comprehension / cognitive debt (opaque blocks, magic numbers)
install.sh         # Downloads skills from GitHub into ~/.claude/skills/ or .claude/skills/
CLAUDE.md.template # Drop into user projects as CLAUDE.md to auto-invoke skills
```

## Skill file format

Each skill is a markdown file with YAML frontmatter followed by the skill body:

```markdown
---
name: vibe-check
description: One-line description shown in skill picker
---

Skill body here — instructions Claude follows when the skill is invoked.
```

The `name` field determines the `/slash-command` users type. The `description` is what Claude Code shows when listing available skills.

## Architecture: two-pass pattern

Every leaf skill (vibe-check, vibe-secure, vibe-explain) uses the same two-pass structure:
1. **Fixed checklist pass** — exhaustive list of known AI failure patterns, checked every time
2. **Adaptive pass** — holistic analysis of domain-specific risks not covered by the checklist

`vibe-guard` is the orchestrator: it runs all three leaf skills sequentially, deduplicates overlapping findings, and produces a single merged report sorted by severity.

## Scope logic (consistent across all four skills)

- Default (no flag): `git diff HEAD` — uncommitted working tree changes only, both passes
- `--full`: all source files tracked by git, excluding `node_modules/`, `vendor/`, `dist/`, `build/`, `.git/`, and lock files, both passes
- `--quick`: `git diff HEAD` + skip adaptive Pass 2 across all four skills. Filtering differs by skill: `vibe-check` / `vibe-secure` / `vibe-guard` report 🔴 CRITICAL only; `vibe-guard` additionally skips Pass 3 entirely; `vibe-explain` reports only 3×-severity-weighted blocks (auth/session/crypto/payment/billing/ledger). If both `--quick` and `--full` are passed, `--quick` wins.
- Empty diff: skills announce "no uncommitted changes found" and stop — they never run on nothing

## Severity model

- 🔴 CRITICAL — directly exploitable, certain failure, or high blast radius → fix before push
- 🟡 WARNING — conditional failure or growing technical risk → fix soon
- 🔵 COGNITIVE DEBT (vibe-explain only) — opaque blocks scored as a ratio (opaque/total named functions)
- Debt scale: < 0.2 Low ✅ | 0.2–0.4 Moderate 🟡 | > 0.4 High 🔴

When evidence is incomplete, findings use `(Needs verification)` rather than asserting facts.

## Install script

`install.sh` detects whether `~/.claude` exists (global install) or `.claude/` exists in the current directory (project-local), then `curl`s each skill from GitHub. The `REPO_URL` variable at the top must be updated to the actual GitHub org/repo path before the script works end-to-end.

## Developing skills

To test a skill locally: copy the `.md` file into `~/.claude/skills/` and invoke it in a Claude Code session with `/vibe-check` (or whichever skill). Changes take effect immediately in the next invocation — no restart needed.

When editing skills:
- Keep the two-pass structure intact — the fixed checklist provides repeatability; the adaptive pass provides intelligence
- The `vibe-guard.md` orchestrator and the three leaf skills must stay in sync on severity rubric definitions and output format
- `vibe-guard` deduplicates findings across passes, so leaf skill output format must be consistent enough to merge
- Never-fix-automatically rule: `vibe-guard` explicitly instructs Claude never to apply fixes without user approval — preserve this in any changes
