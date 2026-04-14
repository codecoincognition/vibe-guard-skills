# vibe-guard-skills

> Catch production bugs, security holes, and AI blind spots before you push.

AI-generated code breaks in production, leaves security holes, and accumulates logic you don't fully own. **vibe-guard-skills** catches all three — before you push.

A set of Claude Code skills that run a 3-pass audit at the end of every session: production resilience, security vulnerabilities, and code comprehension.

---

## What it catches

| Pass | Skill | What it finds |
|------|-------|---------------|
| 🔴 Production | `/vibe-check` | N+1 queries, missing error handling, null edge cases, scale failures, resource leaks |
| 🔴 Security | `/vibe-secure` | Hardcoded secrets, SQL injection, missing auth checks, insecure defaults |
| 🔵 Comprehension | `/vibe-explain` | Code you don't fully own — opaque blocks, magic numbers, hidden assumptions |

---

## Requirements

- [Claude Code](https://code.claude.com) (any version)

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/vibe-guard-skills/main/install.sh | bash
```

> **Note for contributors:** Replace `YOUR_GITHUB_USERNAME` with `codecoincognition` (or the actual org) when the repo goes live.

Installs to `~/.claude/skills/` (global) or `.claude/skills/` (project-local) automatically.

---

## How it works

Vibe Guard is a Claude Code skill — a structured prompt that runs entirely inside your Claude Code session. No external API calls. No code leaves your machine. Claude reads your diff and applies three sequential audit passes using a fixed checklist of known AI failure patterns, followed by an adaptive pass specific to your code's domain.

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

> **Tip:** Run `/vibe-guard` before committing, not just before pushing — it scans uncommitted changes in your working tree (`git diff HEAD`). Use `/vibe-guard --full` for a full repo audit.

---

## Sample Report

```
╔══════════════════════════════════════╗
║        VIBE GUARD REPORT             ║
╚══════════════════════════════════════╝
Scope: git diff (uncommitted changes)

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
Debt score: 1/6 blocks (0.17 — Low ✅)
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

---

## GitHub Topics

If you star this repo, also check: `claude-code` `claude-skills` `vibe-coding` `ai-coding` `code-review` `security-audit` `developer-tools`
