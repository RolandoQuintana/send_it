# Test

Run backend and frontend validation suites. Output structured JSON for ADW automation.

## Purpose

Validate that the current branch passes all automated checks. This is the **Test** step in the SDLC — functionality, not spec alignment. One agent, one purpose: run tests and report results.

## Instructions

1. Read `state.json` (if present) for `adw_id`, branch, and plan file path
2. Discover validation commands from the plan file's **Validation Commands** section; if absent, use project defaults:
   - Backend: linter, unit tests, type check
   - Frontend: linter, type check, unit tests, build
3. Run validations in order — stop on first failure only to capture output; record all results
4. If any validation fails:
   - Do **not** fix code in this prompt (that is `/resolve-failed-test`)
   - Capture full stdout/stderr for each failed command
5. Output the JSON report below to stdout (ADW parses this)
6. Exit with non-zero status if `success` is false

## Validation Stack (default order)

Run what exists in the project. Skip missing tools; note skips in output.

```bash
# Backend (Python example)
uv run ruff check .
uv run pytest -v

# Frontend (Node example)
npm run lint
npm run typecheck
npm run test
npm run build
```

Adapt commands to the project's `package.json`, `pyproject.toml`, `Makefile`, or CI config.

## JSON Output Format

Print this block to stdout as the final output. ADW scripts parse it.

```json
{
  "success": true,
  "adw_id": "<from state.json or null>",
  "branch": "<current git branch>",
  "summary": "All validations passed",
  "validations": [
    {
      "command": "uv run pytest -v",
      "status": "pass",
      "duration_ms": 4200,
      "output_tail": "52 passed in 4.1s"
    },
    {
      "command": "npm run build",
      "status": "pass",
      "duration_ms": 12000,
      "output_tail": "Build completed successfully"
    }
  ],
  "failures": [],
  "skipped": [
    {
      "command": "npm run test",
      "reason": "no test script in package.json"
    }
  ]
}
```

On failure:

```json
{
  "success": false,
  "adw_id": "<from state.json or null>",
  "branch": "<current git branch>",
  "summary": "2 of 5 validations failed",
  "validations": [ "...all results..." ],
  "failures": [
    {
      "command": "uv run pytest -v",
      "status": "fail",
      "duration_ms": 3100,
      "output": "<full stdout/stderr — agents need complete context>",
      "failed_tests": [
        "tests/test_auth.py::test_login_invalid_password"
      ]
    }
  ],
  "skipped": [],
  "next_step": "invoke /resolve-failed-test with failure output"
}
```

## Rules

- Tests are rule of law — do not weaken assertions to pass
- Re-run **all** validations after any fix (handled by `/resolve-failed-test`, not here)
- Log everything to stdout — ADW cannot see GUI dialogs or silent failures
- One agent, one prompt, one purpose — do not implement fixes in this session

## Arguments

$ARGUMENTS — optional override: path to plan file for validation commands, or `"--quick"` to skip build step

## Test

Run all backend and frontend validations for the current branch. Output JSON report.
