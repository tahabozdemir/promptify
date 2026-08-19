# Grounding a prompt in the current repo

The difference between a generic "good prompt" and a great one for *this* codebase is specifics: real paths, the pattern to copy, the command that proves it. Spend the tool calls to find them — but bounded (3–8 calls for most prompts), and never invent what you could not confirm. Adapted from [Claude Code best practices](https://code.claude.com/docs/en/best-practices).

## What to look for, by task type

| Task type | Find and name in the prompt | Shape of the resulting prompt |
| --- | --- | --- |
| **Bug fix** | The symptom in the user's words; the likely module (grep for the error string, feature name, route); an existing test near it; the test command | Symptom → likely location → "write a failing test that reproduces it, then fix the root cause, don't suppress the error" → run `<test cmd>` and show output |
| **Feature / change** | The closest existing implementation to mirror ("`HotDogWidget.php` is a good example"); where it will plug in (router, registry, nav, DI); libraries already used; tests for the sibling feature | Why/for whom → the change → "follow the pattern in X" → in-scope files → out-of-scope → verification command → anti-over-engineering line |
| **Refactor** | The exact files/symbols in scope; callers (`grep -rn Symbol`); the tests that pin current behaviour; lint/typecheck command | Behaviour-preserving statement → scope list → "tests are the oracle; don't edit them" → "no unrelated cleanup" → run tests + typecheck |
| **Question / explanation** | The file or subsystem it concerns; git history if it's a "why" question (`git log -S`, `git log --follow`) | Investigate-before-answering → the specific question → "report findings, change nothing" → output shape (short answer first, file:line refs) |
| **Code review** | The diff source (`git diff main...`, PR number, path); the conventions a reviewer should check against (CLAUDE.md style, existing patterns) | What to review → bar for a finding (coverage vs. filtered) → what each finding must include (file:line, severity, confidence, why) → scope (no style nits unless asked) |
| **Research / investigation** | Where the answer plausibly lives (dirs, services, docs); what "answered" means | Success criteria → where to look → "use subagents for the wide sweep" → deliverable format (table, file:line list, recommendation) |
| **Docs / writing** | Audience; existing docs to match tone and structure; where the file lives | Audience + purpose → length target → structure to match → what not to duplicate |
| **Design / frontend** | Design system tokens, component library, existing screens to stay consistent with; screenshot tooling (`run` skill, Playwright, Chrome) | Concrete visual direction *or* "propose N directions first" → components to reuse → "screenshot the result and compare" |
| **Long autonomous run** | Test framework and how to run a subset; build/lint; where progress notes and state can live; what is destructive in this repo (migrations, deploy scripts, shared branches) | Full template: context, goal, constraints, verification cadence, progress grounding, checkpoint rule, autonomy reminder, memory location |
| **System prompt for an app** | The app's tools, data shapes, and failure modes; brand voice; output contract | Role → context → behaviours with reasons → tool guidance → output format → 3–5 `<example>`s |

## How to find it cheaply

- **Entry points and structure**: the snapshot gives you the top level and manifests. `Glob` for `**/README.md`, `src/**/index.*`, `**/*Router*`, `**/App*`, `**/main.*`.
- **The module for a feature or bug**: `Grep` the user's nouns (route names, UI strings, error messages, model names). A quoted error string from the raw prompt is gold — grep it verbatim.
- **The pattern to copy**: find a sibling — another widget, endpoint, screen, command, migration — and name it: "look at how `<sibling>` is implemented and follow that pattern."
- **The check that proves it**:
  - JS/TS: `package.json` scripts (`test`, `test:unit`, `lint`, `typecheck`, `build`); runner from config (`vitest.config.*`, `jest.config.*`, `playwright.config.*`). Prefer single-file runs: `npx vitest run path/to/file.test.ts`.
  - Python: `pytest path/to/test_x.py -q`, `ruff check`, `mypy`; `pyproject.toml` `[tool.*]` sections.
  - Rust: `cargo test <name>`, `cargo clippy`. Go: `go test ./pkg/...`. Ruby: `bundle exec rspec path`.
  - Swift/Xcode: `swift test` for SPM; `xcodebuild -scheme X test` or the project's XcodeBuildMCP/`run` skill for apps; name the scheme/simulator if the repo pins one.
  - Make/just/Task: list targets and pick the one that already exists.
  - No tests? Name the next-best signal: a build, a lint, a script that exercises the path, a screenshot, a curl against the dev server.
- **Conventions already in force**: CLAUDE.md / AGENTS.md / CONTRIBUTING.md are usually in context — reference, don't repeat. `.claude/agents`, `.claude/skills`, hooks in `.claude/settings.json` may define a required workflow (e.g. a scout → plan → review pipeline, a release procedure); route the prompt through it.
- **History for "why" questions**: `git log -S "symbol" --oneline`, `git log --follow -- path`, `git blame -L a,b path`.
- **What is dangerous here**: migrations, deploy/release scripts, shared branches, generated files, lockfiles, secrets files. Mention them as out of scope or confirm-first.

## Before/after patterns (from the Claude Code guide)

| Strategy | Before | After |
| --- | --- | --- |
| Scope the task | "add tests for foo.py" | "write a test for foo.py covering the edge case where the user is logged out. avoid mocks." |
| Point to sources | "why does ExecutionFactory have such a weird api?" | "look through ExecutionFactory's git history and summarize how its api came to be" |
| Reference existing patterns | "add a calendar widget" | "look at how existing widgets are implemented on the home page to understand the patterns. HotDogWidget.php is a good example. follow the pattern to implement a new calendar widget that lets the user select a month and paginate forwards/backwards to pick a year. build from scratch without libraries other than the ones already used in the codebase." |
| Describe the symptom | "fix the login bug" | "users report that login fails after session timeout. check the auth flow in src/auth/, especially token refresh. write a failing test that reproduces the issue, then fix it" |
| Provide verification criteria | "implement a function that validates email addresses" | "write a validateEmail function. example test cases: user@example.com is true, invalid is false, user@.com is false. run the tests after implementing" |
| Verify UI visually | "make the dashboard look better" | "[paste screenshot] implement this design. take a screenshot of the result and compare it to the original. list differences and fix them" |
| Root cause, not symptom | "the build is failing" | "the build fails with this error: [paste error]. fix it and verify the build succeeds. address the root cause, don't suppress the error" |

## Rules

- **Never fabricate a path, symbol, or command.** Confirmed → name it. Unconfirmed → "find where X lives (likely under `src/auth/`)". A wrong path sends the model down a hole and costs more than a vague one.
- **Prefer one exemplary file over a list of ten.** Claude generalizes from a good example.
- **Use `@path` references** when the file is small and central; the model reads it before acting.
- **Scope investigations.** An unbounded "investigate" fills context; say where to look and when to stop, or hand the sweep to a subagent.
- **Suggest the right container**: plan mode for uncertain multi-file work; a subagent for wide reads or fresh-eyes review; a worktree for parallel tracks; an interview-then-spec for big features. Skip all of it when the diff fits in one sentence.
- **Keep the user's voice.** You are upgrading their prompt, not writing a different one; their domain words and constraints stay.
