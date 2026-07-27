# App Store Connect CLI (`asc`)

> Scriptable CLI for the App Store Connect API. Read when automating TestFlight, builds, App Store submissions, ASC-side IAP/subscriptions, signing, or release status for Quintana Labs iOS apps.

## Official Resources

- Repo / quick start: https://github.com/rorkai/App-Store-Connect-CLI#quick-start
- Install script: https://asccli.sh/install
- API keys: https://appstoreconnect.apple.com/access/integrations/api
- Agent skills: `asc install-skills` or https://github.com/rorkai/app-store-connect-cli-skills

## Stack Context

- **Flutter** (FVM: `fvm flutter`), **iOS-focused** release tooling on macOS
- Auth is **team-level** (one login covers all apps on the Apple Developer account)
- Target apps with `--app <APP_STORE_CONNECT_APP_ID>` — not per-app auth
- For in-app purchase **SDK** work, also read `ai-docs/revenuecat.md`

### Quintana Labs LLC apps

| App | ASC App ID | Bundle ID |
|-----|------------|-----------|
| Sent It | `6746167372` | `com.sent.it` |
| Scrolless | `6741134096` | `com.feed.freed` |
| Gravity | `6759228965` | `com.gravity.timer` |

Active auth profile on dev machine: **Quintana Labs LLC** (stored in system keychain).

## Setup

### Install

```bash
brew install asc
# or: curl -fsSL https://asccli.sh/install | bash
asc version
```

### Authenticate (one-time per Apple account)

Generate an API key at App Store Connect → Users and Access → Integrations → API.

```bash
# Restrict .p8 permissions first (required)
chmod 600 /path/to/AuthKey_XXXXXXXXXX.p8

asc auth login \
  --name "Quintana Labs LLC" \
  --key-id "KEY_ID" \
  --issuer-id "ISSUER_ID" \
  --private-key /path/to/AuthKey_XXXXXXXXXX.p8 \
  --network
```

- `--name` = profile label (team/account name, not an app name)
- `--network` validates credentials immediately
- Credentials land in **system keychain** by default; key material is copied so the `.p8` file can be moved afterward

### Validate

```bash
asc auth status --validate
asc auth doctor
asc apps list --output table
```

### Multiple Apple accounts

```bash
asc auth login --name "Other Account" --key-id "..." --issuer-id "..." --private-key /path/to/key.p8
asc auth switch --name "Quintana Labs LLC"
```

## Core Patterns

### Discover apps and builds

```bash
asc apps list --output table
asc builds list --app "6746167372" --output table
asc versions list --app "6746167372" --output table
```

### TestFlight

```bash
asc testflight groups list --app "6746167372" --output table
asc publish testflight --app "6746167372" --ipa /path/to/app.ipa --group "Internal Testers" --wait
```

Add `--submit --confirm` for external groups that need beta app review.

### Flutter → IPA → upload

Typical local flow before `asc`:

```bash
cd send_it
fvm flutter build ipa --release
# IPA usually at: build/ios/ipa/*.ipa
asc builds upload --app "6746167372" --ipa build/ios/ipa/*.ipa --wait
```

Or high-level publish:

```bash
asc publish appstore --app "6746167372" --ipa /path/to/app.ipa --version "1.2.3" --submit --confirm
```

### Release status and review

```bash
asc status --app "6746167372" --watch
asc review status --app "6746167372"
asc review doctor --app "6746167372"
asc validate --app "6746167372" --version "1.2.3"
```

### ASC-side IAP / subscriptions

Use when creating or inspecting products in App Store Connect (complements RevenueCat dashboard work):

```bash
asc iap list --app "6746167372" --output table
asc subscriptions list --app "6746167372" --output table
```

Sent It product IDs (also in `ai-docs/revenuecat.md`): `sent_it_monthly`, `sent_it_annual`, `sent_it_lifetime`.

### Output format

- Interactive terminal → `table` by default
- Pipes / CI → `json` by default
- Override: `--output json --pretty`

## Configuration

| Item | Where | Notes |
|------|-------|-------|
| API Key ID | ASC Integrations | e.g. `BQ892GDL48` — not secret |
| Issuer ID | ASC Integrations page | UUID at top — do not commit |
| `.p8` private key | Local filesystem or keychain | Never commit; `chmod 600` required |
| Auth profile name | `asc auth login --name` | Friendly label, e.g. team name |
| App ID | `asc apps list` | Use with `--app` on commands |

### CI / headless

```bash
asc auth login --bypass-keychain --name "CI" \
  --key-id "..." --issuer-id "..." --private-key /path/to/key.p8
# or env-based auth — see `asc auth login --help`
```

Repo-local credentials (add `.asc/` to `.gitignore`):

```bash
asc auth login --bypass-keychain --local --name "..." ...
```

## Testing / Sandbox

- `asc auth status --validate` — smoke test API access
- `asc apps list` — confirms key has correct team scope
- TestFlight uploads use Apple's processing pipeline; check `asc builds list --app ...` for processing state
- Sandbox IAP testing is device-side; ASC CLI manages catalog/metadata, not purchase simulation

## Common Pitfalls

- **Private key too permissive** → `chmod 600 AuthKey_*.p8` before `auth login`
- **Naming profile after an app** → profile is per Apple account/team; use team name
- **Re-auth per app** → unnecessary; same credentials work for all team apps via `--app`
- **Confusing bundle ID with app ID** → `--app` expects ASC numeric app ID from `asc apps list`
- **RevenueCat vs ASC** → RC handles SDK/entitlements; `asc` handles builds, TestFlight, ASC product catalog, submissions
- **Keychain blocked in CI** → use `--bypass-keychain` or `ASC_BYPASS_KEYCHAIN=1`
- **Telemetry** → disable with `asc telemetry disable` or `ASC_TELEMETRY_DISABLED=1` if desired

## Related

- `ai-docs/revenuecat.md` — in-app subscriptions, paywalls, entitlements
- `specs/prd-subscription-and-lifetime.md` — Sent It subscription requirements
- `ios/` — Xcode project, signing, capabilities (IAP, etc.)
