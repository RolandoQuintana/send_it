# Bug

Create a plan in `specs/` to fix a bug using the bug plan format.

## Purpose

Generate a detailed bug-fix plan from a high-level problem description. The plan becomes the prompt for `/implement`.

**You are the Planner. Write the plan only — do not implement.**

## Boundaries (CRITICAL)

| Allowed | Forbidden |
|---------|-----------|
| Read files (research) | Edit `src/`, `tests/`, or any application code |
| Write `specs/bug-<slug>.md` | Run validation commands or reproduce the bug |
| Summarize findings in the plan | Execute plan tasks or run `/implement` |

Implementation happens in a **separate fresh session** via `/implement specs/bug-<slug>.md`.

## Instructions

1. Read `conditional-docs.md` — include relevant documentation if conditions match
2. Research the codebase to locate the bug: trace data flow, read error paths, check stdout/logging (read-only)
3. Think hard about root cause before planning the fix
4. Create a new plan file at `specs/bug-<slug>.md` using the plan format below
5. Write concrete steps to reproduce — `/implement` will verify before and after
6. If the bug affects UI or user interactions, include an end-to-end test section in the plan
7. Include validation commands for `/implement` — do not run them yourself
8. **Stop** after writing the plan file — report the path and hand off to `/implement`

## Plan Format

Write the plan file using this exact structure (fill every section):

```markdown
# Bug: <title>

## Problem Statement
<what is broken, observed behavior>

## Solution Statement
<expected behavior after fix>

## Steps to Reproduce
1. <step>
2. <step>
3. <observed failure>

## Root Cause Analysis
<hypothesis based on codebase research — agent fills this in>

## Relevant Files
- `path/to/file` — role in the bug

## New Files
<!-- Only if needed -->
- `path/to/new/file` — purpose

## Step-by-Step Tasks
Ordered tasks for `/implement` — do not execute during planning.

1. <task>
2. <task>
3. ...

## Validation Commands
Run all commands after implementation. All must pass.

- `<reproduce command — must fail before fix, pass after>`
- `<test command>`
- `<lint command>`

## End-to-End Test
<!-- Include ONLY if bug affects UI or user interactions -->
<Playwright or manual E2E steps>

## Notes
<regression risks, related issues>
```

## Arguments

$ARGUMENTS — the bug description (high-level prompt from the engineer)

## Bug

$ARGUMENTS

## Done

When `specs/bug-<slug>.md` is written, stop. Report:

```
Plan ready: specs/bug-<slug>.md
Next step (fresh agent): /implement specs/bug-<slug>.md
```

Do not edit application code in this session.
