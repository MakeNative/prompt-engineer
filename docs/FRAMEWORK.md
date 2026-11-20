# Agent Pipeline Framework

What every pipeline created with this plugin has in common.

## Flow

- Every run goes through the phases PLAN -> BUILD <-> REVIEW.
- Within a phase, agents run sequentially or in parallel.
- A run starts with `/<pipeline>:orchestrate <task>`. The orchestrate skill calls the agents in the
  right order.
- First, the `run-setup` agent creates `.claude/runs/<pipeline>/<date>-<slug>/` with an empty
  `log.md` and `plan.md`.
- PLAN agents work out the plan with the user. Each writes its own section of `plan.md`.
- BUILD agents do the work and never talk to the user.
- REVIEW agents append their TODOs to `log.md` and end their reply with whether the review passed or
  fixes are needed. Each TODO has an ID and a severity: high, medium or low.
- If fixes are needed, orchestrate starts another BUILD -> REVIEW round. From round 2 on, only high
  and medium TODOs need fixes; low ones go to the author in the final report.
- A review without a verdict has not passed.
- A phase ends when all its agents have finished. The run ends when the reviews pass or the maximum
  number of rounds is reached.

## Logging

- `log.md` is mainly for agents. It gives traceability and shared context.
- Every exchange with the user is stored there verbatim.

## Plan

- `plan.md` is the contract for everything that gets built. It must be readable by humans.
- Only PLAN agents may change it.
- No agent assumes anything. PLAN agents agree everything in the plan with the user. For BUILD and
  REVIEW agents, the plan is the only source of truth.

## Orchestration

- The orchestrate skill uses only `Agent`, `SendMessage` and `AskUserQuestion`. It never reads or
  writes files. Its `disallowed-tools` removes only tools none of its agents needs, because the
  lock reaches every agent it starts.
- It is the only connection to the user. PLAN agents pass their questions to it; it asks the user and
  hands back the answers.
- It starts the first task of every agent after `run-setup` with `Run folder: <path>`.

## PLAN, BUILD and REVIEW agents

These rules do not apply to the framework's own agents.

- Every agent reads the run's `log.md` and `plan.md` before starting, and appends to `log.md`.
- Agents never write `plan.md` or `log.md` directly. A hook writes them under a lock, so agents can
  run in parallel.

## Pipeline evaluation

- `/<pipeline>:evaluate-pipeline` checks the quality of a pipeline.
- It prints a table of findings, sorted by priority. Each finding has a title, a short description,
  a priority and a fix. Only problems with a known fix are reported.
- High: the pipeline differs from `docs/FRAMEWORK.md` (this document).
- High: the pipeline differs from `docs/PIPELINE-PLAN.md`, the plan it was generated from.
- High: a permission is so strict that an agent cannot do its job.
- Medium: the pipeline differs from `docs/PIPELINE-DESIGN.md`.
- Medium: a permission could be stricter.

## Run evaluation

- `/<pipeline>:evaluate-runs` checks how the pipeline ran, across finished runs. Its evaluation
  agents only read and reply: no `Write`, no memory, never part of a run.
- Each proposal changes one thing and names the number that must change.
- Only what the author ticks is built in. Each change is logged with its expectation in
  `.claude/evals/<pipeline>/EVAL-CHANGELOG.md`, and the next evaluation checks it first.
- An evaluation never changes a file copied verbatim from pipeline-builder.

## Project context and memory

- `/<pipeline>:adopt` writes `.claude/docs/PROJECT_CONTEXT.md`. Every PLAN, BUILD and REVIEW agent
  reads it before starting. It holds facts about the project, never about one pipeline.
- Each agent writes what it learned about the project into its own memory. An evaluation moves what
  several agents need into the project context, so it is said once.
- An evaluation removes memory entries that are wrong, outdated or duplicate, and turns entries that
  held across runs into rules in the agent's file.

TODO what does each agent read? This file, the log, the plan
TODO summary agent with timings
TODO logging and plan format
TODO parallel writing to files
TODO hooks
