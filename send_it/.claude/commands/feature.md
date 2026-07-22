# Feature

Create a plan in `specs/` to implement a new feature using the feature plan format.

## Purpose

Generate a comprehensive feature plan from a high-level description. The plan becomes the prompt for `/implement`.

**You are the Planner. Write the plan only — do not implement.**

## Boundaries (CRITICAL)

| Allowed | Forbidden |
|---------|-----------|
| Read files (research) | Edit `src/`, `tests/`, or any application code |
| Write `specs/feature-<slug>.md` | Run validation commands |
| Summarize findings in the plan | Execute plan tasks or run `/implement` |

Implementation happens in a **separate fresh session** via `/implement specs/feature-<slug>.md`.

## Instructions

1. Run `/prime` mental model — understand codebase architecture before planning
2. Read `conditional-docs.md` — pull in relevant docs for the feature domain
3. Research existing patterns: how similar features are built in this codebase (read-only)
4. Think hard about the implementation approach — prefer consistency with existing patterns
5. Create a new plan file at `specs/feature-<slug>.md` using the plan format below
6. Break work into Foundation → Core → Integration → Polish phases
7. Include acceptance criteria and validation commands for `/implement`
8. If UI feature: specify end-to-end test steps in the plan
9. **Stop** after writing the plan file — report the path and hand off to `/implement`

## Plan Format

Write the plan file using this exact structure (fill every section):

```markdown
# Feature: <title>

## Description
<what we're building>

## User Story
As a <user>, I want <goal> so that <benefit>.

## Problem / Solution
**Problem:** <current pain>
**Solution:** <proposed approach>

## Relevant Files
- `path/to/file` — role

## New Files
- `path/to/new/file` — purpose

## Implementation Plan

### Foundation
1. <task>

### Core
2. <task>

### Integration
3. <task>

### Polish
4. <task>

## Step-by-Step Tasks
Ordered tasks for `/implement` — do not execute during planning.

1. <task>
2. <task>
...

## Testing
- Unit tests for: <areas>
- E2E test: <description if UI feature>

## Validation Commands
Run all commands after implementation. All must pass.

- `<lint command>`
- `<test command>`
- `<build command>`
- `<e2e command if UI>`

## Acceptance Criteria
- [ ] <criterion>
- [ ] <criterion>

## Notes
<dependencies, risks, out of scope>
```

## Arguments

$ARGUMENTS — the feature description (high-level prompt from the engineer)

## Feature

$ARGUMENTS

## Done

When `specs/feature-<slug>.md` is written, stop. Report:

```
Plan ready: specs/feature-<slug>.md
Next step (fresh agent): /implement specs/feature-<slug>.md
```

Do not edit application code in this session.
