# Model-specific notes

Apply the section for the **target** model: the session model unless `--model` says otherwise. Inside Claude Code the session model is named in the system prompt (and by `/model`); a subagent's model comes from its agent-file frontmatter; an API app's model from its code. Sources: [Prompting Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1), [Prompting Claude Fable 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5), [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5), [Prompting Claude Sonnet 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5), and the model sections of the [general best-practices page](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices).

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

## Claude Fable 5.1 / Claude Mythos 5.1

Everything in the Fable 5 section applies: Anthropic's guidance is that prompts written for Fable 5 perform well on 5.1 without changes, and the capability gains are largest at the higher effort levels. The items below are the behaviours that shifted between the two releases; add one only when the raw prompt's task would actually run into it. Source: [Prompting Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1).

**Add**

- *Scope and test sprawl* on feature work — 5.1 may fix nearby code, extend behaviour the task never mentioned, or commit more test files than the change warrants. This paragraph cuts both with no measured loss in task success; prefer it over the generic anti-over-engineering paragraph whenever tests are part of the work:

  ```text
  If, while working or testing, you find a pre-existing bug, a performance concern, or behavior the task doesn't mention, don't fix, optimize or extend it in this change unless the requested behavior cannot work without it; report it as a follow-up in your summary. Where the task is ambiguous, implement the reading its wording and the surrounding code most directly support, state that assumption in your summary, and don't build for the other readings as well. Verify your work however you like; scratch scripts and quick checks need not be kept. Commit tests only where the task asks for them or this repository already keeps tests for this kind of change, sized like the neighboring test files — roughly one focused test per stated behavior — and don't turn scratch checks into additional permanent test files. This is about extras only: implement every behavior the task asks for, completely.
  ```

- *Finish the whole task* on autonomous runs — 5.1 can end a turn on "Next, I'll…" or ask "Shall I apply this?" for work the request already covered. Two blocks together fix it; when prompt length matters, the first alone keeps most of the effect. Keep its opening sentence as written (it carries much of the effect) and, if the product needs specific confirmations, list them in a sentence right after it. The block also makes the model ask less about genuinely ambiguous requests, so check that trade-off on your own tasks.

  ```text
  You are operating autonomously. The user is not watching in real time and cannot answer questions mid-task, so asking 'Want me to…?' or 'Shall I…?' will block the work. For reversible actions that follow from the original request, proceed without asking. Stop only for destructive actions or genuine scope changes the user must decide. Offering follow-ups after the task is done is fine; asking permission before doing the work is not.

  Exception: when the user is describing a problem, asking a question, or thinking out loud rather than requesting a change, the deliverable is your assessment. Report your findings and stop. Don't apply a fix until they ask for one.

  Before ending your turn, check your last paragraph. If it is a plan, an analysis, a question, a list of next steps, or a promise about work you have not done ('I'll…', 'let me know when…'), do that work now with tool calls. That includes retrying after errors and gathering missing information yourself. Do not stop because the context or session is long. End your turn only when the task is complete or you are blocked on input only the user can provide.

  Before running a command that changes system state (such as restarts, deletes, or config edits), check that the evidence actually supports that specific action. A signal that pattern-matches to a known failure may have a different cause.
  ```

  ```text
  # Delivering work
  The user's request — or the plan they approved — sets the scope, and the scope is the deliverable: don't quietly narrow, widen, or swap it. Read ambiguity the way a careful colleague would: make routine judgment calls yourself, and check in only when different readings would lead to materially different work. If you see a real problem with the task as specified, say so in a sentence or two and keep building under stated assumptions; if the user hears the concern and reaffirms, that is their decision, so deliver the full request.

  If a question comes up partway, first do everything that doesn't depend on the answer; then state the assumption you made, or — when going ahead on a wrong guess would be unsafe or would make the work useless — put the question at the end of a turn that also delivers that progress. If one part turns out to be blocked, complete every other part in full and say exactly what you left out and why — the whole task is the deliverable, and scaling it down is the user's call, not yours. A step you have decided on is something to run, not to announce: describing the next step and ending the turn leaves it undone until the user replies.

  Keep changes to what the request needs. Something else you notice worth doing — cleanup or documentation the task didn't call for, a change to a file the task didn't require — is a suggestion to make at the end, not a change to make; actions clearly beyond what the ask implies, and risky or destructive ones, still need the user's go-ahead.
  ```

- *Progress updates* — 5.1 writes fewer user-facing notes during long tool-calling turns than Fable 5, more so at high effort and in long tool chains, so users see the agent go quiet or get a final message that covers only the last step. Delete anything that suppresses narration first ("hold all findings for the final response"); then, for pair programming and other human-in-the-loop work, one line: "Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own — what you found, what you did, and what's next — so a reader who only sees the last message has the full picture."
- *Mannered prose* for docs, reports, and other written deliverables — 5.1 writes better than earlier models (fewer stock phrases, less jargon) but can run denser: longer sentences, fewer paragraph breaks. In the user message (preferred) or the system prompt: "Please remove all mannered prose." If that is not enough, define the anti-pattern: metaphor and flourish standing in for direct statement ("a dial worth turning" for "a parameter worth varying", "earns its keep" for "still matters"); it makes the reader work so the writer can perform, and it drags in connotations the writer did not choose. When a literal phrase is available, use it.
- *Quoting retrieved sources* for research and summarization — 5.1 is more likely than Fable 5 to reproduce source passages without marking them as quotations. Add one complete example to the system prompt: the user's request, the response, and a sentence saying why it is correct. Show each source conveyed in one or two sentences of the assistant's own indirect speech, organized around where the sources agree and differ rather than as a walk through each one, with at most one short marked phrase quoted. Write the example's tool calls with the tool's real name (`[web_search: …]`) so the model reads them as templated output, not text to emit.
- *Search at low effort* — at `low`, 5.1 answers from memory where Fable 5 would have searched. Raise effort for the affected turns, or in the system prompt: "When a query centers on a name you do not confidently recognize, or recognize from a fast-moving area like AI models and developer tools where the landscape shifts within months, the name itself is the thing to verify: search before answering, and include the name as the user wrote it in at least one query alongside any reformulations. This holds even when you have some background on it — partial background is exactly what makes an out-of-date answer sound authoritative, so familiarity is not a reason to skip the search."
- *Surgical edits* when a small change lands in a large file — 5.1 is more likely than Fable 5 to rewrite the whole file; the result is usually identical but costs output tokens and time. In the system prompt or first user message: "The number of tokens used to edit files is best minimized, all else being equal. Therefore, when it will not affect the end result, try to surgically edit a file rather than rewrite the entire thing."
- *Batching in custom agent loops* (coding and computer-use harnesses you build; Claude Code already does this) — when the next independent calls are implied by the task rather than named, 5.1 may issue one per turn. After each batch of tool results append, as a turn-scoped system message (`clear_at: "next_user_message"`, beta `mid-conversation-system-clear-at-2026-08-21`) or as a text block after the `tool_result` blocks: "First privately list what you need next; then request every item that doesn't depend on another's result in this one response." Leave earlier copies in place; the API clears them.
- *Long deliverables at `xhigh` or `max`* — 5.1 may draft the whole document in thinking and then write it again as the reply. Run these at `high`; if a higher level is measured to help, set `max_tokens` to cover thinking plus reply and end the user message with (fill in the real `max_tokens`): "Everything produced in one reply, including any reasoning or drafting done before the reply, counts toward a single limit of about [max_tokens] tokens. If that limit is reached before the reply is finished, the person receives a cut-off response and has to start over. Composing an entire output or deliverable in full as reasoning and then again as a reply would double the length of the turn without improving the result, so don't do that. Instead, when the person has asked for a long or effort-intensive deliverable such as a multi-section document, a large table or dataset, or a complete code file, spend extra effort on understanding the request, checking the inputs the answer depends on, settling the structure and other difficult decisions, and otherwise using the reasoning space to reason and the output space to write an output. Usually it is not needed to draft an output multiple times."
- *When-to-format rule* for chat products — 5.1 uses bold, headers, and lists less than earlier models, so replies can carry less structure than the content needs. Replace anti-formatting rules with: "Use lists and bullet points when asked to, or when the content is multifaceted enough that they help with clarity. If the person explicitly requests minimal formatting, always format your responses without bullet points, headers, lists, or bold emphasis, as requested. In conversational, personal, or emotional exchanges, keep to plain prose."

**Remove / avoid**

- Anti-formatting rules written to tame older models' bullets and bold ("no lists", "never use bold") — 5.1 already leans the other way, so they push it into under-structured replies.
- Lines that hold narration back ("hold all findings for the final response", "no commentary between tool calls") — they compound the quieter default.
- Compile-check phrasing: "Does this program compile without errors?" trips the safety classifiers more often than "Are there any bugs in this program?". Two other false-positive sources: lesser-known languages (give the model the language's documentation or a description of how it works) and base64 in tool output (strip it before it reaches the model). Finding vulnerabilities in source code is permitted; offensive-cyber and bio asks still return `stop_reason: refusal`.
- Everything on the Fable 5 remove list still holds: reasoning-echo instructions, context-budget countdowns, enumerated behaviour lists where a sentence would do.

**Effort**: default `high`; re-run the sweep rather than inheriting Fable 5 levels, because level names don't map to the same amount of thinking across models. `medium` roughly matches Fable 5 at lower cost; `low` is often competitive with Opus 5 and Sonnet 5 on cost per task while scoring higher, so try it wherever a smaller model at higher effort was the plan. Two effort side effects have their own bullets above: less search at `low`, longer pre-writing at `xhigh` and `max`.

**Harness-level, not prompt text** (for app and system-prompt authors):

- Progress notes between tool calls arrive as `thinking` blocks and are empty under the default `display: "omitted"`; set `display: "updates"` (beta `thinking-display-updates-2026-08-18`) or `"summarized"` before adding prompt lines that ask for more updates. If the UI hides tool output, say so in a turn-scoped system message: "Only you see that command's output — the user's terminal shows at most a few lines of it. If the user needs to read any of it, put it in your reply."
- Keep the conversation history append-only: replay each assistant turn exactly as returned, thinking blocks included; send per-turn reminders as turn-scoped system messages and instruction or tool changes as mid-conversation system messages rather than editing earlier turns. Edits restart the prompt cache and, for accounts created on or after 2026-08-31, invalidate the thinking blocks that follow them.
- Client-side compaction: replace the whole history with one summary message plus the new user turn, and tell the summarizer what to keep: problems and how they were resolved, options tried or set aside and why, anything decided or constrained (stated exactly), where things stand, what is still open, and hard-to-reconstruct specifics such as names, numbers, dates, exact wording, and links. Keep the user's words close and condense the assistant's.
- Subagents: let the lead keep working — the spawn tool returns immediately, results arrive in a later user message, and a separate tool waits on demand. Time to completion drops at similar quality and cost.
- Vision: a crop-and-zoom tool, or a container with the images and PIL/OpenCV, delivers most of the uplift on dense charts and images.

**In Claude Code** (2.1, September 2026) the harness system prompt for Fable 5.1 already carries the progress-update line, both finish-the-whole-task blocks, and the per-turn batching and hidden-output reminders, so a user-turn prompt should not repeat them; check the session's system prompt when unsure. What still earns a place in a user-turn prompt: the scope-and-tests paragraph for feature work, the mannered-prose line for writing tasks, the quoting example for research, the compile-check rephrase, and the surgical-edit line for a small change to a large file. Effort stays a session setting (`/effort`); for a long written deliverable, ask for `high` in words.

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
