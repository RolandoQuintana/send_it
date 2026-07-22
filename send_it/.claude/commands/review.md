# Review

Review implementation against spec. Automated SDLC review step — not human PR approval.

## Purpose

Validate that what was built matches what was planned. Compare `git diff` to the plan file, capture screenshots as proof of value, and output typed JSON with severity-classified issues. One agent, one purpose: review only.

**Disambiguation:** This is the **SDLC Review agent** (kept in ZTE). It is not the Peter **human Review** element (PR approval — dropped in Pete/ZTE).

## Instructions

1. Load context:
   - Read `state.json` for `adw_id`, branch, plan file path
   - Read the plan file from `specs/` (chore, bug, feature, or patch)
   - Run `git diff main...HEAD` (or `git diff` against base branch from state)
2. For each plan step, verify the diff implements it:
   - Files mentioned in plan were changed
   - Logic matches intent
   - No scope creep or missing steps
3. Capture visual proof (if UI affected):
   - Start app via `/start` if not running
   - Use Playwright MCP: navigate → interact → screenshot
   - Save to `agents/screenshots/review-<slug>-<n>.png`
4. **Read every screenshot into context** — do not review UI from file paths alone
5. Classify each issue by severity
6. Output JSON report to stdout
7. Do **not** fix code in this session — blockers are handled by a follow-up `/patch` → `/implement` chain

## Severity Definitions

| Severity | Meaning | ADW Action |
|----------|---------|----------|
| `blocker` | Spec not met; broken behavior; security issue; missing required step | Auto-patch via `/patch` → `/implement` |
| `tech_debt` | Works but suboptimal; missing tests; naming; minor deviation | Log in PR; optional follow-up issue |
| `skippable` | Nit; style preference; docs typo | Log only; do not block merge |

## JSON Output Format

```json
{
  "success": true,
  "adw_id": "<from state.json>",
  "branch": "<current branch>",
  "plan_file": "specs/feature-export-jsonl.md",
  "summary": "Implementation matches spec. 0 blockers, 1 tech_debt, 2 skippable.",
  "spec_alignment": {
    "steps_total": 5,
    "steps_verified": 5,
    "steps_missing": []
  },
  "screenshots": [
    {
      "path": "agents/screenshots/review-export-button.png",
      "description": "Export button visible in toolbar per spec step 3"
    }
  ],
  "issues": [
    {
      "severity": "tech_debt",
      "title": "Missing edge-case test for empty export",
      "description": "Plan step 4 requires tests; happy path covered only",
      "file": "tests/test_export.py",
      "plan_step": 4
    },
    {
      "severity": "skippable",
      "title": "Button label uses 'Export' not 'Export JSONL'",
      "description": "Spec suggested full label; abbreviated is acceptable",
      "file": "src/components/ExportButton.tsx",
      "plan_step": 3
    }
  ],
  "blockers": [],
  "recommendation": "approve"
}
```

On blockers:

```json
{
  "success": false,
  "adw_id": "<from state.json>",
  "branch": "<current branch>",
  "plan_file": "specs/feature-export-jsonl.md",
  "summary": "1 blocker — export button misplaced",
  "issues": [
    {
      "severity": "blocker",
      "title": "Export button in footer, spec requires toolbar",
      "description": "Screenshot shows button at page bottom; plan step 3 specifies toolbar placement",
      "file": "src/components/ExportButton.tsx",
      "plan_step": 3,
      "screenshot": "agents/screenshots/review-export-misplaced.png"
    }
  ],
  "blockers": ["Export button in footer, spec requires toolbar"],
  "recommendation": "patch",
  "next_step": "invoke /patch with blocker descriptions, then /implement"
}
```

## Review Checklist

- [ ] Plan file read and every step checked
- [ ] `git diff` reviewed for all changed files
- [ ] Screenshots captured for UI changes
- [ ] Screenshots **read into agent context**
- [ ] Issues typed with `blocker` | `tech_debt` | `skippable`
- [ ] JSON output printed to stdout

## Rules

- Proof of value: screenshots, not assumptions
- Read images into context — critical for UI review
- Do not weaken the spec to match the implementation
- One agent, one prompt, one purpose — review only, no fixes

## Arguments

$ARGUMENTS — optional: plan file path override, or base branch (default: `main`)

## Review

Review current branch implementation against the plan. Capture screenshots. Output JSON with classified issues.
