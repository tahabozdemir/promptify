# Model-specific notes

Apply the section for the **target** model: the session model unless `--model` says otherwise. Inside Claude Code the session model is named in the system prompt (and by `/model`); a subagent's model comes from its agent-file frontmatter; an API app's model from its code. Sources: [Prompting Claude Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5), [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5), [Prompting Claude Sonnet 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5), and the model sections of the [general best-practices page](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices).

The common theme across the Claude 5 family: **capability went up, so prescriptiveness should go down.** Prompts and skills written for 4.x are often too detailed; review them and remove instructions the model now does by default.

---

## Claude Fable 5 / Claude Mythos 5

Strengths worth exploiting in the prompt: long-horizon autonomy (multi-day runs), first-shot correctness on complex *well-specified* problems, dense-image vision, code review and debugging recall, navigating ambiguous multithreaded requests, dispatching and sustaining parallel subagents. Start at the top of your difficulty range: hand it the hardest version of the task, with scope, and let it ask clarifying questions.

**Add**

- *The reason.* Fable 5 performs better when it understands intent: "I'm working on [X] for [who]. They need [what]. With that in mind: [request]."
- *Act when ready* (prevents over-planning on ambiguous tasks): "When you have enough information to act, act. Do not re-derive facts already established, re-litigate a decision already made, or narrate options you will not pursue. If you are weighing a choice, give a recommendation, not an exhaustive survey."
- *Brevity by selection, not compression* (it can elaborate at higher effort): "Lead with the outcome: your first sentence after finishing should answer 'what happened' or 'what did you find'. Keep output short by being selective about what you include, not by compressing into fragments, abbreviations, arrow chains, or jargon. Readability matters more than concision."
- *Checkpoint rule* (no need to enumerate cases): "Pause for the user only when the work genuinely requires them: a destructive or irreversible action, a real scope change, or input only they can provide. If you hit one of these, ask and end the turn rather than ending on a promise."
- *Grounded progress claims* on long runs (nearly eliminates fabricated status): "Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so. If tests fail, say so with the output; if a step was skipped, say that."
- *Boundaries* (it can take unrequested actions such as drafting an email or creating backup branches): "When the user is describing a problem or thinking out loud rather than requesting a change, the deliverable is your assessment — report and stop. Before running a command that changes system state, check that the evidence supports that specific action."
- *Autonomy reminder* for unattended pipelines (rare early stopping on a statement of intent): "You are operating autonomously; no one can answer mid-task. For reversible actions that follow from the request, proceed without asking. Before ending your turn, check your last paragraph — if it is a plan, a question, or a promise about work not done, do that work now. End only when the task is complete or blocked on input only the user can provide."
- *Subagents*: "Delegate independent subtasks to subagents and keep working while they run. Intervene if a subagent goes off track or is missing relevant context." Prefer long-lived subagents and asynchronous check-ins over blocking on each one.
- *Self-verification cadence on long builds*: "Establish a method for checking your own work at an interval of [X] as you build; verify with fresh-context subagents against the specification." Fresh verifier subagents beat self-critique.
- *Memory*: give it a place to record lessons ("one lesson per file, one-line summary at top, record corrections and confirmed approaches with why; don't save what the repo already records; update rather than duplicate; delete wrong notes").
- *Readable final summary* after long agentic stretches: "Your final message is the user's first look at the work. Open with the outcome, then the one or two things you need from them. Drop the working shorthand: complete sentences, spelled-out terms, each file/commit/flag in its own plain clause."

**Remove / avoid**

- Enumerated behaviour lists where one sentence would do; older prescriptive skills and step scripts (they degrade output).
- "Show / reproduce / explain your reasoning" instructions — can trigger the `reasoning_extraction` refusal and fall back to Opus 4.8. Ask for conclusions and evidence instead.
- Context-budget countdowns or talk of running out of context. If the harness shows them: "You have ample context remaining. Do not stop, summarize, or suggest a new session on account of context limits."
- Offensive-cybersecurity and biology/life-sciences asks — safety classifiers may return `stop_reason: refusal`; route those elsewhere.

**Effort**: `high` is the default for most tasks; `xhigh` for the most capability-sensitive work; `medium`/`low` for routine work still perform well (often above prior models at `xhigh`). Turns run longer at higher effort — mention in the prompt when a quick interactive pass is wanted. To stop unrequested tidying at high effort, include the anti-over-engineering paragraph from `principles.md` §10.

---

## Claude Opus 5

Strengths: difficult multi-file coding and end-to-end features (completes rather than stubs; best when given the whole spec up front and left to run), high-precision code review, strong quality at `low`/`medium` effort, 1M-token context with consistent behaviour throughout, spreadsheets and slide decks, multi-agent writer–verifier patterns.

**Add**

- *Conciseness, explicitly* — effort controls thinking, not visible length: "Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested." In long system prompts add a reminder near the end: `<tone_preference>Keep outputs reasonably concise.</tone_preference>`.
- *Narration cadence* during agentic work: "Before your first tool call, say in one sentence what you're about to do. While working, give a brief update only when you find something important or change direction. When you finish, lead with the outcome."
- *Document length calibration* for files it writes: "Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate."
- *Scope constraint* (it can widen tasks): "Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it."
- *Subagent damping* when cost matters: "Delegate to a subagent only for large tasks that are genuinely independent and parallelizable, such as a wide multi-file investigation. Do not delegate work you can finish yourself in a handful of tool calls, and do not use subagents to verify or double-check your own work. If one subagent can complete the task, use one rather than several." (Deterministic caps: `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`, SDK `max_budget_usd`.)
- *Correction narration limiter* for user-facing products: "Only correct an earlier statement when the error would change the user's code, conclusions, or decisions. State corrections plainly and briefly, then continue."
- *Code review*: it follows "only report high-severity" literally. Ask for everything with confidence + severity and filter in a later pass.

**Remove**

- Every explicit verification instruction ("include a final verification step", "use a subagent to verify", "double-check your answer", "re-verify before responding") and legacy harness verification stages — Opus 5 verifies on its own; these cause over-verification with no quality gain. Remove rather than rewrite.

**Thinking off**: only possible at effort ≤ `high`; it can leak tool calls as text or internal XML tags. Prefer thinking on at `low` effort. If it must be off: "When you use a tool, you may say a brief sentence first. If no tool can express what the user asked for, say so instead of guessing. Do not include internal or system XML tags in your response." (Do not name thinking tags specifically; do not add "do not think" rules.)

**Effort**: start at the default `high`; use `low`/`medium` liberally where quality holds; `xhigh` for demanding agentic work. Re-sweep effort on your own evals rather than inheriting 4.8 defaults.

---

## Claude Sonnet 5

Strengths: coding and agentic tasks; calibrates response length to task complexity; regular, good-quality progress updates; literal, predictable instruction following (great for pipelines and structured extraction).

**Add**

- *Explicit scope of instructions* — it does not silently generalize: "Apply this formatting to every section, not just the first one."
- *Concision if needed*: "Provide concise, focused responses. Skip non-essential context, and keep examples minimal." Positive examples of the wanted style beat negative instructions.
- *Reasoning nudge only when stuck at `low` effort for latency*: "This task involves multistep reasoning. Think carefully through the problem before responding." Otherwise raise effort instead of prompting around shallow reasoning.
- *Tool nudge* if thinking is disabled or a tool under-triggers: describe clearly why and when to use it.
- *Tone* if the product voice matters: "Use a warm, collaborative tone. Acknowledge the user's framing before answering." (`temperature`/`top_p`/`top_k` return 400 — steer style with the prompt.)
- *Design briefs*: either specify a concrete direction (palette hexes, type, radius, spacing, motion) or "Before building, propose 4 distinct visual directions (bg hex / accent hex / typeface + one-line rationale), ask the user to pick one, then implement only that." Plus the short `<frontend_aesthetics>` directive.
- *Code review for coverage*: "Report every issue you find, including ones you are uncertain about or consider low-severity. Do not filter for importance or confidence at this stage — a separate verification step will do that. For each finding, include your confidence level and an estimated severity." If single-pass, state the bar concretely ("anything that could cause incorrect behaviour, a test failure, or a misleading result; omit pure style nits").
- *Interactive coding products*: specify task, intent, and constraints up front in the first turn; under-specified prompts drip-fed across turns cost tokens and quality.

**Remove**

- Scaffolding that forces interim status messages ("after every 3 tool calls, summarize") — it already updates well.
- Manual extended thinking (`budget_tokens`) — 400 error. Adaptive thinking is on by default; `max_tokens` now covers thinking + answer, and the new tokenizer yields ~30 % more tokens for the same text, so leave headroom.

**Effort**: default `high`; `xhigh` for the hardest coding/agentic work; `medium` ≈ Sonnet 4.6 `high`; `low` only for short, scoped, latency-sensitive tasks (respects effort strictly — may under-think at `low`).

---

## Claude Opus 4.8 / 4.7 / 4.6

(No dedicated page fetched for 4.8; this is from the general guide's model sections, which describe the same levers — response length, effort, tool triggering, literal following, subagent control, design defaults.)

- More responsive to the system prompt than earlier models: dial back "CRITICAL/MUST" tool-triggering language or tools over-trigger.
- More upfront exploration, especially at high effort: replace blanket defaults ("default to using X") with targeted ones ("use X when it would enhance understanding"); remove "if in doubt, use X"; lower effort as a fallback. Add the commit-to-an-approach sentence from `principles.md` §9 if it overthinks.
- Strong predilection for subagents (spawns them for things a `grep` would answer) — include the subagent-usage paragraph from `principles.md` §10.
- Tendency to over-engineer (extra files, abstractions, unrequested flexibility) — include the anti-over-engineering paragraph.
- May take hard-to-reverse actions without guidance — include the reversibility paragraph.
- Good vision; a crop/zoom tool gives consistent uplift.
- 4.6 is the first line with adaptive thinking; `budget_tokens` deprecated on 4.6, removed on 4.7+.

## Claude Sonnet 4.6 / 4.5, Haiku 4.5

- Context awareness: they track their remaining token budget; pair with the memory tool for long sessions, and include the "context will be compacted, don't stop early" paragraph in agent harnesses.
- Sonnet 4.6 still accepts manual extended thinking (deprecated); Haiku 4.5 and Sonnet 4.5 use manual extended thinking.
- Older prompts may legitimately need a little more explicitness and a self-check line; the over-prompting warnings above apply less.
- When extended thinking is disabled, Opus 4.5 is sensitive to the word "think" — prefer "consider", "evaluate", "reason through".

---

## Claude Code harness notes (any model)

- The harness already provides the role, tool descriptions, CLAUDE.md, and the permission model. A user-turn prompt should not restate them; reference them ("follow the release procedure in CLAUDE.md").
- Effort is a session setting (`/effort`, or `effort:` in a skill's frontmatter); a prompt can ask for a quick pass or a deep pass in words, but cannot set the parameter.
- `@path/to/file` in a prompt makes Claude read it first; pasted screenshots and URLs are read directly.
- Plan mode (`Shift+Tab`) is the right container for "explore, then plan, then implement" — suggest it in the prompt for uncertain, multi-file, or unfamiliar changes; skip it when the diff fits in one sentence.
- Subagents run in their own context: recommend them for wide investigations or fresh-eyes review so the main context stays clean.
- For a big feature, the best first prompt is often an interview: "Interview me in detail using the AskUserQuestion tool about implementation, UI/UX, edge cases, and tradeoffs; then write a complete spec to SPEC.md" — then implement from the spec in a fresh session.
