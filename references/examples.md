# Before → after examples

Calibration for proportionality and grounding. Paths and commands below are illustrative; in a real run every path and command comes from the repo snapshot and your own grounding, or is phrased as something to discover. Notice that the tiny case stays tiny.

---

## 1. Tiny — stays tiny

**Before**
```text
fix the typo in the readme
```

**After** (Grounded in: `README.md` exists at repo root; the misspelling is "recieve" on line 14.)
```text
In README.md, fix "recieve" → "receive" (line 14). Don't change anything else in the file.
```

Nothing added but the location. No tags, no verification ceremony for a one-word edit.

---

## 2. Bug fix — symptom, location, failing test, root cause

**Before**
```text
login is broken after a while, fix it
```

**After** (Grounded in: `src/auth/session.ts` handles refresh; `src/auth/__tests__/session.test.ts` exists; `npm run test -- src/auth` runs them; CLAUDE.md asks for no mocks of the token service.)
```text
Users report that login fails after a session sits idle long enough for the access token to expire; a page reload then shows the login screen instead of silently refreshing. The refresh path lives in src/auth/session.ts (refreshIfExpired). 

Write a failing test in src/auth/__tests__/session.test.ts that reproduces the expired-token case, then fix the root cause — don't widen the expiry window or swallow the error. Keep the fix inside src/auth/ unless the cause is clearly elsewhere, and say so if it is. Per CLAUDE.md, don't mock the token service; use the existing fake clock helper in that test file.

Run `npm run test -- src/auth` and paste the result. Lead your summary with what the root cause was.
```

---

## 3. Feature — mirror an existing pattern, bound the scope, prove it

**Before**
```text
add a dark mode toggle to settings
```

**After** (Grounded in: SwiftUI app; `Settings/SettingsView.swift` has a `Section("Appearance")`; `Settings/HapticsToggleRow.swift` is the existing toggle pattern backed by `@AppStorage`; theme is applied in `App/RootView.swift` via `.preferredColorScheme`; `xcodebuild -scheme App test` runs unit tests; the `run` skill can screenshot the simulator.)
```text
Add a Dark Mode toggle to the Appearance section of Settings/SettingsView.swift so users can force dark appearance instead of following the system. Follow the pattern in Settings/HapticsToggleRow.swift (an @AppStorage-backed row) and wire the stored value into the existing .preferredColorScheme in App/RootView.swift — three states: system, light, dark.

Keep the change to those three files plus a unit test for the mapping from stored value to ColorScheme. Don't restyle the Settings screen or touch other sections.

Verify: build and run the unit tests with `xcodebuild -scheme App test`, then launch in the simulator, flip the toggle, and take a screenshot showing the dark appearance applied. Include the screenshot and the test output.
```

---

## 4. Question — assessment only, investigate first, no edits

**Before**
```text
why is the dashboard so slow
```

**After** (Grounded in: `src/pages/Dashboard.tsx`, data from `src/api/metrics.ts`; `git log` shows a recent change to `useMetrics`.)
```text
The dashboard (src/pages/Dashboard.tsx) became noticeably slow to first paint in the last couple of weeks — I want to understand why before deciding what to change.

Read the component, its data hook (src/api/metrics.ts, useMetrics) and the recent commits touching them; don't speculate about code you haven't opened. Report what is actually causing the slowness, with file:line references and the evidence you used (renders, request counts, payload sizes — whatever you can measure or read from the code). If there are several candidates, rank them and say how confident you are in each.

This is an assessment: don't change any files. Lead with the answer in one or two sentences, then the supporting detail.
```

---

## 5. Refactor — behaviour-preserving, tests as the oracle, scope fence

**Before**
```text
clean up utils.py it's a mess
```

**After** (Grounded in: `app/utils.py` is 900 lines; `tests/test_utils.py` covers ~60 % of it; callers found via grep in `app/services/` and `app/cli.py`; `pytest tests/test_utils.py -q` and `ruff check app` are the checks.)
```text
Refactor app/utils.py for readability without changing behaviour: it has grown to ~900 lines mixing date helpers, path helpers, and retry logic. Split it into app/utils/dates.py, app/utils/paths.py and app/utils/retry.py, keep app/utils/__init__.py re-exporting the current public names so the callers in app/services/ and app/cli.py don't need to change, and delete nothing that's still referenced.

tests/test_utils.py is the oracle — don't edit it except to update import paths. Don't add docstrings, type annotations, or error handling to code you're only moving, and don't refactor the callers.

Run `pytest tests/test_utils.py -q` and `ruff check app`; paste both results. In your summary, list any function whose behaviour you weren't able to pin with an existing test.
```

---

## 6. Code review — coverage now, filter later

**Before**
```text
review my changes
```

**After** (Grounded in: branch `feature/rate-limit` vs `main`; `src/middleware/rateLimiter.ts` is new; existing middleware pattern in `src/middleware/auth.ts`; CLAUDE.md requires every middleware to have an integration test.)
```text
Review the diff of this branch against main (`git diff main...HEAD`): it adds src/middleware/rateLimiter.ts and wires it into src/app.ts. Compare it against how src/middleware/auth.ts is structured and against the CLAUDE.md rule that every middleware has an integration test.

Report every issue you find, including ones you're uncertain about or consider low-severity — I'll filter afterwards. For each finding give file:line, what can go wrong (inputs → wrong behaviour), severity, and your confidence. Focus on correctness, race conditions, and consistency with the existing middleware; skip pure style and naming nits.

Don't change any files. Lead with the most severe finding.
```

---

## 7. Long autonomous run — full template, grounded progress, checkpoints

**Before**
```text
build the CSV importer feature end to end, i'll check in the morning
```

**After** (Grounded in: Rails app; `app/services/` holds service objects, `app/services/pdf_exporter.rb` is a good exemplar; `bin/rails test test/services` runs the suite; `db/migrate` is the one place changes are hard to reverse; `docs/notes/` exists for progress notes.)
```text
<context>
I'm building a CSV importer so ops can bulk-load customer records instead of entering them one by one; it's the last blocker for the Q3 ops rollout. Service objects live in app/services/ — app/services/pdf_exporter.rb is the pattern to follow (call, Result struct, errors array). I'll be away overnight; nobody can answer questions mid-task.
</context>

<task>
Deliver a working importer: a CustomerCsvImporter service that validates and upserts rows, a controller action + route under /admin/imports, a minimal admin page to upload a file and see the result, and tests for the service and the controller.
</task>

<scope>
In scope: app/services/customer_csv_importer.rb, app/controllers/admin/imports_controller.rb, routes, one view, tests under test/. Out of scope: changing the Customer model's validations, any new gem, any migration — if you believe a migration is genuinely required, stop and leave the reasoning in docs/notes/importer-progress.md instead of writing it.
</scope>

<approach>
Write the service tests first, then the service, then the controller. When you have enough information to act, act; if you're choosing between two approaches, pick one and note why rather than surveying both. Don't add features, abstractions, or error handling beyond what the importer needs.
</approach>

<verification>
Run `bin/rails test test/services test/controllers/admin` after each major step and again before finishing. Before reporting progress, audit each claim against a tool result from this session; if something isn't verified, say so. Keep docs/notes/importer-progress.md updated with what's done, what's next, and anything you couldn't verify.
</verification>

<output>
Your final message is my first look at the work: open with the outcome in one sentence, then the test output, then the one or two things you need from me, each explained as if new. Plain sentences, no working shorthand.
</output>
```

---

## 8. System prompt for an app — role, reasons, tool policy, examples

**Before**
```text
You are a support bot. ALWAYS be helpful. NEVER make things up. ALWAYS use the search tool first. Think step by step and show your reasoning.
```

**After** (Target: Opus 5 via the API; tools: `search_kb`, `create_ticket`.)
```text
You are the support assistant for Acme's billing product, answering customers in chat.

<behavior>
Ground answers in the knowledge base: call search_kb before answering product questions, because answers that aren't in the KB are often out of date and customers act on them. If the KB has nothing relevant, say so plainly and offer to open a ticket with create_ticket rather than guessing. Keep responses focused and brief; spend most of the response on the answer, and keep caveats to a sentence.
</behavior>

<tools>
search_kb: use for any product or policy question. create_ticket: use only after confirming the customer wants one, since it notifies a human.
</tools>

<examples>
<example>
User: Why was I charged twice this month?
Assistant: [calls search_kb("duplicate charge billing cycle")] Two charges usually mean an annual plan renewed in the same month a one-off add-on was bought. Looking at our billing article, … If that doesn't match what you see, I can open a ticket for the billing team.
</example>
<example>
User: Does the API support webhooks for refunds?
Assistant: [calls search_kb("refund webhook")] I don't find refund webhooks in our docs, so I can't confirm that — would you like me to open a ticket so the team can answer definitively?
</example>
</examples>

<tone_preference>Keep outputs reasonably concise.</tone_preference>
```

Removed: the caps-lock commands (over-trigger), "show your reasoning" (reasoning-echo instruction), the unconditional "always search first" (replaced with a reason and a boundary). Added: role, reasons, tool policy, two diverse examples, a concision reminder near the end for Opus 5.
