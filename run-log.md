# The run log

Every run has one log: `.claude/runs/prompt-engineer/<date>-<slug>/log.md`. Every agent appends to it every time it ends a turn: when it finishes, when it stops, and again each time it is resumed. It is the one place where the whole run can be read in order, every exchange with the author included.

**It is append-only, and nobody writes it directly.** Agents run in parallel, and two agents rewriting the same file lose one of the two versions. So you hand your entry to the shared-write hook, and the hook appends it under a lock, one whole entry at a time.

---

## How to append

Use the `Write` tool to write your entry to:

```
.claude/runs/prompt-engineer/<date>-<slug>/inbox/log/<your agent name>.md
```

The hook appends it to the end of `log.md` straight away and deletes the inbox file. Your next entry is then a fresh `Write` to the same path.

- **Use `Write`, never `Edit`.** You are not changing a file, you are handing one over.
- **Never write `log.md` itself.** The access guard blocks it.
- If the hook rejects your entry, the message says why. Fix the entry and `Write` it again. It has not been appended.

## What you write

Frontmatter with your status, then your content. **You do not write the entry heading.** The hook adds it, with the entry number, your name, your status and a timestamp from a real clock. You have no clock, and a made-up time is worse than none.

```markdown
---
status: done
---

### Summary
Two or three lines: what you did and how it ended.

### Details
Everything you did, found and decided. This is your whole report.

### For the next agent
What whoever runs after you needs to know, in their terms.

### Open questions
Anything you could not decide, or "None."
```

Two more sections, when they apply:

- `### Questions and answers`: every question put to the author and their answer, **verbatim**. A PLAN agent adds it after being resumed with answers. Any agent adds it when the orchestrator passes it an exchange to log.
- `### TODOs`: REVIEW agents only. One line per thing the builder must fix, `- [ ] <agent>-<n> (high|medium|low): ...`, or `None.`. IDs count across the run and never change.
- `### Verdict`: REVIEW agents only. `review: passed` or `review: fixes needed`, the same line that ends the reply.
- `### Fixed`: BUILD agents in a fix round. One line per TODO ID fixed, with what changed.

`status` is exactly one of:

| Status | Means |
|---|---|
| `done` | you finished what you were asked to do this turn |
| `questions` | PLAN agents only: you stopped to ask the author. The questions go in your reply, and your findings so far go here |
| `blocked` | you cannot continue, and the entry says why |

Use `###` headings and deeper inside your entry, never `#` or `##`. Level 1 and 2 belong to the log itself.

## What the log looks like

```markdown
# Run log: 2026-09-30-first-draft

Append-only. Agents add entries through the shared-write hook; nobody edits them.

---

## 01 · plan-1 · questions
_2026-09-30T14:02:11Z · agent_id a8f3c21_

### Summary
...

---

## 02 · plan-1 · done
_2026-09-30T14:05:40Z · agent_id a8f3c21_

### Questions and answers
...
```

Entries are numbered in the order they landed, not the order the agents started. Two agents running in parallel show up as two whole entries, one after the other, never interleaved.
