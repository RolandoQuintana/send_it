# PRD: Blast Scale Testing Infrastructure

> Status: draft (product decisions captured 2026-07-27)
> Author: Research Agent
> Date: 2026-07-27
> Source: User request — reproduce Blast failures reported at large group sizes; cannot test with hundreds of real recipients

## Executive Summary

Sent It's **Blast** feature sends personalized messages to an entire group via an Apple Shortcut (`Sent It Blast`), but the developer cannot reproduce user-reported failures at high recipient counts without spamming real people. We need a **developer-only scale-testing workflow** that simulates 100–200+ recipients safely, surfaces where failures occur (app payload → clipboard → Shortcut loop → Messages), and establishes repeatable benchmarks — without changing production Blast behavior for end users.

## Problem Statement

### Current State

- **Blast is the core power-user flow.** Users compose a message, tap Blast in the composer `+` menu, confirm once, and the app hands off to Shortcuts which sends individual messages with no per-recipient confirmation (`group_message_screen.dart`, `more_screen.dart`).
- **App builds a JSON payload and copies it to the clipboard.** `ShortcutService.sendViaShortcut()` personalizes `{firstname}`, stages optional media to Documents (`blast_media.<ext>`), JSON-encodes an array of `{number, message, mediaFile?}` objects, writes to clipboard, then opens `shortcuts://run-shortcut?name=Sent%20It%20Blast&input=clipboard` (`shortcut_service.dart`).
- **Execution is outside the Flutter app.** After launch, behavior is entirely determined by the bundled shortcut (`assets/sent_it_blast.shortcut`, signed binary) and iOS Shortcuts/Messages subsystems. The app shows "Blast Launched" and clears the composer — it has **no visibility** into per-message success, partial completion, or crash point.
- **No recipient cap in app code.** Groups can contain any number of contacts returned by `flutter_contacts`; there is no guardrail or warning for large blasts.
- **No automated or documented scale tests.** `test/` has no `ShortcutService` coverage. There is no mock contact dataset, debug shortcut variant, or QA playbook for high-volume runs.
- **A separate native send path exists but is not Blast.** The standard Send button uses `MFMessageComposeViewController` via `AppDelegate.swift` with per-recipient UI and optional 800ms delays for media — useful for comparison but not equivalent to the unattended Shortcut loop.
- **User report (partially scoped).** Confirmed: **Blast** (not standard Send), **~200 recipients**, Shortcut **appears to just stop** (no app error). Unknown: text vs media, reporter iOS version, exact stop index. Standard per-recipient Send generally works — failure is Shortcut-specific.

### Desired State

- Developer can **reliably reproduce Blast at 50, 100, 150, and 200 recipients** on a physical iOS device without messaging real people.
- Failures are **observable**: know the last completed index, elapsed time, and whether the break is in payload generation, clipboard handoff, Shortcut execution, or Messages.
- Test setup is **repeatable** (documented steps + optional scripted assets) and **safe** (non-routing test numbers only).
- **Diagnose root cause first** — do not pre-commit to a fix (Wait/throttle, chunking, caps, warnings) until scale tests pinpoint where and why the loop stops at ~200.

### Why Now

A user is reporting Blast problems at scale. Without a scale-testing harness, the team cannot confirm the bug, find the breaking point, or validate fixes. Blast is a headline Pro feature and a primary conversion driver — silent partial failures erode trust.

## Users & Personas

| Persona | Need | Pain Point |
|---------|------|------------|
| Developer / QA | Reproduce and debug large-group Blast failures | No safe way to test 100+ recipients |
| Power user (reporter) | Reliable blast to large groups | Experiences unknown failure at scale |
| Support / owner | Understand failure mode from user reports | No logging, no known limits to communicate |

## Goals & Non-Goals

### Goals

- Enable **safe high-volume Blast testing** using fictional NANP numbers (e.g. `+1-555-01XX`) that do not route to real subscribers.
- Provide a **repeatable test contact dataset** (e.g. 200-entry VCF or import script) in a dedicated "Blast Test" contact group.
- Add **observability inside the Shortcut loop** (append index/timestamp to an iCloud Drive log file) to pinpoint crash/stop index.
- Document and validate **Shortcuts tuning** (inter-iteration Wait, "Show When Run" off, foreground execution, auto-lock disabled).
- Establish **baseline breaking points** for text-only and media blasts at N = 25, 50, 100, 150, 200.
- Optionally add **app-side debug logging** (payload item count, serialized byte size) before clipboard write — dev builds only.

### Non-Goals

- Sending test blasts to real phone numbers or personal contacts.
- Changing production Blast UX for end users (warnings, chunking, progress UI) — separate follow-up if limits are confirmed.
- Replacing the Apple Shortcut architecture with in-app unattended SMS (not supported by public iOS APIs).
- Automated CI integration for Shortcut execution (requires physical device + Shortcuts.app; not feasible in standard Flutter test runner).
- Shipping a production fix in this effort — scope is **diagnostic tooling** first; fix is a follow-up task once root cause is confirmed.
- Modifying the native per-recipient `sendMessage` path (different product behavior).

## User Stories

1. As a **developer**, I want 200 mock contacts with safe test numbers so that I can select a large group without texting real people.
2. As a **developer**, I want the Shortcut to log progress to a file so that I can see exactly where a large blast stopped.
3. As a **developer**, I want a documented test protocol so that I can reproduce results across devices and iOS versions.
4. As a **developer**, I want to know the clipboard payload size before launch so that I can rule in/out clipboard limits.
5. As a **developer**, I want a debug Shortcut variant with configurable delay so that I can test whether throttling prevents crashes.

## Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-1 | Provide importable mock contact dataset (≥200 entries) using `+1-555-0100`–`+1-555-0199` (or equivalent NANP fictional range) | must | VCF or scripted Contacts import; unique display names for `{firstname}` personalization |
| FR-2 | Document creation of a dedicated "Blast Test" contact group on device/Mac/iCloud | must | Keeps test data separate from real contacts |
| FR-3 | Debug Shortcut variant (`Sent It Blast (Debug)` or equivalent) with loop progress logging to iCloud Drive `.txt` | must | Log: index, recipient number, timestamp; append per iteration |
| FR-4 | Debug Shortcut supports configurable **Wait** between iterations (default 1–2s for scale tests) | must | Test hypothesis that rapid-fire Send Message causes crash |
| FR-5 | Document Shortcuts "Show When Run" disabled on Send Message actions | must | Reduces UI churn during unattended loop |
| FR-6 | Document device prep: Auto-Lock Never, Shortcuts foreground, Low Power Mode off | must | Mitigate background-kill hypothesis |
| FR-7 | Scale test matrix: record pass/fail and last-logged index at N ∈ {25, 50, 100, 150, 200} for text-only | must | Baseline benchmarks |
| FR-8 | Scale test matrix: same sizes with 1 staged media attachment (`blast_media.jpg`) | should | Media path uses Documents + Files handoff |
| FR-9 | App debug build logs payload `count` and `utf8Bytes` before clipboard write | should | `ShortcutService.sendViaShortcut()` — no production impact |
| FR-10 | Test playbook documents how to reset/clear log file between runs | must | Avoid ambiguous multi-run logs |
| FR-11 | Capture environment metadata per run: iOS version, device model, Shortcut version hash/date | must | For correlating user reports |
| FR-12 | Production `Sent It Blast` shortcut unchanged in this phase | must | Debug fork only; production fix is separate task after diagnosis |
| FR-13 | Debug Shortcut is a **forked copy** of production (`Sent It Blast (Debug)`) | must | Same JSON contract; adds logging + configurable Wait |
| FR-14 | Mock contacts generated via **repo script** (`tools/generate_blast_test_contacts.*`) | must | Not manual Contacts entry |

## Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1 | Mock dataset generation reproducible from repo script | One command produces identical VCF |
| NFR-2 | Debug logging overhead | < 500ms per iteration (should not dominate Wait tuning) |
| NFR-3 | No real SMS/MMS delivery during scale tests | 100% fictional numbers |
| NFR-4 | Test assets live outside user-facing app bundle | `tools/` or `test-fixtures/` — not shipped in release IPA |

## Acceptance Criteria

- [ ] Developer imports ≥200 mock contacts and creates a Sent It group with all of them
- [ ] Blast (debug shortcut) completes or fails with a log file showing last successful index
- [ ] Text-only blast tested at 25, 50, 100, 150, 200 — results recorded in a test log template
- [ ] Media blast tested at same sizes (or failure threshold documented if lower)
- [ ] Payload byte size for 200 contacts logged (app debug or manual `jsonEncode` estimate)
- [ ] Documented whether Wait duration affects crash point (0s vs 1s vs 2s)
- [ ] Production shortcut install flow (`More → Install Shortcut`) still works unchanged
- [ ] No mock contacts or debug shortcut included in App Store release build

## Technical Context

### Existing Patterns

**Blast handoff (app → Shortcut):**

```dart
// shortcut_service.dart — payload → clipboard → shortcuts:// URL
[{"number": "+15551234567", "message": "Hey John, ...", "mediaFile": "blast_media.jpg"}, ...]
```

**Install flow:** Bundled signed `.shortcut` extracted to temp, shared via `UIActivityViewController` (`openShortcutFile` in `AppDelegate.swift`).

**Personalization:** `{firstname}` replaced from `contact.displayName.split(' ').first`.

**Media staging:** Copied to app Documents (`UIFileSharingEnabled`); Shortcut reads via "On My iPhone → Sent It" path.

**Native send (not Blast):** `group_message_screen.dart` loops `platform.invokeMethod('sendMessage')` with `MFMessageComposeViewController` — requires user tap per message; 800ms delay between media sends.

### Relevant Files (Initial)

- `lib/services/shortcut_service.dart` — payload build, clipboard, URL launch
- `lib/screens/group_message_screen.dart` — Blast UI, confirmation dialog, `sendViaShortcut()` call
- `lib/screens/more_screen.dart` — shortcut install UX
- `assets/sent_it_blast.shortcut` — production signed shortcut (binary; edit in Shortcuts.app, re-export, re-sign)
- `ios/Runner/AppDelegate.swift` — `openShortcutFile`, native `sendMessage` (comparison only)
- `pubspec.yaml` — bundles shortcut asset

### Dependencies

- Apple Shortcuts.app (device)
- Apple Contacts (mock import)
- iCloud Drive (optional, for log file persistence across crashes)
- No third-party SDK — no new `ai-docs/` required

### Constraints

- **Signed shortcut format.** `assets/sent_it_blast.shortcut` is Apple-signed (`AEA1` header). Modifications require editing in Shortcuts.app on Mac/iOS, exporting, and replacing the asset (with `shortcuts sign` if needed). Cannot diff or patch the binary in-repo directly.
- **Clipboard as transport.** Entire recipient array must fit in pasteboard. Estimated sizes: ~6 KB (200 text-only short messages), ~11 KB (200 with media filename), ~106 KB (200 × 500-char body). iOS pasteboard typically tolerates this range but should be measured on device for edge cases (very long templates).
- **No runtime telemetry from Shortcut to app.** App cannot know loop progress without either (a) debug logging inside Shortcut, or (b) a future native channel — out of scope for v1 testing.
- **555 numbers.** NANP `555-01XX` (`+1-XXX-555-01XX`) is reserved for fictional use in North America and is the recommended safe range. **Caveat:** Shortcuts may still invoke Messages UI/API per iteration; behavior with non-subscriber numbers should be verified (may show errors without delivering).
- **Simulator limitations.** Shortcuts + SMS/Messages behavior is unreliable in Simulator; scale tests require a **physical iPhone**.

## UX / Design Notes

This is **developer tooling only** — no end-user UI changes in v1.

**Recommended test flow:**

```
1. Generate/import mock VCF → "Blast Test" contacts on device
2. Create Sent It group "Scale Test 200" with all mock contacts
3. Install debug Shortcut variant (separate from production)
4. Compose short template: "Hi {firstname}, scale test."
5. Tap Blast → confirm → Shortcuts runs
6. On failure: open iCloud Drive log → note last index
7. Adjust Wait / recipient count → repeat
```

**Device settings checklist (per run):**

- Settings → Display → Auto-Lock → Never
- Low Power Mode off
- Shortcuts app foreground during run
- Send Message actions: "Show When Run" off (if applicable to installed iOS version)

## Research Notes

### Validating the user's starting hypotheses

| Claim | Assessment | Notes |
|-------|------------|-------|
| Use 555-01XX mock numbers | **Likely valid** | Standard NANP fictional range; avoids real subscribers |
| VCF import for 200 contacts | **Valid** | Fastest way to populate Contacts for group selection |
| Shortcut crashes from memory/timeout at scale | **Plausible, unverified** | Apple does not document loop limits; common community report for large Repeat loops |
| File logger inside loop | **Valid approach** | Only practical way to get crash index without Xcode attached to Shortcuts |
| Wait 1–2s between iterations | **Valid experiment** | Tests throttling hypothesis; tradeoff is test duration (200 × 2s ≈ 7 min minimum) |
| Disable "Show When Run" | **Valid** | Reduces compose-sheet UI overhead per Send Message |
| Keep device awake / foreground | **Valid** | iOS aggressively suspends background Shortcuts |
| Carrier spam filters flagging your number | **N/A for mock numbers** | Real concern for production user blasts, not dev scale tests |

### Failure modes to distinguish

1. **App never launches Shortcut** — `canLaunchUrl` false, clipboard empty, payload empty (`noValidContacts`)
2. **Clipboard truncation** — partial JSON → Shortcut parse error immediately
3. **Shortcut crash mid-loop** — log shows index N then stops; likely Shortcuts/OS limit or Send Message failure
4. **Messages errors per recipient** — loop continues but some fail (may need log + screenshot)
5. **Media-specific** — `blast_media.<ext>` missing from Documents, attachment step fails
6. **User environment** — Low Power Mode, backgrounded app, iOS version regression

### Known reporter context (2026-07-27)

| Field | Value |
|-------|-------|
| Feature | Blast (Shortcut) — not standard Send |
| Recipient count | ~200 (last known failure; no exact upper bound) |
| Observed behavior | Shortcut appears to **just stop** |
| Text vs media | Unknown — test both in matrix |
| Reporter iOS version | Unknown — capture in test runs |
| Standard Send button | Generally works — isolates issue to Shortcut path |

### Payload size reference (estimated)

| Scenario | ~Size (200 recipients) |
|----------|------------------------|
| Short text, no media | 6 KB |
| Short text + mediaFile key | 11 KB |
| 500-char message, no media | 106 KB |

No app-side limit enforced today.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Debug shortcut accidentally shipped to users | med | Keep debug variant out of `pubspec.yaml` assets; separate file in `tools/` |
| 555 numbers still trigger Messages errors/noise | low | Expected; goal is loop stress, not delivery confirmation |
| Cannot attach Xcode to Shortcuts for crash logs | med | File-based index logging is primary observability |
| Production shortcut differs from debug variant | med | Document diff; port only proven fixes to production shortcut |
| Test results not reproducible across iOS versions | med | Record OS version per run; test on reporter's iOS if known |
| Long Wait makes 200-recipient test impractical | low | Binary-search: find crash threshold first, then tune Wait |
| User report is media-specific | med | Include media matrix in test plan (FR-8) |
| Re-signing shortcut breaks install flow | med | Follow existing export → `assets/` → `shortcuts sign` workflow; verify More screen install |

## Open Questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | ~~Recipient count at failure?~~ | human | **resolved** — ~200 (no exact max; last known failure at 200) |
| 2 | Text-only or with media? | human | **open** — reporter unsure; test both in matrix |
| 3 | ~~What did user observe?~~ | human | **resolved** — Shortcut appears to just stop |
| 4 | ~~Debug Shortcut approach?~~ | engineer | **resolved** — forked copy of production |
| 5 | ~~Repo script vs manual contacts?~~ | human | **resolved** — repo script |
| 6 | ~~Fix approach (Wait/chunking/caps/warning)?~~ | human | **resolved** — diagnose first; fix deferred until root cause known |
| 7 | ~~Blast vs standard Send?~~ | human | **resolved** — Blast only; standard Send generally works |
| 8 | Reporter **iOS version** and device model? | human | open — ask reporter; record in all test runs |

## Handoff to Planner

### Suggested Problem Class

`chore` (developer QA tooling + debug Shortcut variant + test playbook; optional small debug-only app logging)

### Suggested Planner Prompt

```
/chore "Blast scale testing harness for Sent It"

Read specs/prd-blast-scale-testing.md first.

Goal: DIAGNOSE why Blast stops at ~200 recipients — not ship a fix yet.

Known context: Blast (not standard Send); Shortcut just stops at ~200; text vs media unknown.

Scope:
1. Add tools/generate_blast_test_contacts.py (or .sh) → 200-contact VCF
   - Numbers: +1-555-0100 through +1-555-0299 (safe NANP range)
   - Unique display names for {firstname} (e.g. "Test Contact 001")
2. Add tools/blast-scale-test-playbook.md — device setup, test matrix template, log interpretation
3. Fork production shortcut → tools/sent_it_blast_debug.shortcut ("Sent It Blast (Debug)")
   - NOT in pubspec release assets
   - Same JSON clipboard contract as production
   - Repeat loop: append "index, number, ISO timestamp" to iCloud Drive/BlastTest/log.txt
   - Configurable Wait (test 0s, 1s, 2s to isolate throttle hypothesis)
   - Send Message: Show When Run off
4. Optional: kDebugMode logging in ShortcutService.sendViaShortcut — contact count + payload byte size
5. Do NOT change production assets/sent_it_blast.shortcut
6. Do NOT add end-user caps, warnings, or chunking yet

Validate:
- Reproduce stop at ~200 with debug shortcut; log shows last completed index
- Matrix at 25/50/100/150/200 — text-only AND with media (reporter unsure which)
- Document: stop index, iOS version, Wait setting, payload size
- Production Install Shortcut flow unchanged
```

### Conditional Docs to Load

- `specs/prd-blast-scale-testing.md` (this PRD)
- `lib/services/shortcut_service.dart`
- `lib/screens/group_message_screen.dart`
- `assets/sent_it_blast.shortcut` (reference only — binary)
- `ios/Runner/AppDelegate.swift`
