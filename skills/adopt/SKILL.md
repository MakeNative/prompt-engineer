---
name: adopt
description: "Onboard this project to the prompt-engineer pipeline: look at the project, ask only what it does not tell, and write the project context every agent reads at .claude/docs/PROJECT_CONTEXT.md. Then check that the pipeline's texts fit the project. Re-run anytime to refresh it. Triggers on: /prompt-engineer:adopt"
disable-model-invocation: true
allowed-tools: AskUserQuestion, Agent, SendMessage, Read, Write, Edit, Glob, Grep, Bash(ls:*), Bash(mkdir:*), Bash(git remote:*), Bash(git log:*)
---

# Adopt

You write the project context the prompt-engineer agents run on: `.claude/docs/PROJECT_CONTEXT.md`. The agents are generic, and this file is what adapts them to this project. Every agent reads it before it starts, so a fact recorded here is a fact no agent has to guess or ask for again.

Work directly. You may start `Explore` agents to look through a large project, but you write the file yourself.

The format is `${CLAUDE_SKILL_DIR}/project-context.md`. The kit is the plugin folder two levels above this skill (`${CLAUDE_SKILL_DIR}/../..`).

## Step 0: fresh or refresh

- `.claude/docs/PROJECT_CONTEXT.md` is missing: **fresh**, all steps.
- It exists: **refresh**. Another pipeline may have written it, so it may follow a different format. Keep every section and every hand-written sentence. Re-check each fact against the project and correct only what is stale. Add a section of the format only when no existing section covers it. Ask only about what you cannot verify.

## Step 1: look before you ask

Read `CLAUDE.md`, the README, the top-level folders and any docs folder, and `git remote -v` if it is a repository. Read `<kit>/docs/PIPELINE-PLAN.md`: its purpose says what the pipeline produces, and its Access table names the files and folders the agents expect. From these, fill in what you can, for every section of the format.

## Step 2: ask what the project does not tell

Ask with AskUserQuestion, at most four questions per call, in the language the author writes to you in, and only about sections you could not fill in Step 1. Offer what you found as the recommended option, so the author confirms instead of typing. Always cover:

- **What is made here, and for whom**, if the README does not say it plainly.
- **Off limits**: what no agent may change, read or send anywhere. Never assume there is nothing.

Then the rest only where Step 1 left a gap: where inputs and results live, the conventions a newcomer would get wrong, the commands that check something, the sources the work is held to.

## Step 3: write it

`mkdir -p .claude/docs`, then write or update `.claude/docs/PROJECT_CONTEXT.md` in the format. Facts only, in short lines. Record commands exactly as they run, and only ones you have seen in the project: never invent one. Mark what you could not verify with `<!-- VERIFY: ... -->`.

## Step 4: check the fit

Start `prompt-auditor` with this task:

```
Kit: <kit>
Scope: fit
```

It reports every path, folder, file and command the agents name that this project does not have. For each finding:

- If the project has it under another name, record the real name in *Where things live*, so every agent finds it.
- If the agent text is wrong for every project, it is a change to the kit: list it in the report, and say that `/prompt-engineer:evaluate-runs` is where kit changes are ticked and built in.

## Step 5: report

In the author's language: what you wrote or changed, section by section; every `<!-- VERIFY -->` item; the fit findings and what you did with each. Say that the agents read the file from their next run on.

Never commit or push. The author reviews and commits.
