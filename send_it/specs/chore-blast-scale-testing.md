# Chore: Blast scale testing harness for Sent It

## Description

Add **developer-only tooling** to diagnose why Blast stops around ~200 recipients. A user reported the Shortcut "just stops" at that scale; standard Send works. This chore does **not** fix production Blast — it enables safe reproduction with mock contacts, debug shortcut logging, and a test playbook.

**PRD:** `specs/prd-blast-scale-testing.md`

## Relevant Files

- `lib/services/shortcut_service.dart` — payload builder, debug logging, optional debug shortcut name
- `assets/sent_it_blast.shortcut` — production shortcut (**unchanged**)
- `pubspec.yaml` — no new assets (debug shortcut stays in `tools/`)

## New Files

- `tools/generate_blast_test_contacts.py` — VCF + JSON payload generator
- `tools/blast-scale-test-playbook.md` — test protocol and results matrix
- `tools/sent_it_blast_debug_setup.md` — fork production shortcut with logging
- `tools/README.md` — quick reference
- `tools/fixtures/blast_test_200.vcf` — 200 mock contacts
- `tools/fixtures/payload_200.json` — sample clipboard payload
- `tools/fixtures/payload_200_with_media.json` — payload with mediaFile key
- `test/shortcut_service_test.dart` — unit tests for payload builder

## Step-by-Step Tasks

1. ✅ Add `tools/generate_blast_test_contacts.py` (vcf + payload subcommands)
2. ✅ Generate `tools/fixtures/` VCF and JSON samples
3. ✅ Add `tools/blast-scale-test-playbook.md` and `tools/sent_it_blast_debug_setup.md`
4. ✅ Extract `buildShortcutPayload` in `ShortcutService`; add `kDebugMode` byte-count logging
5. ✅ Add `--dart-define=BLAST_SHORTCUT_NAME` override for debug shortcut launches
6. ✅ Add `test/shortcut_service_test.dart`
7. Manual (post-merge): fork shortcut on device per setup doc; run playbook matrix on physical iPhone

## Validation Commands

```bash
python3 tools/generate_blast_test_contacts.py vcf -o tools/fixtures/blast_test_200.vcf
fvm flutter analyze
fvm flutter test test/shortcut_service_test.dart
```

## Notes

- Debug shortcut **cannot** be generated as signed binary in CI — engineer forks production shortcut on Mac/iPhone per `sent_it_blast_debug_setup.md`.
- Physical device required for Shortcut scale tests (Simulator unreliable).
- Fix implementation is a **follow-up chore** after playbook results identify root cause.
