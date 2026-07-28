# Chore: Enable 3-day free trial on Sent It Pro annual subscription

## Description

Add a **3-day free introductory trial** on the annual subscription (`sent_it_annual`) so new users can try Sent It Pro before committing. This is primarily **App Store Connect + RevenueCat dashboard** work — Apple applies the trial at purchase, RevenueCat grants the `pro` entitlement during the trial, and the existing `SubscriptionService.hasPro` gate already unlocks the app.

**Why:** The paywall v1 design already uses trial-oriented CTA copy ("Start 3-Day Free Trial & Continue"), but production has no ASC introductory offer (`introductoryOffers: []` on subscription `6794926795` as of 2026-07-27). Shipping trial copy without the store offer is misleading. The only required app code change is **trial-aware status on the More screen** (FR-12).

**Supersedes:** `specs/prd-subscription-and-lifetime.md` FR-11 ("No free trial in v1"). See `specs/prd-free-trial.md` for full product context.

**Current state (research snapshot):**

| Layer | Status |
|-------|--------|
| ASC intro offer on `sent_it_annual` | ❌ Empty (`asc subscriptions offers introductory list --subscription-id 6794926795`) |
| `ios/SentItProducts.storekit` | ✅ 3-day free trial on annual (`P3D`, `paymentMode: free`) |
| RC product `sent_it_annual` | ❌ `trial_duration: null` (will sync after ASC) |
| RC paywall v1 (`pwa4f358491d9044ab`) | ⚠️ Copy references trial; needs eligibility-aware templates |
| `SubscriptionGate` / `hasPro` | ✅ No changes needed |
| `more_screen.dart` trial status | ❌ Shows "Pro subscriber" for all entitlements |
| `termsOfUseUrl` | ✅ Interim Apple EULA in `subscription_constants.dart` |

## Relevant Files

- `specs/prd-free-trial.md` — product requirements, acceptance criteria, QA flows
- `specs/chore-update-paywall-v1.md` — paywall v1 layout/copy; trial CTA dependency (overlap — do not re-publish paywall unless eligibility templates are missing)
- `specs/prd-subscription-and-lifetime.md` — base subscription model (grandfathering, gate policy)
- `ai-docs/revenuecat.md` — RC patterns, paywall IDs, testing channels (update with trial section)
- `ai-docs/asc.md` — ASC app `6746167372`, CLI auth, subscription commands
- `ios/SentItProducts.storekit` — local 3-day annual intro offer (verify matches ASC; no change expected)
- `lib/widgets/subscription_gate.dart` — `PaywallView` gate (`displayCloseButton: false`) — **do not modify**
- `lib/services/subscription_service.dart` — add trial-aware status helper for More screen
- `lib/screens/more_screen.dart` — use status helper for trial label
- `lib/constants/subscription_constants.dart` — legal URLs (no change expected)
- `test/subscription_service_test.dart` — add unit tests for status label helper

## New Files

None expected.

## Step-by-Step Tasks

### 1. Create ASC introductory offer on `sent_it_annual`

Subscription internal ID: `6794926795`. App ID: `6746167372`. Product ID: `sent_it_annual`.

1. Dry-run first:
   ```bash
   asc subscriptions offers introductory create \
     --subscription-id 6794926795 \
     --offer-duration THREE_DAYS \
     --offer-mode FREE_TRIAL \
     --number-of-periods 1 \
     --all-territories \
     --dry-run
   ```
2. Create for all territories:
   ```bash
   asc subscriptions offers introductory create \
     --subscription-id 6794926795 \
     --offer-duration THREE_DAYS \
     --offer-mode FREE_TRIAL \
     --number-of-periods 1 \
     --all-territories
   ```
3. Verify:
   ```bash
   asc subscriptions offers introductory list --subscription-id 6794926795 --output table
   ```
4. Confirm monthly (`6794926872`) still has **no** introductory offer.

**Alternative:** ASC dashboard → Subscriptions → Sent It Pro Annual → Introductory Offers → Free, 3 days, new subscribers.

### 2. Verify StoreKit config matches ASC

1. Open `ios/SentItProducts.storekit` — annual (`sent_it_annual`, internalID `6794926795`) should have:
   ```json
   "introductoryOffer": {
     "paymentMode": "free",
     "subscriptionPeriod": "P3D",
     "numberOfPeriods": 1
   }
   ```
2. Monthly must remain `"introductoryOffer": null`.
3. Confirm Xcode scheme `Runner.xcscheme` references `SentItProducts.storekit` (for local simulator QA without ASC propagation delay).
4. Only edit StoreKit file if ASC offer duration/mode differs from `P3D` free trial.

### 3. Wait for RevenueCat product sync and verify

ASC changes can take up to 24h to propagate. Poll until `trial_duration` is non-null.

1. RevenueCat MCP: `get-product` for `sent_it_annual` in project `projba51c129`.
2. Confirm `trial_duration` reflects 3 days (or equivalent) after sync.
3. If still null after 24h, check RC app settings → App Store Connect API key (.p8) is configured and trigger manual product import in RC dashboard.

### 4. Sandbox QA — trial purchase flow (before paywall publish)

Use a **fresh sandbox Apple ID** (one intro offer per subscription group per Apple ID). Debug builds use RC Test Store key — for real intro-offer behavior, test with **release/profile build + App Store key** or **Xcode + StoreKit config file**.

**StoreKit file path (fastest):**
1. Run from Xcode with `SentItProducts.storekit` attached.
2. Non-pro user sees paywall → select annual → Apple sheet shows 3-day free trial.
3. Complete purchase → app unlocks immediately.
4. More screen shows trial status (after step 6).

**Sandbox Apple ID path (pre-release validation):**
1. TestFlight or release build with `appl_...` key.
2. Fresh sandbox account → trial purchase → verify `pro` entitlement active.
3. Verify `CustomerInfo` entitlement `periodType` is `trial`.

**Do not proceed to paywall publish until sandbox confirms intro offer is live.**

### 5. Update RC paywall v1 — eligibility-aware trial CTA

Paywall: **Sent It Paywall: v1** — `pwa4f358491d9044ab`. Project: `projba51c129`. Offering: `default` — `ofrngd93b6b0c31`.

1. `get-paywall` with `expand: ["components"]` — inspect current CTA and whether intro-offer eligibility templates are already present from `chore-update-paywall-v1.md` work.
2. If CTA is static trial copy or missing eligibility fallback, run `edit-paywall-ai` on `pwa4f358491d9044ab`:

   **Edit prompt (add to MCP `prompt`):**
   > Update the primary CTA on "Sent It Paywall: v1" to be **intro-offer eligibility aware** for the annual package (`$rc_annual`):
   > - **Eligible users:** "Start 3-Day Free Trial & Continue" — use RC intro-offer template variables (`{{ product.offer_period_with_unit }}`, `{{ product.offer_price }}`) for package terms.
   > - **Ineligible users:** "Unlock Unlimited Messaging" — no trial language.
   > - Monthly and lifetime packages: standard pricing only, no trial terms.
   > - Keep existing headline, bullets, annual-default layout, trust line, social proof, and footer legal URLs.
   > - Footer: Privacy Policy `https://www.termsfeed.com/live/707a5825-ae79-4e86-9ddc-edeeaeba78a9`, Terms `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
   > - Do not add a close (X) button — full-app gate.

3. Poll `get-paywall-ai-task` every 10–15s until complete.
4. `render-paywall-screenshot` for visual QA — confirm eligible vs ineligible CTA states if screenshot tool supports it; otherwise verify component config in `get-paywall` response.
5. **Publish only with explicit user approval** after sandbox QA passes:
   ```text
   publish-paywall on pwa4f358491d9044ab
   ```
6. Record `edit-paywall-ai` task ID and revision in commit/PR notes.

**FR-13:** Do not publish trial CTA until ASC intro offer is verified in sandbox (step 4).

### 6. App code — trial status on More screen

Add a **testable static helper** on `SubscriptionService` (mirrors `isGrandfatheredFromReceipt` pattern) and use it in `more_screen.dart`. No custom trial timers; read from RevenueCat `EntitlementInfo` only.

1. In `lib/services/subscription_service.dart`, add:

   ```dart
   /// Human-readable Pro status for More screen.
   @visibleForTesting
   static String proStatusLabel({
     required ProAccessSource accessSource,
     EntitlementInfo? proEntitlement,
   }) {
     switch (accessSource) {
       case ProAccessSource.grandfathered:
         return 'Lifetime access (original purchase)';
       case ProAccessSource.none:
         return 'Not subscribed';
       case ProAccessSource.entitlement:
         if (proEntitlement == null) return 'Pro subscriber';
         if (proEntitlement.periodType == PeriodType.trial) {
           final end = _formatExpirationDate(proEntitlement.expirationDate);
           return end != null ? 'Free trial — ends $end' : 'Free trial';
         }
         if (proEntitlement.productIdentifier.contains('lifetime')) {
           return 'Lifetime Pro';
         }
         return 'Pro subscriber';
     }
   }
   ```

   Add private `_formatExpirationDate(String? iso)` — parse ISO8601 `expirationDate`, format as locale-friendly short date (e.g. `Jan 30, 2026`). Use `intl` if already in `pubspec.yaml`; otherwise simple `DateTime` formatting to avoid new dependencies.

2. Add instance getter or thin wrapper:
   ```dart
   String get proStatusLabel => SubscriptionService.proStatusLabel(
     accessSource: accessSource,
     proEntitlement: _customerInfo?.entitlements.active[SubscriptionConstants.entitlementId],
   );
   ```

3. In `lib/screens/more_screen.dart`, replace `_proStatusLabel()` body with `_subscription.proStatusLabel` (or call static helper with service state). Remove duplicated switch logic.

4. **Do not change** `subscription_gate.dart` — gate policy stays `displayCloseButton: false`; trial users unlock via existing `hasPro` check.

### 7. Unit tests for trial status label

In `test/subscription_service_test.dart`, add `group('proStatusLabel', ...)`:

1. `grandfathered` → `'Lifetime access (original purchase)'`
2. `none` → `'Not subscribed'`
3. `entitlement` + `periodType: TRIAL` + `expirationDate` → `'Free trial — ends <formatted date>'`
4. `entitlement` + `periodType: TRIAL` + null expiration → `'Free trial'`
5. `entitlement` + `periodType: NORMAL` + `productIdentifier: sent_it_annual` → `'Pro subscriber'`
6. `entitlement` + lifetime product ID → `'Lifetime Pro'`

Build `EntitlementInfo` via `EntitlementInfo.fromJson` (see purchases_flutter test fixtures for required fields).

### 8. Update `ai-docs/revenuecat.md`

Add a **Free trial** subsection under Configuration (or extend "Paywall copy (v1)"):

- 3-day free intro offer on `sent_it_annual` only (ASC Introductory Offer, `THREE_DAYS` / `FREE_TRIAL`)
- Monthly and lifetime have no trial
- Trial users get active `pro` entitlement — no app-side trial mode
- Paywall uses eligibility-aware CTA; fallback for ineligible users
- More screen: `periodType == trial` → "Free trial — ends [date]"
- Testing: StoreKit file for local; fresh sandbox Apple ID for ASC; Test Store key does **not** reflect real intro offers
- Publish paywall trial CTA only after ASC offer verified
- Link to `specs/prd-free-trial.md`

### 9. End-to-end manual QA checklist

Run after steps 1–8. Document results in PR/commit.

| Scenario | Expected |
|----------|----------|
| Fresh sandbox / StoreKit user, annual selected | CTA shows trial copy; payment sheet shows 3-day free trial |
| Trial purchase completes | App unlocks; More shows "Free trial — ends [date]" |
| Ineligible user (prior trial consumed) | Fallback CTA "Unlock Unlimited Messaging"; no trial in payment sheet |
| Monthly selected | No trial terms on package or CTA |
| Grandfathered user | Bypasses paywall entirely |
| Restore on paywall / More | Works for trial and paid states |
| Cancel trial in App Store settings | Access ends at trial expiration; paywall returns |
| Footer links | Privacy Policy + Terms URLs open correctly |

## Validation Commands

Run all commands after implementation. All must pass.

- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter build ios --no-codesign` (app code changes in step 6–7)

**Manual (required — store/dashboard work not covered by unit tests):**

```bash
asc subscriptions offers introductory list --subscription-id 6794926795 --output table
```

- RevenueCat `get-product` shows non-null trial on `sent_it_annual`
- Sandbox or StoreKit: trial purchase → `pro` entitlement → app unlock
- `render-paywall-screenshot` matches approved eligible/ineligible CTA behavior (after publish)

## Notes

### Scope boundaries

- **In scope:** ASC intro offer, RC paywall eligibility CTA, More screen trial status, docs, tests.
- **Out of scope:** Custom app-side trial timers, monthly/lifetime trials, push reminders, promotional offers, Android, changing paywall dismiss policy, `subscription_gate.dart` changes.

### Relationship to `chore-update-paywall-v1.md`

That chore covers full paywall redesign (headline, layout, legal URLs). If paywall v1 is already published with trial CTA but **without** eligibility templates, step 5 adds only the eligibility-aware CTA fix. Do not re-run full redesign unless components are missing.

### Terms of Use blocker (open)

Owner will create TermsFeed EULA before App Review. Interim Apple standard EULA (`termsOfUseUrl` in `subscription_constants.dart`) is acceptable for paywall footer until then.

### Test Store vs App Store key

`subscription_constants.dart` uses `test_...` key in debug. Introductory offers require **App Store key** (`appl_...`) or **StoreKit config file** for accurate QA. Do not rely on Test Store alone before release.

### Propagation delay

Allow up to 24h after ASC create before production/TestFlight QA. Use StoreKit file for immediate local dev.

### Grandfathered users

Existing `isGrandfatheredFromReceipt` + cached flag runs before paywall. Regression-test that grandfathered users never see trial flow.

### RC MCP reference IDs

| Item | ID |
|------|-----|
| Project | `projba51c129` |
| Paywall v1 | `pwa4f358491d9044ab` |
| Offering default | `ofrngd93b6b0c31` |
| ASC app | `6746167372` |
| Annual subscription | `6794926795` (`sent_it_annual`) |
| Monthly subscription | `6794926872` (`sent_it_monthly`) |

### Conditional docs loaded

Per `conditional-docs.md`: `ai-docs/revenuecat.md`, `ai-docs/asc.md`, `CLAUDE.md` validation commands.
