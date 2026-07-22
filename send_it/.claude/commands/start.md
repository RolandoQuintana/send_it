# Start

Start the application servers so agents can run and observe stdout.

## Instructions

1. Check if servers are already running on expected ports; stop if conflicting
2. Start backend and frontend using the project's start script (e.g., `scripts/start.sh`)
3. Run in background with sufficient timeout for long-running observation
4. Verify both servers respond (health check or curl)
5. Report URLs and PIDs

## Arguments

Optional: timeout in seconds for observation mode (default: 300)

## Report

```
Backend:  http://localhost:<port> — running
Frontend: http://localhost:<port> — running
```

All server output must be visible via stdout for agent self-validation.
