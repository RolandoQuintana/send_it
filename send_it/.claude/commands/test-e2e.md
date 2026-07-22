# Test E2E

Run a Playwright end-to-end test file. Higher-order prompt — takes an E2E test path as argument.

## Purpose

Execute a single E2E test (or test file) via Playwright MCP. Validates user-facing behavior the unit test stack cannot catch. One agent, one purpose: run the specified E2E test and report.

## Instructions

1. Read the E2E test file path from arguments
2. Ensure the app is running:
   - Check if dev server is up (health endpoint or port check)
   - If not running, invoke `/start` or start servers per `README.md`
3. Read the test file to understand: URL, selectors, assertions, expected screenshots
4. Execute the test using Playwright MCP tools:

### Playwright MCP Steps

```
1. browser_navigate    → open base URL from test or env (e.g. http://localhost:3000)
2. browser_snapshot    → capture accessibility tree for element discovery
3. browser_click       → interact with buttons, links, inputs
4. browser_type        → fill form fields
5. browser_wait_for    → wait for text, element, or navigation
6. browser_take_screenshot → capture proof at assertion points
7. browser_evaluate    → run JS when needed for state checks
```

5. Compare actual behavior against test assertions
6. If test fails: capture screenshot + full error; do **not** fix code (use `/resolve-failed-test`)
7. Output JSON report to stdout

## JSON Output Format

```json
{
  "success": true,
  "test_file": "tests/e2e/export.spec.ts",
  "summary": "E2E test passed — 7 results displayed",
  "steps": [
    {
      "action": "navigate",
      "target": "http://localhost:3000/search",
      "status": "pass"
    },
    {
      "action": "type",
      "target": "input[name='query']",
      "value": "agentic coding",
      "status": "pass"
    },
    {
      "action": "click",
      "target": "button[type='submit']",
      "status": "pass"
    },
    {
      "action": "assert",
      "expected": "7 results",
      "actual": "7 results",
      "status": "pass"
    }
  ],
  "screenshots": [
    "agents/screenshots/e2e-export-results.png"
  ],
  "duration_ms": 8500
}
```

On failure:

```json
{
  "success": false,
  "test_file": "tests/e2e/export.spec.ts",
  "summary": "Assertion failed at step 4",
  "failed_step": {
    "action": "assert",
    "expected": "7 results",
    "actual": "0 results",
    "status": "fail"
  },
  "screenshots": [
    "agents/screenshots/e2e-export-failure.png"
  ],
  "error": "<full error output>",
  "next_step": "invoke /resolve-failed-test with this output"
}
```

## Alternative: CLI Execution

If Playwright CLI is configured and MCP is unavailable:

```bash
npx playwright test <test-file-path> --reporter=json
```

Parse JSON reporter output into the format above.

## Rules

- Save screenshots to `agents/screenshots/` with descriptive names
- Read screenshots into context when debugging failures
- Do not modify application code in this session
- Re-run from a clean browser state between attempts

## Arguments

$ARGUMENTS — path to the E2E test file (e.g. `tests/e2e/search.spec.ts`)

## Test E2E

Run Playwright E2E test: $ARGUMENTS
