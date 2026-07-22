# Patch

Create a concise patch plan in `specs/` for a surgical, targeted fix.

## Purpose

Generate a minimal patch plan for small fixes that don't warrant a full bug or feature workflow. The plan becomes the prompt for `/implement`.

**You are the Planner. Write the plan only — do not implement.**

## Boundaries (CRITICAL)

| Allowed | Forbidden |
|---------|-----------|
| Read files (research) | Edit `src/`, `tests/`, or any application code |
| Write `specs/patch-<slug>.md` | Run validation commands |
| Summarize findings in the plan | Execute plan tasks or run `/implement` |

Implementation happens in a **separate fresh session** via `/implement specs/patch-<slug>.md`.

## Instructions

1. Understand the specific issue — read relevant files only, don't explore broadly (read-only)
2. Think hard about the smallest correct change
3. Create a new plan file at `specs/patch-<slug>.md` using the patch plan format
4. Keep the plan short — patch plans should be < 50 lines
5. Include validation commands for `/implement` — do not run them yourself
6. **Stop** after writing the plan file — report the path and hand off to `/implement`

## Plan Format

Write the plan file using this exact structure (fill every section):

```markdown
# Patch: <title>

## Issue Summary
<one paragraph — what is wrong>

## Solution
<minimal targeted change to fix it>

## Relevant Files
- `path/to/file` — what changes here

## Step-by-Step Tasks
Ordered tasks for `/implement` — do not execute during planning. Keep changes minimal and targeted.

1. <task>
2. <task>

## Validation Commands
- `<quick verification command>`
- `<test command for affected area>`

## Notes
<why patch vs full bug/feature workflow>
```

## Arguments

$ARGUMENTS — the patch description

## Patch

$ARGUMENTS

## Done

When `specs/patch-<slug>.md` is written, stop. Report:

```
Plan ready: specs/patch-<slug>.md
Next step (fresh agent): /implement specs/patch-<slug>.md
```

Do not edit application code in this session.
