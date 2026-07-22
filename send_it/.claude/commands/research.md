# Research

Produce a Product Requirements Document (PRD) in `specs/` from a high-level idea or problem statement.

## Purpose

Investigate user needs, codebase constraints, and technical context before planning. Output answers **what** and **why** — not **how**. The PRD becomes input for `/feature`, `/bug`, or other planning prompts.

**You are the Researcher. Write the PRD only — do not plan implementation or write code.**

## Boundaries (CRITICAL)

| Allowed | Forbidden |
|---------|-----------|
| Read any file (research) | Edit `src/`, `tests/`, or application code |
| Read `ai-docs/`, `app-docs/`, `conditional-docs.md` | Write implementation plans (`specs/feature-*.md`, etc.) |
| Write `specs/prd-<slug>.md` | Run validation commands (`pytest`, linters, builds) |
| Flag missing `ai-docs/` needs | Execute `/feature`, `/implement`, or planning tasks |

Planning and implementation happen in **separate fresh sessions** after the engineer reviews the PRD.

## Instructions

1. Read `conditional-docs.md` — load any matching `app-docs/` or `ai-docs/` files
2. If third-party SDKs are involved and `ai-docs/<vendor>.md` is missing, note in PRD § Dependencies: "Run `/ai-doc` before planning"
3. Explore the codebase (read-only): existing patterns, relevant files, constraints
4. Think hard about scope, risks, and open questions — do not guess on critical unknowns
5. Create `specs/prd-<slug>.md` using the PRD format below (`<slug>` from the feature name, kebab-case)
6. Fill **Handoff to Planner** with a ready-to-paste prompt for `/feature` or `/bug`
7. **Stop** after writing the PRD — report path and open questions for human review

## PRD Format

Write the PRD file using this exact structure (fill every section):

```markdown
# PRD: <feature or product name>

> Status: draft
> Author: Research Agent
> Date: <YYYY-MM-DD>
> Source: <idea prompt, issue link, or user request>

## Executive Summary

<2-3 sentences: what we're building, for whom, and why it matters>

## Problem Statement

### Current State
<What exists today and what's painful or missing>

### Desired State
<What success looks like for users>

### Why Now
<Business or technical urgency — optional>

## Users & Personas

| Persona | Need | Pain Point |
|---------|------|------------|
| <role> | <what they want> | <current friction> |

## Goals & Non-Goals

### Goals
- <measurable outcome>

### Non-Goals
- <explicitly out of scope>

## User Stories

1. As a <user>, I want <action> so that <benefit>.

## Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-1 | <requirement> | must | |

## Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1 | <requirement> | <target> |

## Acceptance Criteria

- [ ] <testable criterion>

## Technical Context

### Existing Patterns
<Similar features in codebase — files, APIs, components>

### Relevant Files (Initial)
- `path/to/file` — <role>

### Dependencies
<External services, libraries, APIs. List required `ai-docs/` files or flag missing ones>

### Constraints
<Tech stack limits, compatibility, migration needs>

## UX / Design Notes

<Key interactions, flows, or links to mockups>

## Research Notes

<Findings, patterns to follow, risks from codebase exploration>

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| <risk> | high/med/low | <plan> |

## Open Questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | <unresolved question> | human | open |

## Handoff to Planner

### Suggested Problem Class
`feature` | `bug` | `chore` | `patch`

### Suggested Planner Prompt
<Ready-to-paste high-level prompt for `/feature` or `/bug` — reference this PRD path>

### Conditional Docs to Load
<List `app-docs/` and `ai-docs/` files planners should read>
```

## Quality Gate

PRD is ready for human review when:
- Acceptance criteria are testable (not vague)
- Non-goals are explicit
- Open questions are flagged — not silently assumed
- Handoff includes suggested planner prompt and problem class

## Arguments

$ARGUMENTS — the idea, problem statement, or feature concept (high-level)

## Research

$ARGUMENTS

## Done

When `specs/prd-<slug>.md` is written, stop. Report:

```
PRD ready: specs/prd-<slug>.md
Open questions: <count> — engineer must resolve before planning
Next steps:
  1. Engineer reviews PRD and answers open questions
  2. If third-party SDK: /ai-doc "<vendor>" (fresh agent) if ai-docs/ missing
  3. /feature or /bug with suggested planner prompt (fresh agent)
```

Do not write plans, code, or run validation in this session.
