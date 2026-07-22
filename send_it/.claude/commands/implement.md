# Implement

Execute a plan file. Higher-order prompt — takes a plan as argument.

## Purpose

Read a plan from `specs/`, think hard, implement every step, validate, and report.

## Instructions

1. Read the plan file at the path provided in arguments
2. Think hard about the plan before writing any code
3. Execute every step in order, top to bottom — do not skip or reorder
4. After implementation, run every **Validation Command** listed in the plan
5. If any validation fails: fix the issue, then re-run ALL validations from the start
6. Do not mark work complete until all validations pass
7. Report completed work

## Report

```
## Implementation Complete

### Plan
<path to plan file>

### Work Summary
<what was done, keyed to plan steps>

### Files Changed
- `path` — change description

### Validation Results
- [command]: PASS/FAIL

### Issues Encountered
<any problems and how resolved, or "none">
```

## Arguments

$ARGUMENTS — absolute or relative path to the plan file in `specs/`

## Plan

Read and implement: $ARGUMENTS
