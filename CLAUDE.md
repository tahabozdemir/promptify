# promptify — notes for agents working in this repo

This repo *is* a Claude Code skill: `SKILL.md` at the root is the product; everything else supports it. (When installed as a plugin this file is not loaded — it is only for contributors.)

- Keep `SKILL.md` short; it is the only file that stays in context when the skill runs. Detail goes in `references/`, prompt shapes in `templates/`.
- The skill's own rules apply to edits here: positive instructions with reasons, no all-caps emphasis, no "be thorough / double-check / show your reasoning".
- `scripts/snapshot.sh` is injected into the prompt before the skill runs and must exit 0 everywhere (a failing injected command aborts the skill).
- Bump the version in three places together: `SKILL.md` frontmatter `metadata.version`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.
- Before finishing any change: `bash scripts/validate.sh`.
