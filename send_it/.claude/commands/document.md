# Document

Generate feature documentation and update conditional doc routing. Meta prompt for the SDLC Document step.

## Purpose

After implementation ships, document how the feature works for future agents and engineers. Produces `app-docs/<feature>.md` and updates `conditional-docs.md` so planning agents load the right docs automatically.

## Instructions

1. Gather context:
   - Read `state.json` for plan file path and branch
   - Read the plan file from `specs/`
   - Run `git diff main...HEAD` (or base branch from state) to see what changed
2. Determine the feature slug from the plan filename (e.g. `specs/feature-export-jsonl.md` → `export-jsonl`)
3. Create or update `app-docs/<slug>.md` using the doc format below
4. Update `conditional-docs.md` — add a routing rule so agents read this doc when working on related code
5. Do not duplicate `ai-docs/` (third-party) content — only document **your** features
6. Report what was created/updated

## Doc Format (`app-docs/<slug>.md`)

```markdown
# <Feature Name>

> One-sentence description of what this feature does.

## Overview

What problem it solves and where it lives in the codebase.

## Key Files

| File | Purpose |
|------|---------|
| `src/...` | ... |

## How It Works

Step-by-step flow an agent can follow to understand behavior.

## Configuration

Env vars, feature flags, defaults (if any).

## API / Interface

Endpoints, function signatures, or UI entry points.

## Testing

How to test manually and which automated tests cover this.

## Common Changes

"When modifying X, also check Y" — guidance for future agents.

## Related Docs

Links to other `app-docs/` files if relevant.
```

## Conditional Docs Update (`conditional-docs.md`)

Read existing `conditional-docs.md` (or create from `templates/conditional-docs.md`). Add a routing rule:

```markdown
Read `app-docs/<slug>.md` when working on <trigger conditions>.
```

Examples:

```markdown
Read `app-docs/export-jsonl.md` when working on export functionality or JSONL output.
Read `app-docs/auth.md` when modifying authentication flows, login, or session handling.
```

Rules for conditional docs:

- One line per feature — concise, scannable
- Trigger on file paths, feature names, or domain keywords agents search for
- Do not remove existing rules — append new ones
- Planning templates (`/chore`, `/bug`, `/feature`, `/prime`) read this file automatically

## Report

```
## Documentation Complete

### Feature Doc
- Created/updated: `app-docs/<slug>.md`

### Conditional Docs
- Added rule: "Read `app-docs/<slug>.md` when ..."

### Summary
<what was documented and why future agents need it>
```

## Rules

- Write for agents first — information-dense, navigable, concrete file paths
- Document behavior as implemented, not as originally planned (use git diff as truth)
- Keep docs under ~200 lines — link to code, don't paste it
- One agent, one prompt, one purpose — document only, no code changes

## Arguments

$ARGUMENTS — optional: plan file path override, or feature slug

## Document

Generate feature documentation from the current branch changes and update conditional-docs.md.
