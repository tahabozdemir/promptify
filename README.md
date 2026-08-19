# promptify — a Claude Code skill

Turn a rough prompt into the prompt an expert on *your* codebase would have written, for the Claude model you're actually running.

```
/promptify login is broken after a while, fix it
```

gives you back something like:

```text
Users report that login fails after a session sits idle long enough for the access token to
expire. The refresh path lives in src/auth/session.ts (refreshIfExpired).

Write a failing test in src/auth/__tests__/session.test.ts that reproduces the expired-token
case, then fix the root cause — don't widen the expiry window or swallow the error. Keep the
fix inside src/auth/ unless the cause is clearly elsewhere. Per CLAUDE.md, don't mock the
token service; use the existing fake clock helper in that test file.

Run `npm run test -- src/auth` and paste the result. Lead your summary with the root cause.
```

…plus a short list of the repo facts it used, any assumptions, and an offer to run it.

## What it does

Vague prompts produce mediocre, hard-to-verify work, and Anthropic's prompting guidance is long and differs per model. promptify closes that gap in one step:

1. **Reads your raw prompt** — whatever you'd have typed anyway.
2. **Snapshots the repo** automatically (git branch and state, top-level layout, manifests, npm scripts, test directories, whether CLAUDE.md / AGENTS.md / project agents / skills exist).
3. **Grounds the prompt in real code** — a handful of targeted reads and greps to find the files actually involved, an existing pattern worth copying, and the test/build/lint command that proves the change. It never invents a path; anything unconfirmed is phrased as something to discover.
4. **Rewrites** according to Anthropic's current guidance for the model in use (Fable 5 / Mythos 5, Opus 5, Sonnet 5, Opus 4.x, Haiku 4.5): direct action verbs, the reason behind the request, explicit scope and out-of-scope, a verifiable check, positive framing, proportional length — and it strips the things that hurt on current models (ALL-CAPS "MUST", "be thorough", "double-check", "show your reasoning", step-by-step thinking scripts).
5. **Presents** the result: the prompt in a code block, **Grounded in** (2–5 bullets), **Assumptions** (≤3, only ones that would change the work), and "Say **run it** to execute". It doesn't change any files or run the task unless you pass `--run`.

Proportionality is a rule, not a suggestion: a one-line typo fix stays two sentences; an overnight autonomous build gets the full `<context>/<task>/<scope>/<verification>/<output>` template.

## Install

**Requirements:** a recent Claude Code (skills with `allowed-tools` and `${CLAUDE_SKILL_DIR}` substitution), `bash` available (macOS/Linux; on Windows use Git Bash — the repo snapshot is a bash script).

### Quickest — with the `skills` CLI

```bash
npx skills add tahabozdemir/promptify -g        # personal: every repo (~/.claude/skills/promptify)
npx skills add tahabozdemir/promptify           # project: this repo only (.claude/skills/promptify)
```

Add `-a claude-code` to target Claude Code only, `-y` to skip the confirmation. The CLI symlinks by default; pass `--copy` for an independent copy (use that for project installs you want to commit).

### As a Claude Code plugin

```
/plugin marketplace add tahabozdemir/promptify
/plugin install promptify@promptify
```

Plugins update in place when a new version is published (`/plugin marketplace update`).

### Cursor and other agents

Cursor: *Settings → Rules → Add Rule → Remote Rule (GitHub)* and paste `https://github.com/tahabozdemir/promptify`. Any agent that follows the [Agent Skills](https://agentskills.io) spec can load the root `SKILL.md`; the `skills` CLI above installs for every agent it detects unless you pass `-a`.

### Option A — personal skill, by hand

```bash
git clone https://github.com/tahabozdemir/promptify.git ~/promptify
ln -s ~/promptify ~/.claude/skills/promptify
```

Or clone straight into place instead of symlinking:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/tahabozdemir/promptify.git ~/.claude/skills/promptify
```

### Option B — project skill, by hand

```bash
mkdir -p .claude/skills
git clone --depth 1 https://github.com/tahabozdemir/promptify.git /tmp/promptify \
  && rm -rf /tmp/promptify/.git \
  && mv /tmp/promptify .claude/skills/promptify
```

Copying (rather than cloning in place) keeps it a plain folder you can commit with your project so teammates get it; use `git submodule add https://github.com/tahabozdemir/promptify.git .claude/skills/promptify` instead if you'd rather track upstream.

### Verify

Open Claude Code in any project and type `/promptify` — it should autocomplete, with the hint `[--run] [--model <name>] <raw prompt>`. Or ask Claude *"what skills are available?"*. Claude Code picks up new skills live; if `~/.claude/skills/` didn't exist before you installed, restart Claude Code once so it starts watching the directory.

### Notes

- **The command name is the directory (or symlink) name** under `~/.claude/skills/`, not the `name:` in the frontmatter. To rename the command, rename the symlink and update `name:` in `SKILL.md` so the listing matches.
- **Permissions:** `SKILL.md` pre-approves only `scripts/snapshot.sh` and read-only `git` via `allowed-tools`; everything else the skill does is reads, greps, and globs. Nothing is written unless you say `run it` or pass `--run`, and then the executed prompt is subject to your normal permission mode.
- **Uninstall:** delete the symlink or folder from `~/.claude/skills/` (or `.claude/skills/`).

## Usage

```
/promptify <raw prompt>                     rewrite and show; nothing is executed
/promptify --run <raw prompt>               rewrite, show, then execute in the same turn
/promptify --model sonnet-5 <raw prompt>    tune for another model (subagent, API app)
/promptify                                  use your previous message as the raw prompt
```

Claude can also invoke it on its own when you say things like *"make this a better prompt"*, *"how should I ask for this"*, or *"promptify this"*.

**What you get back, always in this order:**

1. The upgraded prompt in a single fenced block — copy-paste ready.
2. **Grounded in** — the repo facts it used (paths, commands, conventions), so you can sanity-check them.
3. **Assumptions** — at most three, only if they'd change the work (omitted when there are none).
4. "Say **run it** to execute this prompt as written." — reply `run it` and Claude runs it.

**What it won't do:** change your intent (it adds context, structure, and verification; it doesn't narrow or widen the ask), invent file paths, restate what's already in CLAUDE.md, or pad the prompt with generic advice.

## Layout

```
SKILL.md                      workflow + always-on rules (this is what loads into context)
scripts/snapshot.sh           read-only repo snapshot, injected before the skill runs
scripts/validate.sh           pre-PR checks (frontmatter, references, snapshot in 3 envs, plugin manifests)
references/principles.md      general techniques + Anthropic's tested snippets + a "what to strip and why" table
references/model-notes.md     per-model add/remove lists: Fable 5 / Mythos 5, Opus 5, Sonnet 5, Opus 4.8–4.6, Haiku 4.5, Claude Code harness
references/repo-grounding.md  what to dig out of the repo per task type, and how to find it cheaply
references/examples.md        eight before→after pairs (tiny fix … overnight run … system prompt)
templates/prompt-template.md  three prompt shapes by size
.claude-plugin/               plugin.json + marketplace.json, so it installs as a Claude Code plugin too
CONTRIBUTING.md               layout rules, what to contribute, how to validate
```

Only `SKILL.md` is loaded when the skill runs; the references are read on demand, so they cost nothing until needed.

## Customize

- **Your house style** — add a bullet to *Rules that always apply* in `SKILL.md` (e.g. "always ask for a Conventional Commits message"), or add a before→after pair to `references/examples.md`; examples steer the output more reliably than rules.
- **A new model** — add a section to `references/model-notes.md` with its *Add* / *Remove* lists.
- **Deeper or faster** — set `effort: high` (or `low`) in the `SKILL.md` frontmatter to override the session effort while the skill runs.
- **Manual only** — add `disable-model-invocation: true` to the frontmatter if you don't want Claude invoking it on its own.

## Sources

- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) — techniques for all current models
- [Prompting Claude Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)
- [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- [Prompting Claude Sonnet 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5)
- [Claude Code best practices](https://code.claude.com/docs/en/best-practices) and the [skills reference](https://code.claude.com/docs/en/skills)

Model guidance changes with each release: when a new model page appears, add a section to `references/model-notes.md`; when the general page changes, update `references/principles.md`. Keep `SKILL.md` short — it's the part that stays in context.

## Contributing

Issues and PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the layout rules and the most useful kinds of contribution (a new model section, a better before→after example, a grounding trick for another ecosystem). Run `bash scripts/validate.sh` before opening a PR.

## License

[MIT](LICENSE) © 2026 Taha Bozdemir
