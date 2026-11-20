# How to build agent pipelines

---

# Part 1 — The pieces

## Four filetypes make a pipeline

- **Plugin** — the folder you install.
- **Skill** — a workflow you type: `/my-pipeline:orchestrate`.
- **Agent** — a worker the skill calls. Fresh, empty context every time.
- **Hook** — a script that runs around tool calls.

```
my-pipeline/
├── .claude-plugin/plugin.json
├── skills/orchestrate/SKILL.md   ← you type this
├── agents/reviewer.md            ← it calls this
└── hooks/hooks.json              ← rules nobody can skip
```

## Skill vs agent — same format, different thing

| | **Skill** | **Agent** |
|---|---|---|
| Runs in | your session | its own empty context |
| Started by | you typing it | another component |
| Sees | the conversation | only what it is handed |
| Tools | `disallowed-tools` — denylist | `tools:` — whitelist |
| Can ask you | **yes** | **no** — platform strips it |
| Continuable | it is the session | `SendMessage` to its ID |
| Memory | none | `memory: project` |

## Frontmatter — the settings block

Every agent **and** every skill starts with one.

```yaml
---                              # agents/reviewer.md
name: reviewer
model: sonnet
tools: Read, Grep, Glob          # whitelist: has these, nothing else
---
```

```yaml
---                              # skills/orchestrate/SKILL.md
name: orchestrate
disallowed-tools: Edit, Write, Bash   # denylist: removes these, keeps the rest
---
```

**You control an agent or a skill by limiting the tools it has.**

## Hook — a script that runs on an event

| Event | Fires | Typical use |
|---|---|---|
| `PreToolUse` | before a tool call | **block** it, or change its input |
| `PostToolUse` | after a tool call | **act** on the result: format, merge, log |
| `UserPromptSubmit` / `SessionStart` | prompt sent / session opens | **add context** |
| `Stop` / `SubagentStop` | the session or an agent finishes | **record** or check the outcome |

```json
{ "hooks": { "PreToolUse": [
  { "matcher": "Edit|Write",
    "hooks": [{ "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/guard.sh\"" }] }
]}}
```

## Eval and grader — a test suite for behaviour

```
evals/phase-order/
├── prompt.md          ← "Add a clear-all button"
└── graders/order.md   ← one pass/fail check
```

```yaml
---
type: tool_order          # builder must run before reviewer
before: { tool: Agent, input_match: 'developer' }
after:  { tool: Agent, input_match: 'reviewer' }
---
```

Runs each case **with and without** your plugin. Same score both ways = it did nothing.

---

# Part 2 — The learnings

## Plan → build → review → repeat

```mermaid
flowchart LR
    P["PLAN"] --> B["BUILD"] --> R["REVIEW"]
    R --> B
```

- **PLAN** — decide the task. Every question answered. This is the contract.
- **BUILD** — build what the contract says. Nothing else.
- **REVIEW** — compare the build against the contract. Mismatch → build again.

## 1. The builder cannot review its own work

**What** — making and judging are different agents.

```
BUILD  →  REVIEW  →  fix  →  REVIEW
          fresh agent, empty context
```

**Why** — the builder already argued itself into every choice. A fresh reviewer never did.


## 2. Reviewers advise, builders change

**What** — reviewers report. They never edit.

```yaml
tools: Read, Grep, Glob
```
```json
{ "reviewer": { "deny": "all" } }
```

**Why** — a reviewer that fixes reviews its own work next round. The second pair of eyes is gone.

## 3. Every loop needs a number

**What** — the fix-review loop stops at a fixed count.

```markdown
Cap: 2 rounds. Then hand the findings to the author.
```

**Why** — "until clean" never arrives when a reviewer's job is finding things, and fixing creates new things.

## 4. Lock the orchestrator out of the filesystem

**What** — it uses three tools: `Agent`, `SendMessage`, `AskUserQuestion`. Its frontmatter removes every other tool that none of its agents needs.

```yaml
disallowed-tools: NotebookEdit, Bash, Skill, WebFetch, WebSearch
```

**Why** — an orchestrator that *can* do the work will. Then no agent is accountable.

**But** — a skill's `disallowed-tools` also reaches every agent it starts. Lock out `Read` and `Write`, and no agent can read or write either.

## 5. Resume by ID, never re-spawn

**What** — start a component once. Continue it forever.

```
round 1:  Agent(...)                    → agent_id
round 2:  SendMessage(to: agent_id)     ← not Agent() again
```

**Why** — a new call starts blank. The reviewer re-raises what it already accepted, and the loop never converges.

## 6. Agents cannot ask you

**What** — the agent hands the question up. The orchestrator asks it.

```
agent → returns "## Questions" → orchestrator → AskUserQuestion
you pick → orchestrator → SendMessage → agent resumes
```

**Why** — the platform removes `AskUserQuestion` from every agent. Without a protocol, agents guess.

## Use hooks to guard your agents

**What** — a `PreToolUse` hook sees every tool call before it runs, and can refuse it.

**How** — the hook reads the call from stdin. Exit 0 allows it. Exit 2 blocks it.

```bash
path=$(jq -r '.tool_input.file_path')   # where the agent wants to write
[[ "$path" == */reports/* ]] && exit 0  # inside reports/ → allow
exit 2                                  # anywhere else → block
```

**Why** — `tools:` can say *Write*, but not *Write only in reports/*.

## 7. Enforce with hooks, not prose

**What** — anything that must *never* happen is a hook.

```bash
grep -Eq 'git +(commit|push)' <<<"$cmd" && { echo "BLOCKED" >&2; exit 2; }
```

**Why** — an agent can be argued out of its own instructions. Not out of a hook.

*The kit we reviewed stated seven absolute rules and enforced none.*

## 8. Permissions need two layers

**What** — `tools:` decides *whether*. The hook decides *where*.

```yaml
tools: Read, Grep, Glob, Write     # 1: no Edit, no Bash
```
```bash
[[ "$path" == */test/* ]] && exit 2 # 2: and Write not there
```

**Why** — `tools:` cannot express paths. `Bash` writes anything through the shell.

## 9. Make it parallel-safe

**What** — shared files: the log and the plan. No agent writes them directly.

**How** — the agent hands its piece over. A hook merges it in under a lock.

```
agent → Write inbox/<file>/<agent>.md
hook  → lock → log: append · plan: replace own section → delete inbox
```

**Why** — two agents writing one file: the last write wins, and a report vanishes.

## 10. Ship templates, not descriptions of them

**What** — copy the file, then edit it. Never write it from memory.

```
cp templates/hooks.json  out/hooks/hooks.json
# then replace {{PLACEHOLDER}} — nothing else
```

**Why** — asked to *produce* a config, a model invents a plausible schema. It parses, it loads, it enforces nothing.

## 11. Measure with evals, not opinion

**What** — two different questions, two different tools.

```bash
claude plugin validate . --strict      # is it shaped right?
claude plugin eval . --threshold 0.8   # does it behave?
```

**Why** — validation never runs your pipeline. Without a baseline you cannot tell if a new instruction helped or crowded out an old one.

## 12. A missing capability produces a convincing lie

**What** — we asked a shell-less agent to timestamp a folder. It returned `12-00-00`.

```markdown
Do not invent a clock time. You have no shell.
```

**Why** — an error stops the run. A plausible value spreads silently.

## 13. Every example is a default someone inherits

**What** — all our examples were code, so a slide pipeline was offered a `test-writer`.

```markdown
The thing that fixes "done" is domain-specific:
tests for code, an outline for a deck, criteria for a review.
```

**Why** — a model shown one shape reproduces that shape.

---

# Part 3 — What the runs taught us

*From evaluated runs of the agent-pipeline kit, November 2026.*

## 14. Severity decides the next round

**What** — every TODO is `high`, `medium` or `low`. From round 2 on, only `high` and `medium` start a round.

```markdown
- [ ] claim-checker-3 (low): "lightning fast" is not in the note
```

**Why** — in one project 32 of 34 findings were `low`, and both second rounds found only `low` ones. In another, building took 50 minutes and the review rounds about three hours.

## 15. No verdict is not a pass

**What** — a reviewer's reply without `review: passed` or `review: fixes needed` is asked once, then counts as not passed.

**Why** — reviewers that ran out of turns returned nothing: 6 of 8 empty final replies in one eval. Silence reads like approval.

## 16. Look at what people will see

**What** — whoever makes a page, slide or image renders it and looks at it before handing over.

**Why** — in 0 of 4 runs did a builder look at its rendered result. A contrast defect came back as a new finding a round later.

## 17. Paths come from the project, not the agent

**What** — `adopt` writes the project context. `prompt-auditor` checks that every path an agent names exists.

**Why** — eleven agents and three skills read a file that no setup step ever wrote: 20 failed reads before anyone saw it.

## 18. Memory holds the durable, rules hold what held

**What** — wrong, outdated and duplicate entries go. What held across runs becomes a rule. What several agents need moves into the project context.

**Why** — one warning stood five times across the agents' memory, with three different fixes. Three agents still ran the command it warned against.

## 19. A guard blocks narrowly

**What** — a hook blocks exactly its condition and lets everything else through.

**Why** — a guard that threw on an unexpected payload blocked every write. The agents switched to the shell, where no guard looked, and no test noticed.

## 20. Explanations go in the log, not in the work

**What** — builders explain what they did in their log entry, not in the work.

**Why** — one run wrote 629 lines of comments into 16 files. The author read the diff and stopped the run.

---

*Verified against Claude Code 2.1.282.*
