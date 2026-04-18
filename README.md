<p align="center">
  <img src="./docs/assets/cover.png" alt="vibe-guard — sniffing out bugs with style" width="100%">
</p>

# vibe-guard-skills

> Catch production bugs, security holes, and AI blind spots before you push.

AI-generated code breaks in production, leaves security holes, and accumulates logic you don't fully own. **vibe-guard-skills** catches all three — before you push.

A set of Claude Code skills that run a 3-pass audit at the end of every session: production resilience, security vulnerabilities, and code comprehension.

---

## Contents

- [What it catches](#what-it-catches)
- [Requirements](#requirements)
- [Install](#install)
- [How it works](#how-it-works)
- [Usage](#usage)
- [Auto-invoke with a project `CLAUDE.md`](#auto-invoke-with-a-project-claudemd)
- [What each skill checks for](#what-each-skill-checks-for)
  - [`/vibe-check` — Production Resilience](#vibe-check--production-resilience)
  - [`/vibe-secure` — Security](#vibe-secure--security)
  - [`/vibe-explain` — Comprehension / Cognitive Debt](#vibe-explain--comprehension--cognitive-debt)
- [Sample Report](#sample-report)
- [Skills](#skills)
- [Philosophy](#philosophy)
- [Pre-push hook (optional)](#pre-push-hook-optional)
- [Coming soon](#coming-soon)
- [License](#license)

---

## What it catches

| Pass | Skill | What it finds |
|------|-------|---------------|
| 🔴 Production | `/vibe-check` | N+1 queries, missing error handling, null edge cases, scale failures, resource leaks, data integrity issues |
| 🔴 Security | `/vibe-secure` | Hardcoded secrets, injection surfaces, missing auth checks, insecure defaults, supply chain risks |
| 🔵 Comprehension | `/vibe-explain` | Code you don't fully own — opaque blocks, magic numbers, hidden assumptions, implicit contracts |

---

## Requirements

- [Claude Code](https://code.claude.com) (any version)

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/codecoincognition/vibe-guard-skills/main/install.sh | bash
```

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

For a fast mid-edit check (critical issues only, ~10s):

```
/vibe-guard --quick
```

Run individual passes when you need a focused check:

```
/vibe-check    # production resilience only
/vibe-secure   # security only
/vibe-explain  # comprehension only
```

Each of the three leaf skills also accepts `--quick` for a critical-only sub-second feedback loop during active editing.

> **Tip:** Run `/vibe-guard` before committing, not just before pushing — it scans uncommitted changes in your working tree (`git diff HEAD`). Use `--quick` for mid-edit checks, default for pre-push, `--full` for a full repo audit.

---

## Auto-invoke with a project `CLAUDE.md`

You don't have to remember to type the slash commands inside a Claude Code session. Drop [`CLAUDE.md.template`](./CLAUDE.md.template) at the root of your project as `CLAUDE.md` (or merge its rules into an existing one) and Claude will apply them when the trigger fires inside a session — `--quick` when you ask it to commit, full guard when you ask it to push, `/vibe-secure` when it edits auth or payments code. Note: these rules only run while a Claude session is active. For enforcement regardless of whether Claude is active, use the pre-push hook below.

---

## What each skill checks for

### `/vibe-check` — Production Resilience

**Error Handling Gaps**
- External API/DB/file calls with no error handling; swallowed async rejections
- No timeout or abort signal on network/DB calls — a try/catch still hangs workers indefinitely when a dependency is slow

**Scale Failures**
- N+1 query patterns (DB query inside a loop)
- Unbounded loops; missing pagination on large result sets; full table scans with no LIMIT
- In-memory operations on unbounded data sets
- Thundering herd / cache stampede: concurrent requests all miss cache and recompute the same expensive result
- Missing backpressure: producer generates work faster than consumer can process with no queue depth limit

**Edge Cases AI Commonly Skips**
- Empty array/collection inputs assumed to have elements
- Null/undefined parameters not guarded against
- Concurrent write conflicts with no locking or idempotency
- Timezone assumptions without explicit conversion
- Integer overflow on counters, IDs, financial values
- Off-by-one errors in loops and array indexing
- Schema drift or version skew: code assumes a fixed payload shape but receives an older or newer version

**Untested Branches**
- Conditionals with no test path; error handlers that only log; early returns skipping critical logic

**Resource Leaks**
- Unclosed DB connections; unclosed file handles; unremoved event listeners; uncleared timers
- Unbounded in-memory growth: global Maps, caches, or arrays with no eviction or size limit

**Data Integrity**
- Multi-step operations with no transaction boundary — crash leaves data permanently inconsistent
- Read-modify-write without atomic update or optimistic concurrency — concurrent requests clobber each other
- Missing idempotency key on operations that must not execute twice (payments, email sends, job dispatch)

**Observability**
- Error caught with context stripped — no request ID, tenant, operation name, or upstream error code
- No structured log or metric on critical failure paths — silent degradation invisible to on-call
- Health signal absent: no counter, gauge, or trace span for significant error conditions

**Rollout Safety**
- Required config key not validated at startup — deploys cleanly then crash-loops on first use
- Database migration with no backward-compatible intermediate state — old code breaks on rollback
- Feature flag default not explicitly set — undefined behavior when flag doesn't yet exist in the store

**Adaptive pass:** domain-specific production risks beyond the checklist

---

### `/vibe-secure` — Security

**Secrets & Credentials**
- Hardcoded API keys, tokens, passwords, secrets (including in comments and test files)
- Credentials in URL parameters; private keys in source files
- Server-side secrets bundled into client-facing code (`NEXT_PUBLIC_*`, Vite env vars, frontend bundles)

**Injection Surfaces**
- SQL injection: user input concatenated into SQL strings
- Command injection: user input reaching `exec()`, `eval()`, `subprocess`, shell calls
- Path traversal: user-controlled input in file path construction (`path.join()` does NOT prevent traversal)
- Template injection: Jinja2 `{{ var | safe }}`, EJS `<%- var %>`, Pug without escaping
- XSS: unescaped user input in HTML via `innerHTML`, `dangerouslySetInnerHTML`, `document.write`
- SSRF: user-supplied URLs in server-side HTTP requests without allowlist — can pivot to `169.254.169.254`
- NoSQL injection: user input passed as a query selector object (`db.findOne(JSON.parse(input))`)
- XML/XXE: user-controlled XML parsed without disabling external entity resolution

**Input Validation Gaps**
- User inputs reaching DB writes, file paths, or auth decisions without validation
- Missing input length limits; type confusion without runtime type checking
- Missing allowlist validation on structured-format fields: email addresses, URLs, enum values, content-type strings

**Auth & Authorization**
- Unprotected routes/endpoints; missing object-level authorization (IDOR)
- Broken access control; weak/missing JWT validation; low-entropy session tokens
- CORS misconfiguration: wildcard on authenticated endpoints; dynamic `Origin` reflection; credentials + permissive origin
- Timing attack on auth: `===` comparison instead of constant-time (`crypto.timingSafeEqual`, `hmac.compare_digest`)
- CSRF on cookie-based auth: no CSRF token, no `SameSite` enforcement, no `Origin`/`Referer` check
- Missing refresh token rotation or session invalidation after logout/password change/privilege change

**Insecure Defaults**
- HTTP instead of HTTPS; debug mode in prod; stack traces exposed to users
- No rate limiting on auth; missing cookie security flags (HttpOnly, Secure, SameSite)
- Missing security headers: `X-Frame-Options`, `Content-Security-Policy`, `X-Content-Type-Options`, `Strict-Transport-Security`
- File upload with MIME-type-only validation — `Content-Type` is user-controlled; validate magic bytes
- Missing `Cache-Control: no-store` on auth pages, account data, and sensitive API responses

**Mass Assignment**
- User-controlled request body spread into ORM without field allowlisting (`Model.create(req.body)`, `user.update(req.body)`)

**Insecure Deserialization**
- `pickle.loads()`, `yaml.load()` without `SafeLoader`, `eval()` on serialized input, spread of untrusted objects into class instances

**Prototype Pollution (JavaScript)**
- `_.merge(target, userInput)`, `Object.assign({}, req.body)`, recursive merge utilities with user-controlled `__proto__` or `constructor`

**Dependencies & Crypto**
- MD5/SHA1 for passwords; `Math.random()` for security tokens; deprecated crypto algorithms
- Password stored without a proper KDF — use Argon2, bcrypt, or scrypt with appropriate work factor
- Nonce or IV reused across encryption operations (destroys CBC/CTR/GCM confidentiality)
- TLS certificate verification disabled (`verify=False`, `rejectUnauthorized: false`)
- Dependency provenance: typosquatting-susceptible names, unreviewed packages, postinstall scripts executing arbitrary code

**Security Logging & Monitoring (OWASP A09)**
- No audit log on login, privilege change, data export, payment initiation
- Webhook payload processed without signature verification (HMAC `X-Hub-Signature` or equivalent)
- Failed authentication attempts not logged or counted

**Business Logic & Race Conditions**
- Double-spend / duplicate-action race: two concurrent requests both pass a check before either commits the deduction
- Privilege escalation via parameter tampering (`role`, `plan`, `price`) bypassing mass-assignment checks

**Adaptive pass:** domain-specific security risks (multi-tenancy, PHI, financial logic, file upload, etc.)

---

### `/vibe-explain` — Comprehension / Cognitive Debt

**Black Boxes**
- Non-obvious functions with no intent comment; opaque transformation chains; hidden side effects

**Complexity Barriers**
- Branch depth > 3; more than 3 chained transforms; uncommented regex/bitwise ops; hidden state dependencies; non-obvious recursive termination

**Hidden Assumptions**
- Magic numbers/strings; undocumented preconditions; hidden ordering dependencies; required setup state not indicated

**Fragility Signals**
- Code hard to modify without breaking something unexpected — flags exact dependency surface and concrete change that would trigger silent breakage

**Naming Opacity**
- Single-letter names outside loop counters; generic names (`data`, `result`, `temp`) on non-trivial values; implementation-shaped function names; non-question-form booleans

**Architectural & Design Intent**
- Code with no indication of why this approach was chosen, what tradeoff it embodies, or what alternative was rejected
- Business rules buried with no link to the requirement or decision they represent

**Implicit Module Contracts**
- Functions depending on caller providing data in a specific shape/ordering/state that is not asserted or documented
- Producer/consumer coupling where the consumer assumes data is pre-sorted or pre-enriched based on coincidental upstream behavior

**Temporal Coupling & Async Ordering**
- Async operations relying on incidental execution order — happy-path flows that break on cold start or concurrent initialization
- Initialization races: code accessing a resource before setup is guaranteed to complete
- Teardown ordering assumptions that don't hold under failure or shutdown

**Dead Code & AI Over-Generation**
- Exported functions, helpers, or constants with no active call path
- Duplicate fallback paths or parallel implementations that silently diverge
- Speculative abstractions built for anticipated future use with no current second consumer

**For each opaque block, the report produces:**
- **What it does** — plain-English walkthrough in 3–5 sentences
- **Assumes** — key preconditions that must be true
- **Careful** — what breaks if you change this without understanding it
- **Own it** — one concrete action to convert understanding into maintainability (rename, extract, add assertion, add test)

**Debt score:** raw ratio + severity-adjusted score (critical auth/payment blocks weight 3×, utilities 1×)

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
  Own it: Rename window to TOKEN_REFRESH_THRESHOLD_MS, add assertion
  that refresh cookie exists, add test for expiry path.

══════════════════════════════════════
SUMMARY: 2 critical · 1 warning · 1 debt item
Debt score: 1/6 blocks raw (0.17) · severity-adjusted: Low ✅
══════════════════════════════════════
```

---

## Skills

| Skill | Description |
|-------|-------------|
| `/vibe-guard` | Master orchestrator — runs all three passes, produces one report |
| `/vibe-check` | Production resilience: edge cases, scale, error handling, resource leaks, data integrity, observability, rollout safety |
| `/vibe-secure` | Security: secrets, injection, auth gaps, insecure defaults, supply chain, business logic races |
| `/vibe-explain` | Comprehension: plain-English explanations, module contracts, architectural intent, severity-weighted debt score |

---

## Philosophy

Vibe coding is fast. This is the five-minute check that keeps it safe.

Each skill uses a **two-pass approach**: a fixed checklist of known AI failure patterns, followed by an adaptive pass that looks at your specific code's domain and risks. You get the repeatability of a checklist and the intelligence of context-aware analysis.

**Nothing is fixed without your approval.** After the report, you decide what to fix.

---

## Pre-push hook (optional)

Block pushes automatically when vibe-guard finds CRITICAL issues.

**One-time setup — run from your project root:**

```bash
# 1. Copy the hooks directory into your project
cp -r /path/to/vibe-guard-skills/.githooks .githooks

# 2. Run the setup script
bash .githooks/../setup-hooks.sh
```

Or if you cloned this repo directly, just run from the repo root:

```bash
bash setup-hooks.sh
```

**What it does:**

- Runs `/vibe-guard` on your uncommitted changes before every `git push`
- Blocks the push if any 🔴 CRITICAL issues are found
- Silently skips if the `claude` CLI is not installed (won't break teammates who don't use Claude Code)

**Override for a single push:**

```bash
git push --no-verify
```

**Remove the hook entirely:**

```bash
git config --unset core.hooksPath
```

> **How it works:** `setup-hooks.sh` sets `core.hooksPath = .githooks` in your local git config. Git executes `.githooks/pre-push` before every push. If the script exits non-zero (CRITICAL findings found), git aborts the push before anything reaches the remote.

---

## Coming soon

- Support for **Codex**, **Cursor**, and **Aider** — same three-pass audit, ported to each tool's native rules/conventions format.
- Team enforcement mode + CI/GitHub Actions integration.
- Language-specific checklists (Python, Go, Rust variants).

---

## License

MIT

---

Crafted by [Vikas Sah](https://github.com/codecoincognition).
