---
name: evaluate-runs
description: "Evaluate the prompt-engineer pipeline across its finished runs: numbers per run from the transcripts, a fact sheet per run, an audit of the texts and the agent memory, at most eight proposals each with an expected number. You tick what gets built in. Triggers on: /prompt-engineer:evaluate-runs [period | run folder]"
disable-model-invocation: true
allowed-tools: AskUserQuestion, Agent, SendMessage, Read, Edit, Write, Glob, Grep, Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(cat:*), Bash(bash:*), Bash(git -C:*), Bash(git worktree list:*), Bash(claude -p:*)
---

# Evaluate runs

You evaluate the prompt-engineer pipeline, not what it produced. The numbers come from a script, the judgement from three evaluation agents. You relay between them and the author, and you build in only what the author ticks.

`/prompt-engineer:evaluate-pipeline` checks how the pipeline is built. This skill checks how it ran.

## Agents

`run-evaluator`, `prompt-auditor` and `pipeline-evaluator`, listed as `prompt-engineer:<name>`. They read and reply; none of them writes a file. You file their replies.

## Kit

The kit is the plugin folder two levels above this skill's base directory (`${CLAUDE_SKILL_DIR}/../..`). Proposals for the kit are written there. If that folder lies under `~/.claude/plugins/`, it is an installed copy that every update overwrites: write nothing there, and list the kit changes in the report as text for the kit's source folder instead.

## Eval folder

`.claude/evals/prompt-engineer/<YYYY-MM-DD_HH-MM>/` in the project:

- `log.md`: one line per step, `<YYYY-MM-DD HH:MM> | <agent or step> | <entry>`
- `runs.md`: the runs of this evaluation
- `stats/<run>.tsv`: the script's numbers per run
- `kit-history.txt`: the kit's git history of `agents/` and `skills/`, if the kit is a git repository
- `facts/<run>.md`: the run-evaluator's fact sheet per run
- `audit.md`: the prompt-auditor's report on the texts and the memory
- `proposals.md`: the pipeline-evaluator's report

Next to the eval folders, `.claude/evals/prompt-engineer/EVAL-CHANGELOG.md` outlasts every evaluation. One row per change that was built in:

```markdown
| Date (UTC) | ID | Target | File | Change | Expectation | Status |
| --- | --- | --- | --- | --- | --- | --- |
```

`Status` is `open` until an evaluation judges it, then `met <date>` or `missed <date>`, or `reverted <date>` when the author took the change out again. Dates are UTC, like the run log's timestamps, so the two can be compared.

## Steps

1. **Runs.** A run is a folder with a `log.md` under `.claude/runs/prompt-engineer/` of the project, or of any worktree `git worktree list` names. With an argument, take the run folder it names, or the runs of the period it names: the folder names start with their date. Without one, take the runs since the newest eval folder, and all runs on the first evaluation. Show the list, one run per line with the time of its first log entry, and ask with AskUserQuestion: evaluate these (recommended), only the newest five, or name the runs. Then create the eval folder (`date +%Y-%m-%d_%H-%M`), write `runs.md` and the first line of `log.md`.
2. **Stats.** For every run: `bash "${CLAUDE_SKILL_DIR}/run-stats.sh" <run folder> > <eval folder>/stats/<run>.tsv`. A run whose transcripts are gone is still evaluated; its stats say so. If the kit is a git repository: `git -C <kit> log --oneline -- agents skills > <eval folder>/kit-history.txt`.
3. **Fact sheets.** Start one `run-evaluator` per run, in parallel, at most six at a time, each with this task:

   ```
   Run to evaluate: <run folder>
   Stats: <eval folder>/stats/<run>.tsv
   Kit: <kit>
   ```

   File each reply as `facts/<run>.md`: everything above the line `DONE`, unchanged, and append a line to `log.md`. If a reply is cut off or has no `DONE`, ask that run-evaluator once with SendMessage for the finished fact sheet. If none comes, file what came and add the section `## Data gaps` with "the run-evaluator did not finish".

   Alongside them, start `prompt-auditor` with this task:

   ```
   Kit: <kit>
   Scope: full
   Eval folder: <eval folder>
   ```

   File everything above its line `FINDINGS:` as `audit.md`, with the same rule for a cut-off reply.
4. **Where the author stepped in.** While the agents work, ask with AskUserQuestion, multiSelect, where the author stepped in during these runs, since no log records it: "Nowhere", "Checked the result myself after the reviews", "Took decisions that reopened work", "Fixed something by hand". Take the free answer as it is.
5. **Proposals.** When every fact sheet and `audit.md` are filed, start `pipeline-evaluator` with this task:

   ```
   Eval folder: <eval folder>
   Kit: <kit>
   Stepped in: <the author's answer>
   ```

   File everything above the line `PROPOSALS:` as `proposals.md`, with the same rule for a cut-off reply as in step 3.
6. **Choose.** Show `proposals.md` in the author's language: the open expectations, the patterns, then each proposal with its target, observation, wording and expectation. Then `audit.md`: each finding with its target, what it proposes and what goes away for it. Ask with AskUserQuestion, multiSelect, which proposals to build in, at most four options per question, so ask in groups of four. Then the same for the audit findings and for the memory entries. Items with the target `pipeline-builder` are not offered: they go into the report as text. If nothing is ticked, go to step 8.
7. **Build in.** For every ticked ID:
   1. Say which folder you write to: the kit (`<kit>`) or the project.
   2. Apply the wording exactly as written, with Edit. An audit finding also removes what it lists under "Goes away". A memory entry is removed, or moved as it says: into the agent file as a rule, or into `.claude/docs/PROJECT_CONTEXT.md`.
   3. If the proposal names a plan line, change that line of `<kit>/docs/PIPELINE-PLAN.md` the same way, so the plan and the pipeline still agree.
   4. Append a row to `.claude/evals/prompt-engineer/EVAL-CHANGELOG.md`, creating it with the header above if it is missing: date and time in UTC (`date -u +'%Y-%m-%d %H:%M'`), since runs that were already going then don't count for it; `<eval folder name>/<ID>`; `kit` or `project`; the file; the change in one line; the expectation; `open`.
   5. Append `built in <ID>: <file>` to `log.md`.

   Then set the status of every changelog row the pipeline-evaluator judged under "Open expectations": `met <date>` or `missed <date>`. Rows with too few runs stay `open`.

   If anything was built into the kit, raise the patch version in `<kit>/.claude-plugin/plugin.json`, so `0.2.0` becomes `0.2.1`: an installed copy only updates when the version changes. Then check that the kit still holds together: run `cd <kit> && claude -p "/prompt-engineer:evaluate-pipeline" --plugin-dir . --allowedTools "Read,Glob,Grep"` and append its result to `log.md`.
8. **Report.** In the author's language: the eval folder, how many runs, what was built in and where (kit or project, uncommitted), the result of `evaluate-pipeline`, the items for pipeline-builder as text, the open expectations and the data gaps. Say that a change shows its effect only in the next runs, and that the next `/prompt-engineer:evaluate-runs` checks the expectations first.

## What you never do

- Judge a run yourself. The numbers come from the stats, the judgement from the evaluation agents.
- Change a file whose ID nobody ticked, or change a ticked one beyond its wording.
- Change a file the generator copied verbatim: those changes belong to pipeline-builder.
- Commit or push. The author reviews and commits.
