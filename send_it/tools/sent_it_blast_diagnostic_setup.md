# Sent It Blast (Diagnostic) — Shortcut Setup

Maintainer-only guide for building the **TestFlight diagnostic shortcut**.  
Reporters install it via **More → Install Diagnostic Blast** — they never edit shortcuts manually.

## Prerequisites

- Production **Sent It Blast** installed (from the app or `assets/sent_it_blast.shortcut`)
- Mac with Shortcuts.app (for export/sign) or iPhone (export via Mac Export — not AirDrop)

## 1. Duplicate production shortcut

1. Open **Shortcuts** on Mac or iPhone.
2. Find **Sent It Blast**.
3. Duplicate → rename to **`Sent It Blast (Diagnostic)`** (exact name).

## 2. RUN START (before Repeat with Each)

Add these actions **before** the loop:

| # | Action | Configuration |
|---|--------|---------------|
| 1 | **Count** | Input: Shortcut Input → output `RecipientCount` |
| 2 | **Text** | `--- RUN START: [Current Date] \| Recipients: [RecipientCount] ---` |
| 3 | **Append to Text File** | File: **`Sent_It_Blast.txt`** (creates on first write) |

## 3. Inside Repeat with Each (per recipient)

After extracting `number`, `message`, and optional `mediaFile`, add **after Send Message** (match production Wait placement):

| # | Action | Configuration |
|---|--------|---------------|
| 1 | **Text** | `[Repeat Index],[number],[Current Date]` |
| 2 | **Append to Text File** | File: **`Sent_It_Blast.txt`** |

**Use Repeat Index** (magic variable from the Repeat action). Do **not** use a manual `LoopIndex` variable.

## 4. RUN END (after Repeat with Each)

| # | Action | Configuration |
|---|--------|---------------|
| 1 | **Text** | `--- RUN END: [Current Date] ---` |
| 2 | **Append to Text File** | File: **`Sent_It_Blast.txt`** |

Testers find the log via **Files** app → search **`Sent_It_Blast.txt`**. No pre-setup required.

## 5. Send Message settings

Same as production:

- **Show When Run:** OFF
- Recipients: `number`
- Body: `message`
- Media: Get File from On My iPhone → Sent It → path `mediaFile` (if present)

## 6. Export and sign (Mac)

Export from **Shortcuts.app on Mac** (File → Export). AirDrop from iPhone often fails `shortcuts sign`.

```bash
shortcuts sign --mode anyone \
  --input ~/Desktop/Sent\ It\ Blast\ \(Diagnostic\).shortcut \
  --output assets/sent_it_blast_diagnostic.shortcut
```

## 7. Register in the app

1. Confirm file exists: `assets/sent_it_blast_diagnostic.shortcut`
2. Listed in `pubspec.yaml` under `assets:`
3. Run `fvm flutter pub get`

## 8. Test locally

```bash
fvm flutter run --dart-define=BLAST_DIAGNOSTICS=true
```

1. More → Install Diagnostic Blast
2. Small blast (2–3 contacts)
3. Files → search **`Sent_It_Blast.txt`** → verify RUN START, indexed lines, RUN END

## Log format

```
--- RUN START: Jul 28, 2026 at 6:00 PM | Recipients: 200 ---
1,+15551234567,Jul 28, 2026 at 6:00 PM
2,+15559876543,Jul 28, 2026 at 6:00 PM
...
--- RUN END: Jul 28, 2026 at 6:12 PM ---
```

Missing `RUN END` → Shortcut likely timed out mid-run.

## TestFlight archive

```bash
fvm flutter build ipa --dart-define=BLAST_DIAGNOSTICS=true
```

App Store / production archives: **omit** `BLAST_DIAGNOSTICS` (default `false`).

## Related

- `tools/testflight-blast-diagnostics-reporter.md` — email template for the tester
- `tools/sent_it_blast_debug_setup.md` — dev-only iCloud file logging (not shipped)
- `specs/chore-blast-testflight-diagnostics.md` — full plan
