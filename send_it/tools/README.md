# Blast scale testing tools

Developer-only harness for diagnosing large-group Blast failures.  
**Not shipped in the app.**

| File | Purpose |
|------|---------|
| `generate_blast_test_contacts.py` | Generate mock VCF contacts and JSON payloads |
| `blast-scale-test-playbook.md` | Step-by-step test protocol and results matrix |
| `sent_it_blast_debug_setup.md` | Fork production shortcut with loop logging (dev) |
| `sent_it_blast_diagnostic_setup.md` | Build TestFlight diagnostic shortcut (Notes logging) |
| `testflight-blast-diagnostics-reporter.md` | Email template for beta tester |
| `fixtures/` | Pre-generated 200-contact VCF and sample payloads |

## Quick start

```bash
# Regenerate fixtures
python3 tools/generate_blast_test_contacts.py vcf -o tools/fixtures/blast_test_200.vcf
python3 tools/generate_blast_test_contacts.py payload --count 200 -o tools/fixtures/payload_200.json

# Run app with debug shortcut (after installing Sent It Blast (Debug))
fvm flutter run --dart-define=BLAST_SHORTCUT_NAME="Sent It Blast (Debug)"

# TestFlight diagnostic build (after adding assets/sent_it_blast_diagnostic.shortcut)
fvm flutter run --dart-define=BLAST_DIAGNOSTICS=true
```

See `blast-scale-test-playbook.md` for the full workflow.
