# Chore: TestFlight Blast diagnostics (Notes logging shortcut)

## Description

Ship a **TestFlight-only** diagnostic path so the reporting user can reproduce a large-group Blast while logging progress to a **Notes** note — with **minimal setup** (one in-app install tap, then use Blast normally).

**Context from scale testing (2026-07-27):**

- Reporter: ~200-person group; Shortcut stopped with a **“took too long to send”** style error (Shortcuts runtime limit).
- Dev test (555 numbers): Shortcut loop completed all 200; Messages degraded ~154+ (green → blue/failed).
- Root cause is likely **platform limits** (Shortcuts timeout + Messages throughput), not app payload bugs.
- Need **real-number** telemetry from reporter: last logged index, timestamps, Shortcut error text, recipient count.

**Goal:** Capture that telemetry without asking the reporter to build shortcuts, edit variables, or use Mac/Xcode.

**Out of scope:** Fixing chunking/timeouts in this chore — diagnostics only. App Store production builds must behave unchanged.

## Approach (decision)

| Option | Reporter setup | Pros | Cons |
|--------|----------------|------|------|
| A. Manual debug shortcut (current) | Duplicate/edit shortcut, Notes setup | Full control | Too much for beta tester |
| B. **Bundled diagnostic shortcut + TestFlight flag (recommended)** | One tap Install in More; Blast works as today | Minimal friction; same install pattern as production | Must sign & maintain second `.shortcut` asset |
| C. In-app send loop (no Shortcut) | None | Full telemetry in app | Large refactor; loses unattended Blast UX |

**Recommendation: Option B**

- Bundle `assets/sent_it_blast_diagnostic.shortcut` (signed), installed via existing share-sheet flow.
- TestFlight IPA built with `--dart-define=BLAST_DIAGNOSTICS=true` → app auto-launches **Sent It Blast (Diagnostic)** instead of production shortcut.
- Diagnostic shortcut = production logic + **Append to Note** each iteration (use Shortcuts **Repeat Index**, not manual `LoopIndex` variable).
- App Store archive **without** the define → production shortcut only, no diagnostic UI.

## Reporter experience (target)

1. Install **TestFlight** build (invite from owner).
2. Open Sent It → **More** → **Install Diagnostic Blast** (one tap, add to Shortcuts — same as production install).
3. Use Blast normally on their real ~200 group.
4. When done (or if Shortcut stops), open **Notes** → note **Sent It Blast Log** → Share → send to owner.
5. Optional: screenshot Shortcut error if shown.

**No:** Mac, VCF imports, variable wiring, iCloud folder setup, or `dart-define` on their side.

## Diagnostic shortcut spec

**Name (exact):** `Sent It Blast (Diagnostic)`

**Base:** Fork production `Sent It Blast` — same JSON clipboard contract, same Send Message + optional media path.

**Add inside Repeat with Each** (after parsing `number` / `message` / `mediaFile`, before or after Send Message):

1. **Text** — build line using magic variables:
   - `Repeat Index`, `number`, `Current Date` (medium or ISO)
   - Example line: `42,+15551234567,2026-07-28 18:30:00`
2. **Append to Note** — note name: **`Sent It Blast Log`**
   - Creates note on first append if missing

**At start of shortcut** (before loop):

1. **Text** — header line: `--- RUN START: Current Date | Recipients: [Count of Shortcut Input] ---`
2. **Append to Note** → `Sent It Blast Log`

**At end of shortcut** (after Repeat completes):

1. **Text** — `--- RUN END: Current Date ---`
2. **Append to Note** → same note

**Do not add** manual `LoopIndex` / Calculate — use **Repeat Index** (avoids the stuck-at-0 bug from dev testing).

**Send Message:** Show When Run **off** (same as production recommendation).

**Wait:** Match production shortcut initially (do not add extra Wait unless production already has it). Document Wait duration in commit notes so logs are comparable.

**Export:** Sign with `shortcuts sign --mode anyone` → commit to `assets/sent_it_blast_diagnostic.shortcut`.

Document shortcut recipe in `tools/sent_it_blast_diagnostic_setup.md` (for maintainers only — not reporter-facing).

## App changes

### 1. Compile-time TestFlight diagnostics flag

```dart
// lib/constants/diagnostic_constants.dart (or extend subscription_constants)
static const bool blastDiagnosticsEnabled = bool.fromEnvironment(
  'BLAST_DIAGNOSTICS',
  defaultValue: false,
);
static const String diagnosticShortcutName = 'Sent It Blast (Diagnostic)';
static const String diagnosticLogNoteTitle = 'Sent It Blast Log';
```

- **TestFlight CI/archive:** `fvm flutter build ipa --dart-define=BLAST_DIAGNOSTICS=true ...`
- **App Store / local release:** omit define (default `false`)

Do **not** rely on runtime TestFlight detection alone for v1 — compile flag guarantees App Store never launches diagnostic shortcut even if asset is present.

### 2. `ShortcutService` updates

| Behavior | `BLAST_DIAGNOSTICS=false` | `BLAST_DIAGNOSTICS=true` |
|----------|---------------------------|---------------------------|
| `shortcutName` for Blast launch | `Sent It Blast` | `Sent It Blast (Diagnostic)` |
| Install asset | `sent_it_blast.shortcut` | `sent_it_blast_diagnostic.shortcut` |
| `markBlastInstalled` key | existing | separate `_diagnosticInstalledKey` OR shared (either works) |

Add:

- `static bool get isBlastDiagnosticsEnabled` (from constant)
- `static Future<void> openDiagnosticInstallPage()` — load diagnostic asset, share sheet (mirror `openInstallPage`)
- Optional: prepend run metadata to clipboard is **not** possible after handoff — rely on shortcut header line

Keep existing `BLAST_SHORTCUT_NAME` env override for local dev (overrides when set).

### 3. `more_screen.dart` — TestFlight-only UI

When `ShortcutService.isBlastDiagnosticsEnabled`:

- Show second card **below** production shortcut section OR replace production install with diagnostic-only for TestFlight:
  - **Recommended:** Show **only** diagnostic install + copy explaining this is a beta logging build (avoids installing wrong shortcut).
- Title: **Diagnostic Blast (TestFlight)**
- Body: short text — logs to Notes note `Sent It Blast Log`; share with developer after run.
- Button: **Install Diagnostic Blast**
- Link/button: **How to share logs** (alert with 3 steps)

When flag false: unchanged (production shortcut section only).

### 4. `group_message_screen.dart` — Blast confirmation

When diagnostics enabled, append to confirm dialog:

> This TestFlight build logs each send to Notes (“Sent It Blast Log”). After your blast, share that note with us.

No change to gate policy or send button.

### 5. Assets & `pubspec.yaml`

```yaml
assets:
  - assets/sent_it_blast.shortcut
  - assets/sent_it_blast_diagnostic.shortcut  # small; only used when diagnostics enabled
```

Diagnostic asset in repo is fine — inert when flag is false.

## Owner / build workflow

1. Build diagnostic shortcut on Mac (recipe in `tools/sent_it_blast_diagnostic_setup.md`), sign, add to `assets/`.
2. Archive TestFlight IPA:
   ```bash
   fvm flutter build ipa --dart-define=BLAST_DIAGNOSTICS=true --dart-define=RC_IOS_API_KEY=appl_...
   ```
3. Upload via `asc publish testflight` (see `ai-docs/asc.md`).
4. Invite reporter to TestFlight group.
5. Send reporter **one message** (template below).

### Reporter message template

```
You're on a special TestFlight build that logs Blast progress to help us fix large-group sends.

Setup (one time):
1. Open Sent It → More → Install Diagnostic Blast → add to Shortcuts

When reproducing:
1. Blast your group as usual
2. If Shortcuts shows an error, screenshot it
3. Open Notes → "Sent It Blast Log" → Share → send to [your email]

Thanks!
```

## Log format (for analysis)

```
--- RUN START: Jul 28, 2026 at 6:00 PM | Recipients: 200 ---
1,+15551234567,Jul 28, 2026 at 6:00 PM
2,+15559876543,Jul 28, 2026 at 6:00 PM
...
--- RUN END: Jul 28, 2026 at 6:12 PM ---
```

**Parse for:**

- Last **Repeat Index** before RUN END (or before stop) → how far loop got
- Elapsed time (START vs last line vs END)
- Whether END line exists → clean completion vs Shortcut timeout mid-loop
- Compare to reporter’s “took too long” timestamp

## Relevant Files

- `assets/sent_it_blast.shortcut` — production (unchanged behavior)
- `assets/sent_it_blast_diagnostic.shortcut` — **new**, signed diagnostic fork
- `lib/services/shortcut_service.dart` — diagnostics flag, shortcut name routing, install diagnostic
- `lib/screens/more_screen.dart` — TestFlight install UI + share-log instructions
- `lib/screens/group_message_screen.dart` — confirm dialog copy when diagnostics on
- `lib/constants/diagnostic_constants.dart` — **new** (or single constants file)
- `pubspec.yaml` — second asset
- `tools/sent_it_blast_diagnostic_setup.md` — **new**, maintainer shortcut recipe
- `tools/blast-scale-test-playbook.md` — cross-link findings
- `specs/prd-blast-scale-testing.md` — prior research
- `ai-docs/asc.md` — TestFlight upload

## New Files

- `assets/sent_it_blast_diagnostic.shortcut`
- `lib/constants/diagnostic_constants.dart`
- `tools/sent_it_blast_diagnostic_setup.md`
- `tools/testflight-blast-diagnostics-reporter.md` — copy-paste instructions for email to tester

## Step-by-Step Tasks

### 1. Create diagnostic shortcut (maintainer, on Mac)

1. Duplicate production **Sent It Blast** → rename **Sent It Blast (Diagnostic)**.
2. Add RUN START / RUN END Append to Note blocks (note: `Sent It Blast Log`).
3. Inside loop: Text with `Repeat Index`, `number`, `Current Date` → Append to Note.
4. Export → `shortcuts sign` → `assets/sent_it_blast_diagnostic.shortcut`.
5. Document in `tools/sent_it_blast_diagnostic_setup.md`.

### 2. App: diagnostics flag + ShortcutService routing

1. Add `diagnostic_constants.dart` with `BLAST_DIAGNOSTICS` flag and names.
2. `shortcutName` getter: if diagnostics enabled → Diagnostic name; else production (unless `BLAST_SHORTCUT_NAME` override).
3. `openDiagnosticInstallPage()` loading diagnostic asset.
4. Log payload count in diagnostics builds (`debugPrint` — works in profile/TestFlight if needed; optional).

### 3. More screen: TestFlight-only section

1. If `isBlastDiagnosticsEnabled`, show Diagnostic install card + “How to share logs” alert.
2. Hide or de-emphasize production shortcut install on diagnostic builds (tester should only install diagnostic).

### 4. Blast confirm copy

1. When diagnostics enabled, add Notes logging sentence to `_sendViaShortcut` confirm dialog.

### 5. pubspec + reporter doc

1. Register diagnostic asset in `pubspec.yaml`.
2. Add `tools/testflight-blast-diagnostics-reporter.md` with email template.

### 6. Build & ship TestFlight

1. Build IPA with `--dart-define=BLAST_DIAGNOSTICS=true`.
2. Upload to TestFlight; invite reporter.
3. Verify on device: install diagnostic shortcut → small test blast (3 contacts) → note appears in Notes.

## Validation Commands

```bash
fvm flutter analyze
fvm flutter test
# TestFlight build (manual)
fvm flutter build ipa --dart-define=BLAST_DIAGNOSTICS=true --no-codesign  # or full archive
# App Store build must NOT set BLAST_DIAGNOSTICS
fvm flutter build ipa --no-codesign
```

**Manual QA (TestFlight build on physical device):**

- [ ] More shows Diagnostic install only (or clearly primary)
- [ ] Install Diagnostic Blast adds shortcut to library
- [ ] Blast launches **Sent It Blast (Diagnostic)** not production
- [ ] Notes contains `Sent It Blast Log` with RUN START, indexed lines, RUN END (small group)
- [ ] Production-flag build (`BLAST_DIAGNOSTICS` unset): unchanged More + production shortcut

## Notes

### Why compile-time flag vs runtime TestFlight detection

Runtime detection (receipt URL, provisioning profile) is possible but adds native code and edge cases. **Explicit `BLAST_DIAGNOSTICS` on TestFlight archive** is foolproof: App Store release pipeline simply omits the flag.

Future: add Swift `isTestFlight` helper and OR with compile flag if you want single IPA — not needed for v1.

### Privacy

Logs contain **phone numbers** and **message text** (personalized). Reporter must consent when sharing note. Keep TestFlight group small; delete note after analysis.

### If shortcut times out before RUN END

Log will show last Repeat Index and no RUN END line — confirms Shortcuts timeout hypothesis. Ask reporter for Shortcut screenshot of error.

### Relationship to chunking fix

After logs confirm stop index + timeout, separate chore: chunked Blast (e.g. 4×50). Diagnostics chore does not implement chunking.

### Open questions for owner before implement

| # | Question | Default if unanswered |
|---|----------|----------------------|
| 1 | Hide production shortcut install entirely on diagnostic builds? | Yes — diagnostic only |
| 2 | Include app version in RUN START line? | Yes — pass via clipboard prefix or shortcut Text with hardcoded build # in shortcut name metadata; simplest: app writes one-line header to a shared note before blast — **optional v2**; v1 shortcut-only header is enough |
| 3 | Same Wait as production shortcut? | Yes — match production for faithful repro |

## Handoff to Implement

```
/implement specs/chore-blast-testflight-diagnostics.md
```

Build diagnostic shortcut asset first (blocked on signed `.shortcut` file), then app changes, then TestFlight archive with `BLAST_DIAGNOSTICS=true`.
