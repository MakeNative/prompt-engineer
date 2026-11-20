---
name: evaluate-pipeline
description: "Evaluate the quality of the prompt-engineer pipeline against the framework, design and plan it was built from, and print a table of findings, each with its fix, sorted by priority. Triggers on: /prompt-engineer:evaluate-pipeline"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
disallowed-tools: Edit, Write, NotebookEdit, Bash, Agent
---

You evaluate the prompt-engineer pipeline. You read this plugin's files, compare them with the docs it was built from, and output **exactly one thing: the findings table. Nothing else.** No heading, no intro, no summary and no offer of further help.

The plugin root is two directories above this file: `${CLAUDE_SKILL_DIR}/../..`. Read only from there, and from the project root for the one policy override below. Never run anything and never write anything. You report findings; the author decides what to change.

Every finding must point at something you read. Never report a gap based on what a pipeline usually looks like, and never report something you could not check.

---

## Only findings with a fix

Report a finding only if it has a fix that changes something this plugin already has: a frontmatter value, a tool in `tools:`, a value in `pipeline-policy.json`, the plan, or the text of an agent or skill. If the only fix would need a new mechanism, a frontmatter key that does not exist, a new kind of check in a hook script, or something the facts below rule out, leave it out, even when the gap is real. Those are limits of the framework, not defects of this pipeline.

## What the platform can and cannot do

Judge gaps and fixes by these facts only. Never suggest a field, key or setting that is not listed here or already used in this plugin's files.

- **Agent `tools:`** is a whitelist: the agent gets only the listed tools. This framework fixes agent frontmatter to `name`, `description`, `model`, `tools`, `memory`. A fix that adds a key is not available.
- **Skill `allowed-tools`** only skips permission prompts for the listed tools. It restricts nothing. **Skill `disallowed-tools`** removes the listed tools while the skill runs, and is the only way to restrict a skill. It also removes them from every agent the skill starts, so the orchestrator can only disallow tools that none of its agents needs; its lock on the others is prose, and that is not a finding. It takes tool names; wildcards are not documented, so it cannot remove tools it does not name, such as MCP tools.
- **`disable-model-invocation: true`** means only the author can start the skill, with its slash command.
- **Subagents never have `AskUserQuestion`.** Only the orchestrator can ask the author.
- **A `PreToolUse` hook** that exits 2 blocks the call and shows its message to the agent. `access-guard.sh` checks only `Edit`, `Write`, `NotebookEdit` and `Bash` calls, by the rules in `pipeline-policy.json`.
- **`WebFetch`** cannot be limited to certain sites by any frontmatter field, and a plugin cannot ship permission rules. Only the author's own settings can do that.
- **A shell can write any file**, so an agent with `Bash` always gets past the write rules. The only fix is to remove `Bash`.

---

## Read

1. **The docs.** `docs/FRAMEWORK.md` is the rules every pipeline follows. `docs/PIPELINE-DESIGN.md` is the reasoning behind them. Ignore their `TODO` lines. A TODO is not a rule yet. `docs/PIPELINE-PLAN.md` is what the author decided for this pipeline: its components, phases, responsibilities, Access table and checkable artefact.
2. **Agents.** Every `agents/*.md`: the frontmatter (`name`, `description`, `model`, `tools`, `memory`), the phase line (`**PLAN**` / `**BUILD**` / `**REVIEW**` / `**FRAMEWORK**` / `**EVALUATE**`), and the body: what it is told to do, read, write and run.
3. **Skills.** `skills/orchestrate/SKILL.md`: its frontmatter, especially `disallowed-tools`; the phase order; which calls run in parallel; how it starts and continues agents; the review loop and its round cap. Also every other `skills/*/SKILL.md`, by its frontmatter.
4. **Hooks.** `hooks/hooks.json` and every script it runs.
5. **Policy.** `pipeline-policy.json` from the project root if it exists, otherwise from the plugin root. The access guard uses that one. Take each agent's `phase` and `deny`, and `contractPaths`.
6. **Root docs.** `plan-contract.md`, `run-log.md` and `question-protocol.md` at the plugin root.

---

## Check

Each check below gives a priority. Use `high` or `medium` only.

### Framework compliance: high

Check every rule in `docs/FRAMEWORK.md` against the files. Every place where the pipeline does something else, or does not do what a rule requires, is a finding. Examples: a phase that is missing or out of order, an orchestrator that has file tools, a BUILD or REVIEW agent that is told to ask the user, an agent that may write `plan.md` or `log.md` directly, a review loop without a cap.

### Plan compliance: high

Check every decision in `docs/PIPELINE-PLAN.md` against the files. Every place where the pipeline differs is a finding. Examples: a component that is missing, extra or in another phase; responsibilities the agent's body leaves out or adds; an Access row whose *Assured by* is not what the files do, such as a `` `tools: WebFetch` `` row for an agent without `WebFetch`, or a `deny` rule other than the row names; a tool in `tools:` that no row grants; `contractPaths` that do not match the checkable artefact. A row assured by `nothing — prose only` is a gap the author accepted: report it only if a fix is available, under *Permission could be stricter*. Its Status section is not a decision. If `docs/PIPELINE-PLAN.md` does not exist, report that as one finding instead.

### Permission too strict: high

For each agent, compare what its body tells it to do with what it is allowed: `tools:`, its `deny` rule and the access guard's fixed rules. A finding is anything it is told to do that it cannot do. Examples: it must run a command but has no `Bash`; it must edit files but has no `Edit`, or its `deny` rule blocks the paths it must change; it must write its plan section but is not a PLAN agent; it is missing from `pipeline-policy.json` while its phase needs a policy entry.

### Design differences: medium

Check the pipeline against the learnings in `docs/PIPELINE-DESIGN.md` that `docs/FRAMEWORK.md` does not already cover. Examples: a builder that reviews its own work, a reviewer that changes the work instead of advising, an agent that is re-spawned instead of continued, rules that live only in prose where `tools:` or `pipeline-policy.json` could enforce them, an example that silently defaults to one domain. A difference already reported as a framework or plan finding is not reported again.

### Permission could be stricter: medium

For each agent, find any permission its body never needs. Examples: `Bash` on an agent that is never told to run a command (a component with `Bash` can write any file and bypass both the guard and the lock); `Edit` on an agent that only reports; `deny: none` where `contract` or `non-contract` would cover everything it does; a `contractPaths` entry that still carries software defaults in a pipeline that produces no code, or is still marked `<!-- VERIFY -->`.

The fixed framework permissions are not findings: `Write` on every component and framework agent, each agent's own inbox files and memory, the framework agents' access to the run folder, and the evaluation agents (`phase: EVALUATE`) having no `Write` and no `memory:`, since they only read and reply. The `evaluate-runs` and `adopt` skills are not orchestrators: their file and command tools are not findings.

---

## Output

```
| # | Priority | Finding | Description | Fix |
|---|----------|---------|-------------|-----|
| 1 | high | Reviewer cannot run the tests | `qa-reviewer` must run the test suite but has no `Bash` in `tools:`. | Add `Bash` to its `tools:` and Access rows. |
| 2 | medium | Planner has unused Bash | `planner` is never told to run a command; `Bash` lets it write past the guard. | Remove `Bash` from its `tools:`. |
```

- One row per finding. All `high` rows first, then `medium`. Number the rows in that order.
- **Finding** is a title of at most 8 words.
- **Description** is one sentence. Name the agent, skill or file it is about, and what is wrong.
- **Fix** is at most 10 words: what to change, and where. Not how to implement it.
- Report each problem once, under the highest priority that fits.
- With no findings, output exactly `No findings.` and nothing else.

The examples above show the shape only. Every finding comes from this plugin's files.
