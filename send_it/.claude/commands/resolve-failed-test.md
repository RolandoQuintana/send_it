# Resolve Failed Test

Fix failing tests and re-run all validations until they pass. Closed-loop resolve step.

## Purpose

Take failed test output (from `/test`, `/test-e2e`, or CI), diagnose root cause, fix the code, and re-run **all** validations from the start. Embodies Request → Validate → **Resolve** (Tactic 5).

## Instructions

1. Read the failure output from arguments (JSON from `/test`, `/test-e2e`, or raw CI log)
2. Identify root cause — not symptoms:
   - Parse failed test names, assertion messages, stack traces
   - Read the failing test file and the code under test
   - If E2E failure: read screenshots into context
3. Fix the application code (or update tests **only** when the test is wrong — document why)
4. Re-run **every** validation command from the plan's **Validation Commands** section (or project defaults) — not just the failed one
5. If any validation still fails: repeat diagnose → fix → re-run all
6. Do not mark complete until all validations pass
7. Output JSON report to stdout

## Closed-Loop Pattern

```
[Request]  Fix failures described in input
[Validate] Re-run ALL validations from start
[Resolve]  If still failing, loop until pass or max attempts reached
```

## JSON Input (from /test or /test-e2e)

The argument may be a path to a JSON file or inline JSON:

```json
{
  "success": false,
  "failures": [
    {
      "command": "uv run pytest -v",
      "output": "...",
      "failed_tests": ["tests/test_auth.py::test_login_invalid_password"]
    }
  ]
}
```

## JSON Output Format

```json
{
  "success": true,
  "summary": "Fixed 1 failing test; all validations pass",
  "attempts": 2,
  "fixes": [
    {
      "issue": "test_login_invalid_password — expected 401, got 500",
      "root_cause": "Missing null check on password field in auth handler",
      "files_changed": ["src/auth/handler.py"],
      "resolution": "Added guard for empty password before hash comparison"
    }
  ],
  "validation_results": [
    { "command": "uv run ruff check .", "status": "pass" },
    { "command": "uv run pytest -v", "status": "pass" },
    { "command": "npm run build", "status": "pass" }
  ]
}
```

On unresolved failure (after 3 attempts):

```json
{
  "success": false,
  "summary": "Unable to resolve after 3 attempts",
  "attempts": 3,
  "fixes": [ "...attempted fixes..." ],
  "remaining_failures": [
    {
      "command": "uv run pytest -v",
      "output": "<latest failure output>"
    }
  ],
  "recommendation": "escalate — improve template or add missing test coverage"
}
```

## Rules

- Tests are rule of law — fix code, not assertions (unless test is genuinely wrong)
- Re-run **all** validations after every fix, from the start
- Max 3 resolve attempts before escalating
- Log full command output to stdout
- Read screenshots for E2E failures before changing UI code

## Arguments

$ARGUMENTS — failed test JSON (file path or inline), or raw pytest/playwright output

## Resolve

Fix the failing tests described below and re-run all validations until they pass.

$ARGUMENTS
