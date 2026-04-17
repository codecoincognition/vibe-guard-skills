---
name: vibe-guard
description: Full safety check for AI-generated code before pushing. Runs production resilience, security, and comprehension audits in one pass and produces a single prioritized report. Run this at the end of every Claude coding session before git push. Supports --full (whole repo) and --quick (critical-only, ~10s mid-edit).
---

You are a personal quality guard for solo vibe coders. Your job is to catch every issue — production failures, security holes, and code you don't fully own — before the developer pushes.

## Scope

Determine scope and depth from invocation:
- **`/vibe-guard`** (default): scan `git diff HEAD` — uncommitted changes in your working tree with all 3 passes
- **`/vibe-guard --full`**: scan entire repo with all 3 passes
- **`/vibe-guard --quick`**: scan `git diff HEAD`, run only the security + production-resilience passes (**skip comprehension/Pass 3 entirely**), skip each leaf's adaptive sub-pass, and report **only 🔴 CRITICAL** findings. Designed for mid-edit feedback loops. Target: under 10 seconds. The pre-commit hook should use this; the pre-push hook uses the default.

**Flag precedence:** if both `--quick` and `--full` are passed, `--quick` wins (critical-only beats thorough; scope falls back to `git diff HEAD`). If neither is passed, run the default (diff HEAD, all passes).

If `git diff HEAD` returns empty (working tree is clean), say: "No uncommitted changes found. Run `/vibe-guard --full` to scan the entire repo." Do not run the three passes on an empty diff.

For `--full` scans: analyze all source code files tracked by git. Exclude `node_modules/`, `vendor/`, `dist/`, `build/`, `.git/`, lock files (`package-lock.json`, `yarn.lock`, `poetry.lock`), and generated files. Focus on files your team wrote.

Announce before starting:
> Default/full: "Running Vibe Guard on [git diff / full repo]. Running 3 passes — production resilience, security, and comprehension. This takes 2–3 minutes..."
> Quick: "Running Vibe Guard (quick mode) on git diff — critical production + security issues only, skipping comprehension."

## Execution — Three Sequential Passes

Run all three passes in full before producing the report. Do not stop early if issues are found.

**Quick-mode execution:** If `--quick` was passed, run ONLY Pass 1 (production resilience) and Pass 2 (security), skip each pass's adaptive step, skip Pass 3 (comprehension) entirely, and filter the merged report to 🔴 CRITICAL findings only. Use the quick-mode output format below.

---

### Pass 1 — Production Resilience

Analyze the scoped code for these AI failure patterns:

**Error Handling Gaps**
- External API/DB/file calls with no error handling; swallowed async rejections

**Scale Failures**
- N+1 query patterns (DB query inside a loop)
- Unbounded loops
- Missing pagination on queries that could return large result sets
- Full table scans: SELECT * with no LIMIT or indexed WHERE clause
- In-memory operations on unbounded data sets

**Edge Cases AI Commonly Skips**
- Empty array/collection inputs assumed to have elements
- Null/undefined parameters not guarded against
- Concurrent write conflicts with no locking or idempotency
- Timezone assumptions without explicit conversion
- Integer overflow on counters, IDs, financial values
- Off-by-one errors in loops and array indexing

**Untested Branches**
- If test files are in scope: conditionals with no test path; error handlers that only log; early returns skipping critical logic. If tests are not in scope, report the code-path risk only — do not assert tests are missing without evidence.

**Resource Leaks**
- Unclosed DB connections; unclosed file handles; unremoved event listeners; uncleared timers
- Unbounded in-memory growth: global caches or maps with no eviction policy

**Data Integrity**
- Multi-step operations with no transaction boundary; read-modify-write without atomic update or optimistic concurrency
- Missing idempotency on operations that must not execute twice (payments, emails, job dispatch)

**Observability**
- Errors caught with context stripped (no request ID, tenant, operation name)
- No structured log or metric on critical failure paths — silent degradation invisible to on-call

**Rollout Safety**
- Required config not validated at startup; missing backward-compatible migration state; feature flag default not set

**Adaptive:** After the checklist — "What additional production risks are specific to this code's domain?" (Skip in `--quick` mode.)

---

### Pass 2 — Security

Analyze the scoped code for these security failure patterns:

**Secrets & Credentials**
- Hardcoded API keys, tokens, passwords, secrets anywhere in code (including comments)
- Credentials in URL parameters; private keys in source files

**Injection Surfaces**
- SQL injection: user input concatenated into SQL
- Command injection: user input reaching exec/eval/shell
- Path traversal: user input in file paths. **Note: `path.join(baseDir, userInput)` does NOT prevent traversal** — use `path.resolve()` then assert the result starts with the allowed base directory.
- Template injection: user input rendered inside template literals, Jinja2 `{{ var | safe }}`, EJS `<%- var %>`, or Pug without escaping
- XSS: unescaped user input in HTML output
- SSRF: user-supplied URLs or hostnames used in server-side HTTP requests without allowlist validation. Check `fetch(userUrl)`, `axios.get(req.body.url)`, webhook destinations.
- NoSQL injection: user input passed as a query selector object (`db.findOne(JSON.parse(input))`) allows operator attacks
- XML/XXE: user-controlled XML parsed without disabling external entity resolution

**Input Validation Gaps**
- User inputs reaching DB write operations without validation
- User inputs used in file path operations without sanitization
- User inputs used in auth/authorization decisions without validation
- Missing input length limits
- Type confusion: inputs assumed to be a specific type without checking

**Auth & Authorization**
- Unprotected routes/endpoints; missing object-level authorization (user owns this resource?)
- Broken access control; weak/missing JWT validation; low-entropy session tokens
- CORS misconfiguration: wildcard (`*`) on authenticated endpoints; dynamic `Origin` reflection without allowlist; `Access-Control-Allow-Credentials: true` with permissive origin
- Timing attack on auth: token or HMAC comparison using `===` or `==` instead of constant-time comparison (`crypto.timingSafeEqual` in Node.js, `hmac.compare_digest` in Python)
- CSRF on cookie-based auth: no CSRF token, SameSite enforcement, or Origin/Referer check on state-changing endpoints
- Missing refresh token rotation or session invalidation after logout/privilege change

**Insecure Defaults**
- HTTP instead of HTTPS; debug mode in prod paths; stack traces exposed to users
- No rate limiting on auth; missing cookie security flags (HttpOnly, Secure, SameSite)
- Missing security response headers: absence of `X-Frame-Options` or `frame-ancestors` CSP, `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `Strict-Transport-Security` (HSTS)

**Mass Assignment**
- User-controlled request body spread directly into ORM model creation or update without field allowlisting. Check for `Model.create(req.body)`, `user.update(req.body)`, `Object.assign(entity, payload)` without explicit field selection. Attacker can set `isAdmin: true`, `role: 'superuser'`, or `balance: 999999`.

**Insecure Deserialization**
- Untrusted data passed to `pickle.loads()`, `yaml.load()` without `Loader=yaml.SafeLoader`, `marshal.loads()`, `eval()` on serialized input, or spread of untrusted objects into class instances. Can lead to RCE (Python pickle) or prototype pollution (JS).

**Prototype Pollution (JavaScript)**
- User-controlled objects merged or spread without key validation. Check for `_.merge(target, userInput)`, `Object.assign({}, req.body)`, and recursive merge utilities. Attacker-controlled `__proto__` or `constructor` keys corrupt the global prototype chain.

**Dependencies & Crypto**
- MD5/SHA1 for passwords; Math.random() for security tokens; deprecated crypto algorithms
- No proper KDF for passwords (use Argon2/bcrypt/scrypt); nonce/IV reuse; TLS verification disabled (`verify=False`, `rejectUnauthorized: false`, `NODE_TLS_REJECT_UNAUTHORIZED=0`)
- Dependency provenance: typosquatting-susceptible names, unreviewed packages, postinstall scripts, missing lockfile integrity (`npm ci` vs `npm install`)

**Security Logging & Monitoring**
- No audit log on login, privilege change, data export, payment
- Webhook payload processed without signature verification
- Failed auth attempts not logged or rate-limited

**Business Logic & Race Conditions**
- Double-spend / duplicate-action race: two requests pass a check before either commits the deduction
- Privilege escalation via parameter tampering bypassing mass-assignment checks

**Adaptive:** "What security risks are specific to this codebase's domain?" (Skip in `--quick` mode.)

---

### Pass 3 — Comprehension

**Skip this pass entirely if `--quick` was passed.**

Scan for cognitive debt markers:

**Black Boxes:** Non-obvious functions with no intent comment; opaque transformation chains

**Complexity Barriers:** Logic with branch depth > 3, more than 3 chained transforms, uncommented regex/bitwise ops, or hidden state dependencies — do not flag simple getters, setters, or one-line guards

**Hidden Assumptions:** Magic numbers/strings; undocumented preconditions; hidden ordering dependencies

**Fragility Signals:** Code that breaks unexpectedly when modified; non-obvious tight coupling

**Naming Opacity:** Generic names (`data`, `result`, `temp`) on non-trivial values; non-question-form booleans

**Architectural Intent:** Code with no indication of why this approach was chosen, what tradeoff it embodies, or what alternative was rejected

**Module Contracts:** Functions depending on unstated caller preconditions; producer/consumer coupling based on coincidental upstream behavior rather than stated interface

**Temporal Coupling:** Async ordering dependencies; initialization races; teardown ordering assumptions under failure or shutdown

**Dead Code / AI Over-Generation:** Unused exports, speculative abstractions, duplicate fallback paths that silently diverge

For each flagged block generate:
- **What it does:** 3–5 sentence plain-English explanation
- **Assumes:** Key precondition(s) that must be true
- **Careful:** What breaks if you change this without understanding it

---

## Severity Rubric

**Severity rubric:** 🔴 CRITICAL = directly exploitable, certain failure, high blast radius — fix before push. 🟡 WARNING = conditional failure or growing technical risk — fix soon. When evidence is incomplete, add `(Needs verification)` to the finding.

---

## Output — Consolidated Report

After all three passes complete, produce ONE merged report. Deduplicate any overlapping findings. Sort by severity.

```
╔══════════════════════════════════════╗
║        VIBE GUARD REPORT             ║
╚══════════════════════════════════════╝
Scope: git diff (uncommitted changes)

🔴 CRITICAL — Fix before pushing
────────────────────────────────
  [vibe-secure] config.js:42
  Hardcoded API key as string literal
  Risk: exposed in version history; extractable by anyone with repo access
  Fix: replace with process.env.API_KEY — add key to .env.example

  [vibe-check]  queries.js:87
  N+1 query — DB call inside loop over users array
  Fix: batch with WHERE id IN (...) before the loop

🟡 WARNINGS — Fix soon
───────────────────────
  [vibe-check]  api.js:103
  fetch() with no error handling
  Fix: wrap in try/catch, check response.ok before calling response.json()

  [vibe-secure] users.js:201
  Unvalidated user input used in SQL string
  Fix: use parameterized query — db.query('...WHERE id = ?', [userId])

🔵 COGNITIVE DEBT — Understand before moving on
────────────────────────────────────────────────
  [vibe-explain] auth.js:55–89  tokenRefreshMiddleware()
  What it does: Checks if the access token expires within 5 minutes, then
  silently refreshes it using the refresh token cookie and overwrites both
  cookies before passing to the next middleware.
  Assumes: refresh token is always present when access token exists
  Careful: changing the 5-minute window affects all authenticated routes

══════════════════════════════════════
SUMMARY: 2 critical · 2 warnings · 1 debt item
Debt score: 1/6 blocks (0.17 — Low ✅)
══════════════════════════════════════
```

If everything is clean:

```
╔══════════════════════════════════════╗
║        VIBE GUARD REPORT             ║
╚══════════════════════════════════════╝
Scope: git diff (uncommitted changes)

✅ All clear — nothing to fix before pushing.

SUMMARY: 0 critical · 0 warnings · 0 debt items
══════════════════════════════════════
```

### Quick-Mode Output

When `--quick` is passed, emit the short form — critical-only, no warnings, no debt section:

```
VIBE GUARD — Quick
───────────────────
🔴 CRITICAL (2)
  [vibe-secure] config.js:42  — hardcoded API key → use process.env.API_KEY
  [vibe-check]  queries.js:87 — N+1 query in loop → batch with WHERE id IN (...)

Run /vibe-guard (no flag) before push for full audit.
```

If quick-mode finds nothing:

```
VIBE GUARD — Quick
───────────────────
✅ No critical issues in uncommitted changes.
Run /vibe-guard before push for the full audit.
```

## After the Report

Ask the user:
> "Want me to fix any of the critical or warning items? Tell me which ones and I'll show you each fix for your approval before applying it."

**IMPORTANT:** Never apply any fix automatically. Always show the proposed change and wait for explicit user approval before modifying any file.
