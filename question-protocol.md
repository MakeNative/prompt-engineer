# Asking the author a question

Agents cannot talk to the author. `AskUserQuestion` is removed from every subagent by the platform, even when the agent's `tools:` lists it. A PLAN agent that needs a decision therefore **hands the question upward** and the orchestrator asks it.

**Only PLAN agents ask.** BUILD and REVIEW agents never do: when the plan does not settle something, they log `status: blocked` and stop.

This is the one way it is done in this pipeline. Follow it exactly — the orchestrator parses what you write.

---

## If you are a PLAN agent

When you hit something only the author can decide, **stop and ask. Do not guess, and do not pick a default and note it.** A wrong assumption discovered three phases later costs more than a question.

End your turn with a `## Questions` section containing one fenced `json` block. **Put it in your reply, not in a file.**

Your reply is the only thing the orchestrator sees — it has no `Read` tool. A question written to a file and not to your reply is a question nobody will ever be asked.

````markdown
## Questions

```json
[
  {
    "question": "The task could be aimed at two audiences. Who is it for?",
    "header": "Audience",
    "multiSelect": false,
    "options": [
      { "label": "Existing users", "description": "They know the background, so the result can skip it and stay short.", "recommended": true },
      { "label": "Newcomers", "description": "Needs an introduction first, which makes it longer." },
      { "label": "Both", "description": "One version for everyone. Longer and less focused." }
    ]
  }
]
```
````

**The shape is fixed by the tool that renders it:**

| Field | Rule |
|---|---|
| the array | **at most 4 questions.** More than that, ask the 4 that unblock you and leave the rest |
| `question` | the full question, ending in a question mark. Give the context needed to answer it |
| `header` | **12 characters maximum** — a chip label, e.g. `Audience`, `Scope`, `Format` |
| `multiSelect` | `true` when several answers can apply together, `false` when they are alternatives |
| `options` | **2 to 4.** Never add an "Other" option — the author always gets one automatically |
| `label` | 1–5 words, the choice itself |
| `description` | what it means and what it costs. This is where the author actually decides |
| `recommended` | optional, on at most one option. Say in its `description` why |

**Then stop.** Do not continue past a question on an assumption. You will be resumed with the answers and your full context intact, so there is no need to restate what you already know or to write a summary for your future self.

Everything you worked out before the question still goes in the run log, as an entry with `status: questions` (see `run-log.md`). A question is not a reason to hand back nothing.

When you are resumed, your next log entry quotes every question and answer **verbatim** under `### Questions and answers`. Every exchange with the author ends up in the log.

---

## If you are the orchestrator

When a PLAN agent's reply ends with a `## Questions` block:

1. **Render it.** Pass the questions to `AskUserQuestion` — up to 4 in one call. Put a `recommended` option first and append `(Recommended)` to its label. Never re-word what the agent asked, and never add options it did not offer.
2. **Never answer on the agent's behalf.** Not from the plan, not from context, not because the answer seems obvious. The agent stopped because it judged that this is the author's call.
3. **Resume, do not re-spawn.** Send the answers back with `SendMessage` to that agent's ID. A new `Agent` call would start a fresh context and lose everything it had worked out.
4. **Answers go back verbatim**, including anything the author typed into "Other".

If the author's answer raises a further question, the agent will ask again. That is fine — loop until it stops asking.

**Questions you ask yourself** (a blocked plan, a reached round cap) are logged too. Pass the question and the answer verbatim to the next agent you call and tell it to log them, or to `run-summary` if no agent follows.
