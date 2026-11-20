# The plan

Every run has one plan: `.claude/runs/prompt-engineer/<date>-<slug>/plan.md`. The PLAN agents write it together, one section each. **It is the contract for every BUILD and REVIEW agent.** They build what it says, and reviewers check against it.

It must be readable for humans: the author reads it to see what will be built.

## If you are a PLAN agent

You own one section, `## <your agent name>`. Nobody writes `plan.md` directly. Other PLAN agents may be writing their sections at the same moment, so you hand yours to the shared-write hook:

```
.claude/runs/prompt-engineer/<date>-<slug>/inbox/plan/<your agent name>.md
```

- `Write` your **whole section** there, every time, without the `## <your agent name>` heading. The hook adds it.
- The hook **replaces** your section in `plan.md`, or adds it on your first write. Other sections are never touched. Rewrite your section as often as you need.
- Use `###` headings and deeper. `#` and `##` belong to the plan itself.
- If the hook rejects your section, the message says why. Fix it and `Write` it again.

What goes in it:

- Read the other sections first. Do not repeat or contradict them. If you disagree with one, say so under *Open questions*.
- **Never assume.** Every decision in your section is asked and agreed with the author.
- Write decisions, not discussion. Anything a builder could read two ways is not finished.
- Use these headings where they fit your role, with their names unchanged: the other agents look for them.

```markdown
### Goal
<what this run delivers>

### Scope
- In: <what gets built>
- Out: <what explicitly does not>

### Decisions
- <each decision a builder needs, with its reason when it is not obvious>

### Done when
- [ ] <checkable criteria. Reviewers verify each one>

### Open questions
<anything unresolved, or "None.">
```

## If you are a BUILD or REVIEW agent

- Read the whole of `plan.md` before anything else. It is your contract.
- **Build only what it says.** Nothing it leaves out, however useful.
- **Review against every *Done when*** in every section. Say which criteria are met and which are not.
- **Never edit it.** The access guard blocks you. If the plan is wrong or incomplete, append a run log entry with `status: blocked` that says why, say the same in your reply, and stop. The orchestrator takes it to the author.
