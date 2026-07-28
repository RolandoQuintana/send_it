# Sent It Blast (Debug) — Shortcut Setup

Fork of production **Sent It Blast** with loop logging and configurable Wait.  
**Not shipped in the app** — install manually from Shortcuts.app on your test device.

## Prerequisites

- Production **Sent It Blast** already installed (More → Install Shortcut in the app)
- iCloud Drive enabled (for crash-surviving log file)

## 1. Duplicate production shortcut

1. Open **Shortcuts** on Mac or iPhone.
2. Find **Sent It Blast**.
3. Long-press → **Duplicate**.
4. Rename to **`Sent It Blast (Debug)`** (exact name — used by debug launch flag below).

## 2. Add logging variables (top of shortcut)

Before the **Repeat with Each** loop, add:

| Action | Value |
|--------|-------|
| **Text** | `BlastTest/log.txt` |
| **Set Variable** | `LogPath` |
| **Text** | `0` |
| **Set Variable** | `LoopIndex` |

Create the log folder once (run manually or add as first actions):

| Action | Value |
|--------|-------|
| **Get File** → iCloud Drive | (root) |
| **Create Folder** | Name: `BlastTest` (if not exists — skip if already created) |

## 3. Inside Repeat with Each (per recipient)

After extracting `number`, `message`, and optional `mediaFile` from the current dictionary item, add **before** Send Message:

### 3a. Increment index

| Action | Value |
|--------|-------|
| **Calculate** | `LoopIndex + 1` |
| **Set Variable** | `LoopIndex` |

### 3b. Append log line

| Action | Value |
|--------|-------|
| **Text** | `{LoopIndex},{number},{Current Date}` (use "Current Date" magic variable formatted as ISO 8601 if available, else custom format) |
| **Get File** from iCloud Drive at path `BlastTest/log.txt` | (create empty file first if missing) |
| **Combine Text** | existing file contents + newline + log line |
| **Save File** | overwrite `BlastTest/log.txt` on iCloud Drive |

**Simpler alternative:** use **Append to Text File** if your iOS version exposes it, targeting `BlastTest/log.txt` on iCloud Drive.

### 3c. Configurable Wait

| Action | Value |
|--------|-------|
| **Number** | `1` (change to `0` or `2` when testing throttle hypothesis) |
| **Set Variable** | `WaitSeconds` |
| **Wait** | `WaitSeconds` seconds |

Place **Wait after Send Message** (not before) so the log records attempts even if Send Message hangs.

## 4. Send Message settings

- **Show When Run:** OFF (tap the action → Show When Run → disable)
- Recipients: `number` variable
- Message body: `message` variable
- If `mediaFile` exists: attach via **Get File** from `On My iPhone` → `Sent It` → path `mediaFile` (same as production)

## 5. Export (optional, for repo backup)

On Mac:

```bash
# Export unsigned from Shortcuts, then sign for sharing:
shortcuts sign --mode anyone \
  --input ~/Desktop/Sent\ It\ Blast\ \(Debug\).shortcut \
  --output tools/sent_it_blast_debug.shortcut
```

Commit `tools/sent_it_blast_debug.shortcut` only after signing — keep it **out of** `pubspec.yaml`.

## 6. Clear log between runs

Delete `iCloud Drive/BlastTest/log.txt` before each test run, or note the last line of the previous run.

## 7. Launch debug shortcut from the app (debug builds only)

```bash
fvm flutter run --dart-define=BLAST_SHORTCUT_NAME="Sent It Blast (Debug)"
```

Production shortcut name is unchanged in release builds.

## Shortcut-only test (no app)

1. Generate payload: `python tools/generate_blast_test_contacts.py payload --count 200 -o /tmp/payload.json`
2. Copy file contents to clipboard (or use **Get File** as shortcut input).
3. Run **Sent It Blast (Debug)** from Shortcuts with input = clipboard.
4. Inspect `iCloud Drive/BlastTest/log.txt` for last index.
