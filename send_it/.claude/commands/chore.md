# Chore

Create a plan in `specs/` to resolve a maintenance chore using the chore plan format.

## Purpose

Generate a detailed, executable plan from a high-level chore description. The plan becomes the prompt for `/implement`.

**You are the Planner. Write the plan only — do not implement.**

## Boundaries (CRITICAL)

| Allowed | Forbidden |
|---------|-----------|
| Read files (research) | Edit `src/`, `tests/`, or any application code |
| Write `specs/chore-<slug>.md` | Run `pytest`, `ruff`, or any validation command |
| Summarize findings in the plan | Execute plan tasks or run `/implement` |

Implementation happens in a **separate fresh session** via `/implement specs/chore-<slug>.md`.

## Instructions

1. Read `conditional-docs.md` — include relevant documentation files in the plan if conditions match
2. Research the codebase: read relevant files, understand current state (read-only)
3. Think hard about the minimal correct approach
4. Create a new plan file at `specs/chore-<slug>.md` using the plan format below
5. Focus on the right files — use `git ls-files` and targeted search, not blind exploration
6. Include validation commands that `/implement` will run later — do not run them yourself
7. **Stop** after writing the plan file — report the path and hand off to `/implement`

## Plan Format

Write the plan file using this exact structure (fill every section):

```markdown
# Chore: <title>

## Description
<what needs to be done and why>

## Relevant Files
- `path/to/file` — reason

## New Files
<!-- List only if creating new files -->
- `path/to/new/file` — purpose

## Step-by-Step Tasks
Ordered tasks for `/implement` — do not execute during planning.

1. <task>
2. <task>
3. ...

## Validation Commands
Run all commands after implementation. All must pass.

- `<lint command>`
- `<test command>`
- `<compile/build command if applicable>`

## Notes
<edge cases, constraints, follow-ups>
```

## Arguments

$ARGUMENTS — the chore description (high-level prompt from the engineer)

## Chore

$ARGUMENTS

## Done

When `specs/chore-<slug>.md` is written, stop. Report:

```
Plan ready: specs/chore-<slug>.md
Next step (fresh agent): /implement specs/chore-<slug>.md
```

Do not edit application code in this session.
