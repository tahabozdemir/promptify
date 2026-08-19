---
name: promptify
description: Rewrite a rough, vague, or bloated prompt into a best-practices prompt for the Claude model in use, grounded in the current repo (real file paths, existing patterns, the test/build command that proves the change, CLAUDE.md conventions). Use when the user says "upgrade/improve/optimize/rewrite my prompt", "make this a better prompt", "how should I ask for this", "promptify", or pastes a task and wants it phrased properly before running it. Produces the prompt; runs it only with --run.
argument-hint: "[--run] [--model <name>] <raw prompt>"
license: MIT
allowed-tools: Read, Grep, Glob, Bash(${CLAUDE_SKILL_DIR}/scripts/snapshot.sh), Bash(${CLAUDE_SKILL_DIR}/scripts/snapshot.sh *), Bash(git *)
---

# Prompt upgrade

Turn the raw prompt below into the prompt an expert on this codebase would have written for this model: specific, grounded in real files, verifiable, and no longer than the task needs. The rewritten prompt is the deliverable; the task itself is not executed unless `--run` is passed.

## Input

<raw_prompt>
$ARGUMENTS
</raw_prompt>

If `<raw_prompt>` is empty, treat the user's previous message as the raw prompt. If there is none, ask for it and end the turn.

Flags (strip them from the raw prompt before working):

- `--run` — after presenting the upgraded prompt, execute it as written in this same turn.
- `--model <name>` (also accepted as `--mode <name>`) — tune for that model instead of the one running this session (for example a subagent on Sonnet 5, or an API app on Opus 5). Without it, the target is the current session model, which your system prompt names.

## Repo snapshot

Collected automatically before you start (session effort: `${CLAUDE_EFFORT}`):

!`${CLAUDE_SKILL_DIR}/scripts/snapshot.sh`

## Workflow

1. **Classify.** Decide, briefly, what kind of prompt this is: feature, bug fix, refactor, question or explanation, code review, research or investigation, docs or writing, design or frontend, a long autonomous run, or a system prompt for an application. Decide its size: a one-sentence diff, a bounded change, multi-file work, or autonomous. And decide what it really asks for: implement, suggest, or explain. These three choices drive everything below.

2. **Ground it in the repo.** Spend a handful of tool calls (roughly 3–8; more only for multi-file work) finding the facts the prompt should name: the files or modules actually involved, an existing pattern worth copying, the command that proves the change (test, build, lint, script, screenshot), the conventions CLAUDE.md or AGENTS.md already impose, and any project workflow (agents, skills, hooks, pipelines) the prompt should route through. Prefer `Grep`, `Glob`, `git log -S`, and reading a few hundred targeted lines over whole-file dumps; for a wide sweep use an Explore-type subagent so your own context stays clean. Never invent a path: if you cannot confirm a file exists, phrase it as something to discover ("find where X is configured") rather than naming it. `references/repo-grounding.md` lists what to look for per task type and how to find it cheaply.

3. **Rewrite.** Apply `references/principles.md` (techniques for all current models) and the section of `references/model-notes.md` for the target model. Keep the shape proportional to the task, using `templates/prompt-template.md` and the before/after pairs in `references/examples.md` as calibration:
   - one-sentence diff → two to five plain sentences, no tags, no headings;
   - bounded change → short paragraphs, or a few tagged sections when the prompt mixes context, task, and constraints;
   - multi-file, autonomous, or system prompt → the full template.

4. **Present.** Your message has four parts and nothing else:
   - the upgraded prompt in one fenced block, ready to paste or run;
   - **Grounded in** — two to five bullets naming the repo facts that shaped it (paths, commands, conventions);
   - **Assumptions** — at most three, and only ones that would change the work if wrong; omit the section when there are none;
   - one closing line: "Say **run it** to execute this prompt as written." When `--run` was passed, skip the line and execute the prompt instead, treating it as the user's instruction.

## Rules that always apply

- **Preserve intent.** Add context, structure, and verification; do not change what is being asked, narrow it, or widen it. If the raw prompt looks mistaken (wrong file, impossible ask, a question phrased as a command), keep its intent and surface the doubt under Assumptions.
- **Write for the model in use.** Current Claude models follow a brief instruction as well as an enumerated list, so one clear sentence with its reason beats a checklist of behaviors. Do not add all-caps emphasis ("CRITICAL", "YOU MUST"), "be thorough", "double-check your work", "verify with a subagent", "show your reasoning", or hand-written think-step-by-step scripts: on current models these over-trigger, cost tokens, or in the case of reasoning-echo instructions can trip a refusal on Fable 5. The per-model deltas live in `references/model-notes.md`.
- **Positive over negative.** Say what to do rather than what to avoid; when a prohibition is needed, give the reason so the model can generalize.
- **Give the reason, not only the request.** One sentence on why, or for whom, whenever it is not obvious. Claude connects the task to the right context instead of guessing at intent.
- **Make it verifiable.** Every change-type prompt names a check Claude can run and asks for the evidence (test output, build exit code, screenshot) rather than a claim of success. Without a check, the user becomes the verification loop.
- **Right-size the action.** Questions and thinking-out-loud become assessment-only prompts ("report findings; don't change files"). Change requests use direct verbs ("change", "implement", "add") instead of "can you suggest". Anything destructive or visible to others (deletes, force-push, posting, sending) gets an explicit confirm-first clause.
- **Honor the project's own rules.** When CLAUDE.md, AGENTS.md, skills, agents, or hooks already define a workflow, style, or forbidden action, the prompt routes through it rather than restating it. What is already loaded in context does not need repeating.
- **Long material at the top, the ask at the bottom.** If the prompt carries logs, diffs, or documents, wrap them in `<document>`-style tags first and put the instruction last; queries at the end measurably improve results on long inputs.
- **Don't pad.** No preamble, no restating the repo, no generic advice ("write clean code", "follow best practices"). If a section would be empty or obvious, leave it out. A prompt that is longer than it needs to be is a worse prompt.
