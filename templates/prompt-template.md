# Prompt shapes by size

Pick the smallest shape that carries the necessary context. Fill only the parts that add information; delete the rest. Tag names are suggestions — keep them consistent within one prompt.

## Tiny (the diff fits in one sentence)

Two to five plain sentences. No tags, no headings, no "context" section.

```text
<what to change, with the file>. <one constraint or pattern to follow, if any>. <the check to run, if any>.
```

## Bounded change (one feature, one bug, one refactor in a known area)

Short paragraphs; tags only if the prompt mixes pasted material with instructions.

```text
<why / for whom, one sentence — only if not obvious>

<the task, with direct verbs and the real files/symbols>. Follow the pattern in <exemplar file>. Keep it to <in-scope files>; <out of scope, one clause>.

Verify with `<command>` and show the output. <anti-over-engineering sentence if the area invites tidying>.
```

## Multi-file / autonomous / system prompt

```text
<context>
Why this is being done and for whom. What already exists and what it's called. Anything loaded in CLAUDE.md the model should route through rather than re-derive.
</context>

<task>
The goal in one paragraph, then the concrete pieces if order or completeness matters (numbered only then).
</task>

<scope>
In scope: files/modules. Out of scope: what not to touch and why. Destructive or outward-facing actions that need confirmation first.
</scope>

<approach>
Patterns to follow (one exemplar each), libraries already in use, decisions already made. "Act when you have enough information; give a recommendation rather than a survey when choosing."
</approach>

<verification>
The checks and how to run them, the cadence for long runs, and "report progress only against tool results; say what is unverified."
</verification>

<output>
What the final message should lead with (the outcome), what it must include (evidence, file:line refs, open questions), and length expectations. For written deliverables, a length calibration.
</output>

<examples>  (only when format or style is the point — 3 to 5, diverse, in <example> tags)
</examples>
```

For a **system prompt** add a one-sentence role at the top, describe tool-use policy with reasons rather than caps-lock commands, and put model-specific tone/concision lines near the end.

For **long pasted material** (logs, diffs, documents) place it above everything in `<documents><document index="n"><source/><document_content/></document></documents>` and put the ask last.
