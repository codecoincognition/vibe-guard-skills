# vibe-guard-skills

> Personal quality guard for solo vibe coders. Catch everything before you push.

AI coding tools are fast. But AI-generated code breaks in production, has security holes, and accumulates code you don't fully understand. **vibe-guard-skills** is a set of Claude Code skills that run a 3-pass audit at the end of every coding session — before you `git push`.

---

## What it catches

| Pass | Skill | What it finds |
|------|-------|---------------|
| 🔴 Production | `/vibe-check` | N+1 queries, missing error handling, null edge cases, scale failures, resource leaks |
| 🔴 Security | `/vibe-secure` | Hardcoded secrets, SQL injection, missing auth checks, insecure defaults |
| 🔵 Comprehension | `/vibe-explain` | Code you don't fully own — opaque blocks, magic numbers, hidden assumptions |

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/vibe-guard-skills/main/install.sh | bash
```

Installs to `~/.claude/skills/` (global) or `.claude/skills/` (project-local) automatically.

---

## Usage

At the end of every vibe coding session, before pushing:

```
/vibe-guard
```

For a full repo scan (not just recent changes):

```
/vibe-guard --full
```

Run individual passes when you need a focused check:

```
/vibe-check    # production resilience only
/vibe-secure   # security only
/vibe-explain  # comprehension only
```

---

## Sample Report

```
╔══════════════════════════════════════╗
║        VIBE GUARD REPORT             ║
╚══════════════════════════════════════╝
Scope: git diff (last commit)

🔴 CRITICAL — Fix before pushing
────────────────────────────────
  [vibe-secure] config.js:42
  Hardcoded API key as string literal
  Risk: exposed in version history
  Fix: replace with process.env.API_KEY

  [vibe-check]  queries.js:87
  N+1 query — DB call inside loop over users
  Fix: batch with WHERE id IN (...) before the loop

🟡 WARNINGS — Fix soon
───────────────────────
  [vibe-check]  api.js:103
  fetch() with no error handling
  Fix: wrap in try/catch, check response.ok

🔵 COGNITIVE DEBT — Understand before moving on
────────────────────────────────────────────────
  [vibe-explain] auth.js:55–89  tokenRefreshMiddleware()
  What it does: Silently refreshes access tokens within 5 minutes
  of expiry using the refresh token cookie...

══════════════════════════════════════
SUMMARY: 2 critical · 1 warning · 1 debt item
══════════════════════════════════════
```

---

## Skills

| Skill | Description |
|-------|-------------|
| `/vibe-guard` | Master orchestrator — runs all three passes, produces one report |
| `/vibe-check` | Production resilience: edge cases, scale, error handling, resource leaks |
| `/vibe-secure` | Security: secrets, injection, auth gaps, insecure defaults |
| `/vibe-explain` | Comprehension: plain-English explanations of opaque AI-generated blocks |

---

## Philosophy

Vibe coding is fast. This is the five-minute check that keeps it safe.

Each skill uses a **two-pass approach**: a fixed checklist of known AI failure patterns, followed by an adaptive pass that looks at your specific code's domain and risks. You get the repeatability of a checklist and the intelligence of context-aware analysis.

**Nothing is fixed without your approval.** After the report, you decide what to fix.

---

## Coming soon

- v2: Team enforcement mode + CI/GitHub Actions integration
- v2: Cross-platform ports (Cursor, Copilot, Codex/Windsurf)
- v2: Language-specific checklists (Python, Go, Rust variants)

---

## License

MIT
