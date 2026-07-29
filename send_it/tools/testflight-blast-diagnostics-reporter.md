# TestFlight Blast Diagnostics — Reporter Instructions

Copy-paste for the beta tester (replace `[your email]`).

---

**Subject:** Sent It TestFlight — help us fix large-group Blast

You're on a special TestFlight build that logs Blast progress so we can see where large sends stop.

### One-time setup

1. Install the TestFlight build
2. Open **Sent It → More → Install Diagnostic Blast**
3. Tap the Shortcuts icon on the share sheet to add it

No other setup — the log file is created automatically on your first blast.

### When reproducing the issue

1. Compose your message and blast your group as you normally would
2. If Shortcuts shows an error, **screenshot it**
3. Open the **Files** app and search for **`Sent_It_Blast.txt`**
4. Long-press the file → **Share** → send to **[your email]**

### Privacy note

The log includes phone numbers and message text from your blast. We'll only use it to debug this issue and delete it afterward.

Thanks!

---

## Owner checklist before sending invite

- [ ] `assets/sent_it_blast_diagnostic.shortcut` created and in `pubspec.yaml`
- [ ] IPA built with `--dart-define=BLAST_DIAGNOSTICS=true`
- [ ] You verified install + small test blast on a device
- [ ] TestFlight build uploaded and tester invited
