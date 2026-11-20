---
name: show-pipeline
description: "Show the prompt-engineer pipeline: a table of every agent with its allowed tools and hooks, a graph of the flow, and a table of every file the pipeline uses. Triggers on: /prompt-engineer:show-pipeline"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
disallowed-tools: Edit, Write, NotebookEdit, Bash, Agent
---

You print a picture of the prompt-engineer pipeline. You read this plugin's files and output **exactly three things: the agents table, the graph, then the files table. Nothing else** — no heading, no intro, no summary, no notes, no closing line, no offer of further help.

The plugin root is two directories above this file: `${CLAUDE_SKILL_DIR}/../..`. Read only from there, and from the project root for the one policy override below. Never run anything, never write anything.

Take every value from the files. Never fill a gap from what a pipeline usually looks like — if something is missing, the cell says `—`.

---

## Read

1. **Agents** — every `agents/*.md`. From the frontmatter take `name` and `tools`, exactly as written. If an agent's frontmatter has a `hooks:` key, take those too. From the body take the phase (the `**PLAN**` / `**BUILD**` / `**REVIEW**` / `**FRAMEWORK**` / `**EVALUATE**` line).
2. **Hooks** — `hooks/hooks.json`. For each event (`PreToolUse`, `PostToolUse`, …) note each entry's `matcher` and the script its `command` runs (the file name only, e.g. `access-guard.sh`).
3. **Policy** — `pipeline-policy.json` from the project root if it exists, otherwise from the plugin root. It is the one the access guard actually uses. Take each agent's `phase` and `deny` value.
4. **Flow** — the workflow skill, `skills/orchestrate/SKILL.md`. Take `run-setup` first, its phases in order, the agents each phase calls in the order it calls them, which calls run in parallel, the review loop with its round cap, and `run-summary` last.
5. **Files** — every file or directory that the agents' bodies, the skills, the hook scripts in `hooks/` and the plugin's root `.md` files name as something read or written while the pipeline runs. That covers the run directory (`00-task.md`, `plan.md`, `log.md`, `inbox/log/`, `inbox/plan/`, `timings.jsonl`), agent memory, the project context, `pipeline-policy.json` and the contract paths in it, and plugin docs agents are told to read (`plan-contract.md`, `run-log.md`, `question-protocol.md`). For each one, note which agents read or write it, going by each agent's own body. Leave out the plugin's own agent, skill and hook files. The first table already shows them.

## Which hooks an agent gets

A hook entry applies to an agent when:

- its event is `SubagentStart` or `SubagentStop` — these fire for every agent, or
- its `matcher` is `*` or missing, or
- its `matcher` (a regex, `|` = or) matches **at least one tool in that agent's `tools:`**. An agent without `Bash` never triggers a `Bash`-matched hook.

Group by script. List the events it fires on, and for a `PreToolUse` script the tools of **this agent** that trigger it. For `access-guard.sh` add the agent's `deny` rule. Add any frontmatter `hooks:` the same way.

---

## Output

### 1. The table

```
| Agent | Phase | Allowed tools | Hooks |
|-------|-------|---------------|-------|
| run-setup | FRAMEWORK | Read, Glob, Write | access-guard.sh — PreToolUse on Write · deny: all<br>shared-write.sh — PostToolUse on Write<br>timing.sh — PostToolUse, PostToolUseFailure, SubagentStart, SubagentStop |
| plan-1 | PLAN | Read, Grep, Glob, Write | access-guard.sh — PreToolUse on Write · deny: all<br>shared-write.sh — PostToolUse on Write<br>timing.sh — PostToolUse, PostToolUseFailure, SubagentStart, SubagentStop |
| build-1 | BUILD | Read, Grep, Glob, Edit, Write, Bash | access-guard.sh — PreToolUse on Edit, Write, Bash · deny: contract<br>shared-write.sh — PostToolUse on Write<br>timing.sh — PostToolUse, PostToolUseFailure, SubagentStart, SubagentStop |
```

One row per agent, in flow order. The evaluation agents (`EVALUATE`) come after `run-summary`: `evaluate-runs` and `adopt` start them, never the workflow. Any other agent the workflow never calls goes last, with phase `—`.

### 2. The graph

A plain-text graph in a ```` ``` ```` block — the terminal shows Mermaid as raw code, so do not use it.

- `run-setup` on top and `run-summary` at the bottom, as plain lines outside the boxes.
- Phases top to bottom, each a labelled box holding its agents.
- Agents in one phase called one after another are joined with `──▶`; agents called in parallel sit side by side, joined with `│`.
- The review loop is an arrow from the reviewers back to the building agent, labelled with its cap.
- Label nothing else. Agent names only — no tools, no files, no descriptions.

```
           run-setup
                ▼
┌─ PLAN ─────────────────────────┐
│  plan-1  │  plan-2             │
└───────────────┬────────────────┘
                ▼
┌─ BUILD ────────────────────────┐
│  build-1                       │◀──┐
└───────────────┬────────────────┘   │
                ▼                    │ fix, max 2 rounds
┌─ REVIEW ───────────────────────┐   │
│  review-1  │  review-2         │───┘
└───────────────┬────────────────┘
                ▼
           run-summary
```

### 3. The files table

```
| File | What it is | Used by |
|------|------------|---------|
| `<run>/00-task.md` | The task, verbatim, as the author gave it | run-setup (writes) · all agents |
| `<run>/plan.md` | The contract: one section per PLAN agent | run-setup (creates) · all agents · shared-write.sh |
| `<run>/log.md` | Append-only run log: every agent's report, in order | run-setup (creates) · all agents · shared-write.sh |
| `<run>/inbox/log/<agent>.md` | An agent's log entry, until the hook appends it | all agents, each its own · shared-write.sh |
| `<run>/inbox/plan/<agent>.md` | A PLAN agent's plan section, until the hook merges it | plan-1, plan-2 · shared-write.sh |
| `<run>/timings.jsonl` | Per-event timing, one JSON line each | timing.sh · run-summary · run-evaluator |
| `.claude/agent-memory/prompt-engineer-<agent>/` | What the agent learned across runs | all agents, each its own |
| `.claude/evals/prompt-engineer/<date>/` | One evaluation: stats, fact sheets, audit, proposals | evaluate-runs (writes) · pipeline-evaluator |
| `.claude/evals/prompt-engineer/EVAL-CHANGELOG.md` | Every built-in change with its expected number | evaluate-runs (writes) · pipeline-evaluator · prompt-auditor |
| `.claude/docs/PROJECT_CONTEXT.md` | How the project is organised and its conventions | adopt (writes) · all agents |
| `pipeline-policy.json` | Each agent's write rule and the contract paths | access-guard.sh |
| `plan-contract.md` | How plan.md is written and followed | all agents |
| `run-log.md` | How to write a log entry | all agents |
| `question-protocol.md` | How an agent asks the author a question | all agents |
```

- `<run>` stands for `.claude/runs/prompt-engineer/<date>-<slug>`. Write it that way, not as a real run.
- One row per file or directory, in this order: run directory in the order a run creates them, then memory, then the evaluation files, then project and plugin files.
- **What it is** is at most 10 words.
- **Used by** names every agent that reads or writes it, in flow order. Write `all agents` when that is literally true, and add `each its own` when each agent has its own copy. Add a hook script only when it writes the file, as with `shared-write.sh`, or when nothing but a hook uses it.

The examples above show the shape only. Every name, tool, rule, file and number comes from this plugin's files.
