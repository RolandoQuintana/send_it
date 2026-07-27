# Conditional Documentation

> Routes agents to the right docs for send_it. Edit as the app grows.

## Always Read

| Doc | When |
|-----|------|
| `README.md` | Install, run, test, analyze commands |
| `CLAUDE.md` | Validation commands, project conventions |
| `pubspec.yaml` | Dependencies and Flutter SDK constraints |
| `tac-os/knowledge/quick-reference.md` | TAC methodology cheat sheet |

## Read When Relevant

| Condition | Doc |
|-----------|-----|
| Groups / messaging UI | `lib/screens/group_message_screen.dart`, `lib/models/message_group.dart` |
| Contact picker / permissions | `lib/services/contact_search_service.dart`, `permission_handler` in pubspec |
| Persistence | `lib/services/group_storage.dart`, `lib/services/keyboard_height_storage.dart` |
| iOS shortcuts | `lib/services/shortcut_service.dart` |
| Subscriptions / IAP / paywalls / entitlements | `ai-docs/revenuecat.md` |
| TestFlight / App Store builds / ASC automation | `ai-docs/asc.md` |
| Feature shipped | `app-docs/<feature>.md` (created by `/document`) |

## Do Not Read Unless Asked

| Doc | Reason |
|-----|--------|
| `tac-os/knowledge/tac.md` | Full course manual — use quick-reference instead |
| `tac-os/ARCHITECTURE.md` | TAC OS internals — not app code |
| `specs/*.md` | Only read the specific plan you're implementing |

## Third-Party References

- Read `ai-docs/<vendor>.md` when integrating external SDKs (create via `/ai-doc` first)
- Read `ai-docs/revenuecat.md` when working on subscriptions, in-app purchases, paywalls, entitlements, or grandfathering
- Read `ai-docs/asc.md` when working on TestFlight, App Store submissions, builds, ASC-side IAP/subscriptions, or release automation

## Stack-Specific

| Stack Area | Doc |
|------------|-----|
| Flutter / FVM | Use `fvm flutter` for all commands (see `.fvmrc`) |
| iOS native | `ios/` — only when changing platform config or shortcuts |
| iOS release / ASC | `ai-docs/asc.md` — TestFlight, builds, App Store Connect CLI |
