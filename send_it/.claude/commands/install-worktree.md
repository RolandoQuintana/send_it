# Install Worktree

Set up an isolated git worktree environment for parallel agent execution.

## Arguments

- `$WORKTREE_PATH` — absolute path to the worktree directory
- `$PORT_BACKEND` — backend port for this instance
- `$PORT_FRONTEND` — frontend port for this instance

## Instructions

1. Create the worktree: `git worktree add $WORKTREE_PATH <branch-name>`
2. Copy environment files into the worktree (`.env`, nested env files)
3. Update port configuration in the worktree to use `$PORT_BACKEND` and `$PORT_FRONTEND`
4. Install dependencies inside the worktree (backend + frontend)
5. Run database setup/migrations scoped to this worktree
6. Verify the app starts on the assigned ports
7. Report worktree path, branch, and ports assigned

## Report

```
Worktree: $WORKTREE_PATH
Branch: <branch>
Backend: http://localhost:$PORT_BACKEND
Frontend: http://localhost:$PORT_FRONTEND
Status: ready
```
