# AI Doc

Distill third-party library or service documentation into `ai-docs/` for agent consumption.

## Purpose

Create agent-readable reference docs for external SDKs, APIs, and services. Updates `conditional-docs.md` so planning and research agents load the right third-party context automatically.

**You are documenting the vendor — not your app.** App-specific docs belong in `app-docs/` via `/document`.

## Boundaries (CRITICAL)

| Allowed | Forbidden |
|---------|-----------|
| Read official docs (web, MCP, pasted content) | Edit `src/`, `tests/`, or application code |
| Write `ai-docs/<slug>.md` | Write `app-docs/` or `specs/` plans |
| Update `conditional-docs.md` (append routing rule) | Remove existing conditional-docs rules |
| Summarize vendor APIs and patterns | Copy entire vendor doc sites verbatim |

## Instructions

1. Identify the vendor/library from arguments (e.g. `revenuecat`, `stripe`, `playwright`)
2. Research official documentation — use web tools if available; ask for URLs if blocked
3. Distill into `ai-docs/<slug>.md` using the format below — **agent-first**, under ~200 lines
4. Focus on: init/setup, core APIs used in this stack, testing/sandbox, common pitfalls
5. Append a routing rule to `conditional-docs.md` (do not remove existing rules)
6. **Stop** after writing the doc and updating conditional docs

## Doc Format (`ai-docs/<slug>.md`)

```markdown
# <Vendor / Library Name>

> One sentence: what it does and when agents should read this doc.

## Official Resources

- Docs: <url>
- Dashboard / console: <url if applicable>

## Stack Context

<How this project uses it — React Native, Next.js, Python, etc. Adjust for README/CLAUDE.md>

## Setup

<Minimal install + init pattern for this stack>

## Core Patterns

### <Pattern 1 name>
<When to use, code sketch or steps, not full paste>

### <Pattern 2 name>
...

## Configuration

<Env vars, API keys, product IDs — names only, never real secrets>

## Testing / Sandbox

<How to test without production — sandbox accounts, test mode, mocks>

## Common Pitfalls

- <pitfall> → <fix or avoidance>

## Related

- `ai-docs/<other>.md` if relevant
- Link to official docs for edge cases
```

## Conditional Docs Update

Append to `conditional-docs.md` under Third-Party References:

```markdown
- Read `ai-docs/<slug>.md` when working on <trigger keywords>.
```

Examples:

```markdown
- Read `ai-docs/revenuecat.md` when working on subscriptions, in-app purchases, or entitlements.
- Read `ai-docs/stripe.md` when modifying payment flows or billing.
```

## Arguments

$ARGUMENTS — vendor name, library name, and optional: stack context, doc URLs, specific APIs to cover

## AI Doc

$ARGUMENTS

## Done

When `ai-docs/<slug>.md` exists and `conditional-docs.md` is updated, stop. Report:

```
AI doc ready: ai-docs/<slug>.md
Conditional docs: added routing rule for <triggers>
Next step (fresh agent): /research or /feature — agents will load this doc via conditional-docs.md
```

Do not write application code or implementation plans in this session.
