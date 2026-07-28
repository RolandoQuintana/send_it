# Blast Scale Testing Playbook

Diagnose why **Sent It Blast** stops around ~200 recipients.  
**Goal:** find where the loop breaks — not ship a fix yet.

See also: `specs/prd-blast-scale-testing.md`, `tools/sent_it_blast_debug_setup.md`

## Known reporter context

| Field | Value |
|-------|-------|
| Feature | Blast (Shortcut) — not standard Send |
| Recipients | ~200 (last known failure) |
| Behavior | Shortcut appears to just stop |
| Text vs media | Unknown — test both |

---

## Phase 0 — One-time setup

### Generate mock contacts

```bash
cd send_it
python3 tools/generate_blast_test_contacts.py vcf -o tools/fixtures/blast_test_200.vcf
```

Optional smaller sets:

```bash
python3 tools/generate_blast_test_contacts.py vcf --count 50 -o tools/fixtures/blast_test_50.vcf
```

### Import contacts

1. AirDrop or email `blast_test_200.vcf` to your test iPhone.
2. Tap the file → **Add All Contacts**.
3. In Contacts, create a group **Blast Test** (Mac: Contacts → File → New Group; iOS: use a dedicated list/filter).
4. Add all `Scale### Tester` contacts to that group.

Numbers use **+1-555-01XX** (NANP fictional range) — they do not route to real subscribers.

### Install debug shortcut

Follow **`tools/sent_it_blast_debug_setup.md`**:

1. Duplicate production **Sent It Blast** → rename **Sent It Blast (Debug)**.
2. Add per-iteration logging to `iCloud Drive/BlastTest/log.txt`.
3. Add **Wait** action (start with **1 second**).
4. Turn off **Show When Run** on Send Message.

### Create Sent It test group

1. Open Sent It → create group **Scale Test 200**.
2. Select all mock contacts from **Blast Test** group.

---

## Phase 1 — Device prep (every run)

- [ ] **Auto-Lock → Never** (Settings → Display)
- [ ] **Low Power Mode → Off**
- [ ] Delete or archive previous `iCloud Drive/BlastTest/log.txt`
- [ ] Note **device model** and **iOS version**
- [ ] Keep **Shortcuts** in foreground during the run
- [ ] Debug build with debug shortcut name:

```bash
fvm flutter run --dart-define=BLAST_SHORTCUT_NAME="Sent It Blast (Debug)"
```

Release/TestFlight builds always use production **Sent It Blast**.

---

## Phase 2 — Test matrix

Record results in the table below. Test **text-only first**, then repeat with **one image attachment**.

**Message template:** `Hi {firstname}, scale test.`

| N | Text only | Last log index | Payload bytes (debug log) | Wait (s) | Pass/Fail | Notes |
|---|-----------|----------------|---------------------------|----------|-----------|-------|
| 25 | | | | 1 | | |
| 50 | | | | 1 | | |
| 100 | | | | 1 | | |
| 150 | | | | 1 | | |
| 200 | | | | 1 | | |
| 200 | | | | 0 | | throttle test |
| 200 | | | | 2 | | throttle test |

### Subset testing

For each N, create a group with only the first N mock contacts (`Scale001` … `Scale0NN`), or duplicate the full group and deselect extras in the composer.

### Text-only run

1. Open group (N members).
2. Enter message template.
3. Tap **+** → **Blast** → confirm.
4. Watch Shortcuts — do not background the app.
5. When Shortcut stops (or completes), open `iCloud Drive/BlastTest/log.txt`.
6. Note **last line index** and compare to N.

### Media run

1. Attach **one** image in the composer.
2. Same steps as text-only.
3. Confirm `blast_media.jpg` (or `.png`) appears under **Files → On My iPhone → Sent It** before blasting.

### Shortcut-only run (isolates app handoff)

```bash
python3 tools/generate_blast_test_contacts.py payload --count 200 \
  -o /tmp/payload_200.json
```

1. Copy `/tmp/payload_200.json` contents to clipboard.
2. Run **Sent It Blast (Debug)** from Shortcuts (input = clipboard).
3. Check log file — if this fails at the same index, the bug is in the Shortcut/Messages layer, not the Flutter app.

---

## Phase 3 — Interpret results

| Symptom | Likely layer |
|---------|----------------|
| App dialog: "No Recipients" / "No Message" | App validation |
| App shows "Blast Launched" but Shortcut never opens | URL scheme / Shortcut not installed |
| Shortcut errors immediately on run | Clipboard JSON parse / truncated payload |
| Log stops at index N consistently | Shortcut loop limit, Messages throttle, or memory |
| Log reaches N with Wait=2s but fails at N with Wait=0s | Throttling / rate limit — fix candidate |
| Text passes, media fails at lower N | Media staging or attachment path |
| Shortcut-only fails same as app-launched | Rules out Flutter clipboard handoff |

### Debug console (app)

In debug builds, `ShortcutService` logs:

```
[Blast] payload: <count> recipients, <bytes> UTF-8 bytes, shortcut: Sent It Blast (Debug)
```

---

## Phase 4 — Report template

Copy for each failed run:

```
Date:
Device:
iOS:
Recipient count (N):
Text / Media:
Wait seconds:
Payload bytes (from debug log):
Last log index:
Expected index:
Production or Debug shortcut:
Notes:
```

---

## Fixtures (generated)

Regenerate committed fixtures:

```bash
python3 tools/generate_blast_test_contacts.py vcf -o tools/fixtures/blast_test_200.vcf
python3 tools/generate_blast_test_contacts.py payload --count 200 -o tools/fixtures/payload_200.json
python3 tools/generate_blast_test_contacts.py payload --count 200 --media \
  -o tools/fixtures/payload_200_with_media.json
```

---

## Out of scope (this chore)

- Changing production `assets/sent_it_blast.shortcut`
- User-facing recipient caps or warnings
- App-side chunking across multiple Shortcut launches

Fix implementation follows once root cause is confirmed.
