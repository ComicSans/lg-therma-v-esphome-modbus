# MISTAKES.md

Mistakes in this project that cost time. Every session reads this file before it
plans or changes anything, and writes its own mistakes here before it reports
done. The rules: `project_standards rule:"learning.mistakes-log"` and
`rule:"learning.mistakes-read"`.

The format, deliberately narrow:

- One `###` entry per mistake, newest on top.
- The heading is the trigger in one line — it is the only part that reaches the
  next session at startup.
- Three fields, none optional: **What happened**, **Trigger**, **Fix**.
- No entry without a trigger and a fix. Without the trigger the next session does
  not know what to watch for.
- An entry that turns out wrong or obsolete is corrected or deleted with one line
  saying why. A wrong entry costs more than a missing one.

<!-- Template, copy and fill in, then leave this comment in place:

### YYYY-MM-DD Short trigger in one line

- **What happened:** [what went wrong, one sentence]
- **Trigger:** [what caused it and how it could have been spotted first]
- **Fix:** [what resolved it, with the file or command]

-->

### YYYY-MM-DD No entries yet

- **What happened:** Placeholder, so the format is visible.
- **Trigger:** The project was just set up.
- **Fix:** Replace this entry with the first real mistake.
