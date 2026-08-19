# Contributing

Issues and pull requests are welcome. This is a single-skill repo: `SKILL.md` at the root is the skill, and everything else supports it.

## Layout rules

```
SKILL.md                 the skill — keep it short, it is the only file that stays in context
scripts/snapshot.sh      repo snapshot injected into the prompt; must always exit 0
scripts/validate.sh      checks the repo before a PR
references/*.md          reference material loaded on demand — put detail here, not in SKILL.md
templates/*.md           prompt shapes
.claude-plugin/          plugin + marketplace manifests (version lives here and in SKILL.md frontmatter)
```

- `SKILL.md` frontmatter: `name` must stay `promptify` (the `skills` CLI and the plugin loader take the install name from it); `description` leads with the key use case and stays under 1,536 characters; bump `metadata.version` together with `.claude-plugin/*.json` when behaviour changes.
- Keep `SKILL.md` under ~150 lines. If a rule needs more than a sentence of explanation, the explanation goes in `references/`.
- Positive instructions with reasons; no all-caps emphasis, no "be thorough / double-check / show your reasoning" — the skill's own rules apply to the skill.

## The most useful contributions

- **A new model** — add a section to `references/model-notes.md` with its *Add* / *Remove* lists, citing the model's prompting page on platform.claude.com.
- **A better example** — add a before→after pair to `references/examples.md`. Examples steer the output more reliably than rules; keep paths illustrative and say so.
- **A grounding trick** — add to `references/repo-grounding.md` how to find the pattern / test command cheaply for another ecosystem.
- **A snapshot probe** — extend `scripts/snapshot.sh` for another manifest or test layout. Guard every probe; the script must exit 0 in a git repo, in a non-git folder, and in an empty directory.

## Before you open a PR

```bash
bash scripts/validate.sh
```

It checks the frontmatter, the referenced files, the snapshot script in three environments, and (if the `claude` CLI is installed) runs `claude plugin validate . --strict`. Then try the skill on a real repo: `/promptify <some rough prompt>` and read the result as if you were the person who'd have to run it.

## Commit messages

Conventional style is appreciated but not enforced: a one-line subject saying what changed and why.
