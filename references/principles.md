# Prompting principles for current Claude models

Condensed from Anthropic's [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) (applies to Fable 5.1/5, Mythos 5.1/5, Opus 5.5/5, Opus 4.8/4.7/4.6, Sonnet 5/4.6, Haiku 4.5). Use this as the checklist when rewriting; the model-specific deltas are in `model-notes.md`. Snippets in code blocks are Anthropic's tested wording — reuse them when the situation calls for it, and prefer a short paraphrase when the full block would dwarf the task.

## 1. Clear and direct

- Treat Claude as a brilliant new colleague without your context. **Golden rule:** if a colleague with minimal context would be confused by the prompt, Claude will be too.
- Be specific about the desired output and its constraints. If you want "above and beyond" behaviour, ask for it: *"Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation."*
- Use numbered steps only when the order or completeness of steps matters.
- Use action verbs when you want action. "Can you suggest some changes?" yields suggestions; "Change this function to improve its performance" yields changes.

## 2. Context and motivation

Explain *why* an instruction exists; Claude generalizes from the reason.

- Weaker: "NEVER use ellipses."
- Stronger: "Your response will be read aloud by a text-to-speech engine, so never use ellipses since the engine will not know how to pronounce them."

Template for the request itself (especially for long-running or multi-workstream agents):

```text
I'm working on [the larger task] for [who it's for]. They need [what the output enables]. With that in mind: [request].
```

## 3. Examples

The most reliable way to steer format, tone, and structure. Make them **relevant** (mirror the real use case), **diverse** (cover edge cases, vary enough that no accidental pattern is learned), **structured** (`<example>` tags, several inside `<examples>`). Three to five is the sweet spot. Positive examples of the style you want beat instructions about what not to do.

## 4. XML structure

Wrap each kind of content in its own tag when a prompt mixes instructions, context, examples, and variable input: `<instructions>`, `<context>`, `<input>`, `<constraints>`, `<success_criteria>`, `<output_format>`. Use consistent, descriptive names; nest when content has a hierarchy (`<documents>` → `<document index="n">` → `<source>`, `<document_content>`). Tags earn their place in medium and large prompts; a two-line request does not need them.

## 5. Role (system prompts)

A one-sentence role in the system prompt focuses behaviour: *"You are a helpful coding assistant specializing in Python."* Inside Claude Code the harness already supplies the role, so a user-turn prompt should not restate one; only add a role when writing a system prompt for an application or a subagent.

## 6. Long context (20k+ tokens)

- Put long documents and data at the **top**, above the query, instructions, and examples. Queries at the end improved results by up to 30 % in tests.
- Wrap each document: `<document index="1"><source>name</source><document_content>…</document_content></document>`.
- Ask Claude to **quote relevant parts first** (`<quotes>`), then do the task — it focuses attention and ignores the rest.

## 7. Output and formatting

- Tell Claude what to do, not what not to do: instead of "Do not use markdown", say "Your response should be composed of smoothly flowing prose paragraphs."
- XML format indicators work: "Write the prose sections in `<smoothly_flowing_prose_paragraphs>` tags."
- Match prompt style to desired output style (less markdown in the prompt → less in the output).
- Current models skip verbal summaries after tool calls unless asked: *"After completing a task that involves tool use, provide a quick summary of the work you've done."*
- LaTeX is the default for math; ask for plain text explicitly if needed.
- Prefilled assistant turns are no longer supported (400 error from 4.6 on). Use structured outputs, tools with enum fields, or a direct instruction: "Respond directly without preamble. Do not start with phrases like 'Here is…'."

Anthropic's prose-over-bullets block, for long-form deliverables:

```text
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form content, write in clear, flowing prose using complete paragraphs and sentences. Use standard paragraph breaks for organization and reserve markdown primarily for `inline code`, code blocks, and simple headings (## and ###). Avoid using **bold** and *italics*.
DO NOT use ordered or unordered lists unless: a) you're presenting truly discrete items where a list format is the best option, or b) the user explicitly requests a list or ranking. Instead, incorporate items naturally into sentences. NEVER output a series of overly short bullet points.
Your goal is readable, flowing text that guides the reader naturally through ideas rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

## 8. Tool use and action calibration

Current models follow instructions precisely and benefit from explicit direction on whether to act.

More proactive by default:

```text
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing. Try to infer the user's intent about whether a tool call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

More conservative by default:

```text
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

Dial back aggressive language: "CRITICAL: You MUST use this tool when…" now over-triggers; "Use this tool when…" is enough. Replace "If in doubt, use [tool]" with "Use [tool] when it would enhance your understanding of the problem."

Parallel tool calls happen by default; to push toward 100 %:

```text
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the tool calls, make all of the independent tool calls in parallel. Prioritize calling tools simultaneously whenever the actions can be done in parallel rather than sequentially. However, if some tool calls depend on previous calls to inform dependent values like the parameters, do NOT call these tools in parallel and instead call them sequentially. Never use placeholders or guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

## 9. Thinking

- Adaptive thinking is on for 4.6+ (always on for Fable 5.1/5, Mythos 5.1/5, and Opus 5.5; on by default for Opus 5 and Sonnet 5). `effort` is the depth control; `budget_tokens` is gone from 4.7 on.
- **Prefer general instructions over prescriptive steps.** "Think thoroughly about X" beats a hand-written step plan; the model's own reasoning usually exceeds what a human would script.
- Reflection after tools: *"After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding."*
- To reduce overthinking: *"When you're deciding how to approach a problem, choose an approach and commit to it. Avoid revisiting decisions unless you encounter new information that directly contradicts your reasoning."*
- To reduce thinking frequency under big system prompts: *"Thinking adds latency and should only be used when it will meaningfully improve answer quality, typically for problems that require multistep reasoning. When in doubt, respond directly."*
- Self-check ("Before you finish, verify your answer against [criteria]") helps on most models — **except Opus 5 and 5.5**, which already verify; there, remove such lines (see `model-notes.md`).
- **Never ask the model to echo or transcribe its internal reasoning in the response** — on Fable 5, Fable 5.1, and Opus 5.5 this can trigger the `reasoning_extraction` refusal. Ask for conclusions and evidence, not reasoning transcripts.

## 10. Agentic coding

Investigate before answering (kills hallucinated claims about code):

```text
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a specific file, you MUST read the file before answering. Make sure to investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain of the correct answer - give grounded and hallucination-free answers.
</investigate_before_answering>
```

Avoid over-engineering (short form, suitable for most change prompts):

```text
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Don't add features, refactor, or introduce abstractions beyond what the task requires; a bug fix doesn't need surrounding cleanup. Don't add docstrings, comments, or type annotations to code you didn't change. Don't add error handling or validation for scenarios that can't happen — validate only at system boundaries. Don't create helpers for one-time operations or design for hypothetical future requirements.
```

General-purpose solutions rather than test-gaming:

```text
Write a high-quality, general-purpose solution using the standard tools available. Do not create helper scripts or workarounds to accomplish the task more efficiently. Implement a solution that works correctly for all valid inputs, not just the test cases. Tests are there to verify correctness, not to define the solution. If the task is unreasonable or infeasible, or if any of the tests are incorrect, tell me rather than working around them.
```

Reversibility and shared systems:

```text
Consider the reversibility and potential impact of your actions. Take local, reversible actions like editing files or running tests freely, but for actions that are hard to reverse, affect shared systems, or could be destructive, ask before proceeding — deleting files or branches, rm -rf, git push --force, git reset --hard, amending published commits, pushing code, commenting on PRs/issues, sending messages. When encountering obstacles, do not use destructive actions as a shortcut (no --no-verify, no discarding unfamiliar files).
```

Subagents — when they are and are not warranted:

```text
Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams that don't need to share state. For simple tasks, sequential operations, single-file edits, or tasks where you need to maintain context across steps, work directly rather than delegating.
```

Temporary files: *"If you create any temporary new files, scripts, or helper files for iteration, clean up these files by removing them at the end of the task."*

Long-horizon work (multi-context-window): use the first window to set up the framework (tests, `init.sh`, `progress.txt`, `tests.json`); tell the model it may not remove or edit tests; remind it that context compacts so it should not stop early; be prescriptive about how a fresh window restarts ("Review progress.txt, tests.json, and the git log; re-run the fundamental integration test before new work"); use git as the state log.

```text
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Never artificially stop any task early regardless of the context remaining.
```

Research: give success criteria, ask for cross-source verification, and for hard problems: *"develop several competing hypotheses, track confidence in your notes, regularly self-critique, and keep a hypothesis tree or research notes file."*

Frontend: models converge on an "AI slop" aesthetic. Either specify a concrete visual direction, have the model propose 3–4 directions first, or include the `<frontend_aesthetics>` directive (distinctive typography, committed palette with CSS variables, purposeful motion, atmospheric backgrounds; avoid Inter/Roboto/Arial, purple-gradient-on-white, cookie-cutter layouts). A general "avoid the AI look" only swaps one default style for another; naming the specific patterns to avoid works better (Opus 5.5 list in `model-notes.md`). The full treatment is the `frontend-design` skill.

## 11. Migration reminders (prompts written for older models)

1. Be specific about desired behaviour; add quality modifiers where you want more.
2. Request animations/interactivity explicitly.
3. Replace `budget_tokens` with adaptive thinking + `effort`.
4. Remove prefills.
5. **Tune down anti-laziness prompting** — "be thorough", "use tools aggressively", "always double-check" now over-trigger.

## 12. What to strip from a raw prompt, and why

| Found in raw prompt | Do instead | Why |
| --- | --- | --- |
| ALL CAPS / "CRITICAL" / "YOU MUST" | Plain sentence with the reason | Current models over-trigger on emphasis; one clear instruction suffices |
| "be thorough", "explore everything", "if in doubt, use X" | Targeted: "use X when it would improve understanding of Y" | Over-exploration and tool over-triggering |
| "double-check", "verify again", "use a subagent to verify" | Name the concrete check once (test/build), or nothing on Opus 5 / 5.5 | Over-verification; Opus 5 and 5.5 already verify |
| "think step by step and show your reasoning" | "Think carefully about X" / ask for conclusions + evidence | Prescriptive steps underperform; reasoning echo can trip Fable 5 / 5.1 and Opus 5.5 refusals |
| "don't do X" with no reason | "do Y" or "don't do X because Z" | Positive framing and reasons generalize |
| "can you suggest…" when changes are wanted | "change/implement/add…" | Literal instruction following |
| "fix it" / "make it better" with no check | Symptom + location + what fixed looks like + the command that proves it | Without a check the user is the verification loop |
| Vague scope ("clean up the module") | Files in scope, behaviour to preserve, what is out of scope | Prevents scope creep and over-engineering |
| Prefilled assistant text | Structured outputs / direct instruction | Unsupported from 4.6 on |
| Restating CLAUDE.md or the system prompt | Reference it or leave it out | Already in context; repetition dilutes |
