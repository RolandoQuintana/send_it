# In-Loop Review

Human verification workflow: checkout a feature branch, reset state, start the app, and open the browser for manual review.

## Arguments

`$BRANCH` — branch name to review

## Instructions

1. Stash or commit any uncommitted work
2. Checkout `$BRANCH`
3. Reset database to clean state (run project's DB reset script)
4. Run `/start` to boot servers
5. Open the browser to the frontend URL
6. Report: branch checked out, servers running, browser URL

## Note

This is a **human-in-loop** utility. Use when you need hands-on verification. Prefer automated `/review` for out-loop workflows. After review, checkout main and clean up.
