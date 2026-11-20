---
max_turns: 40
allowed_tools: [Read, Glob, Grep, Agent, SendMessage, AskUserQuestion, Write, Edit, Bash]
append_system_prompt: "This is an automated eval run. No author is present, so never call AskUserQuestion. Wherever you would ask the author, choose the option marked recommended, or else the first option, and use it exactly as if the author had picked it."
---

/prompt-engineer:orchestrate Prüf und schärf diesen Prompt, er erfindet Deadlines: „Fasse die Meetingnotizen zusammen. Liste alle To-dos mit Verantwortlichem und Deadline auf. Wenn etwas unklar ist, frag nach.“
