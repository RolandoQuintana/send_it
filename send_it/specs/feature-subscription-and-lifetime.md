# Feature: Subscription and Lifetime IAP

## Description

Integrate RevenueCat (`purchases_flutter` + `purchases_ui_flutter`) to gate the entire Sent It app behind a `pro` entitlement. Offer monthly ($1.99), annual ($9.99), and lifetime ($19.99) via RC remote paywall. Grandfather pre-release paid-download buyers via `originalPurchaseDate`.

## User Story

As a user, I want to subscribe or buy lifetime access so that I can use Sent It after the app becomes free to download.

## Problem / Solution

**Problem:** Sent It is a paid download with no IAP SDK, no gating, and no path to recurring revenue.

**Solution:** RevenueCat remote paywall + full app gate + grandfathering for legacy paid buyers.

## Relevant Files

- `lib/main.dart` — SDK configure at launch, subscription gate wrapper
- `lib/screens/more_screen.dart` — restore, manage subscription, pro status
- `lib/services/subscription_service.dart` — entitlement + grandfather logic
- `lib/widgets/subscription_gate.dart` — PaywallView full-app gate
- `pubspec.yaml` — RC dependencies
- `ios/Podfile` — iOS 15+ minimum

## New Files

- `lib/constants/subscription_constants.dart` — entitlement ID, API key, cutoff
- `lib/services/subscription_service.dart`
- `lib/widgets/subscription_gate.dart`
- `test/subscription_service_test.dart`

## Implementation Plan

### Foundation
1. Add `purchases_flutter` + `purchases_ui_flutter`; bump iOS to 15.0
2. Create RevenueCat project (com.sent.it), products, `pro` entitlement, default offering, paywall

### Core
3. `SubscriptionService` — configure, `hasPro`, listener, restore, grandfather cache
4. `SubscriptionGate` — `PaywallView` for non-pro users

### Integration
5. Wire `main.dart`; restore on paywall + More screen only
6. More screen — restore, manage subscription, privacy policy, pro badge

### Polish
7. Unit tests for grandfather logic; validate analyze/test/build

## Step-by-Step Tasks

1. Add RC packages and iOS 15 Podfile/deployment target
2. Bootstrap RevenueCat dashboard (project, app, products, entitlement, offering, paywall)
3. Implement `SubscriptionService` with `originalPurchaseDate` grandfathering
4. Implement `SubscriptionGate` with `PaywallView` (no close button)
5. Update More screen with restore + manage subscription
7. Run `fvm flutter analyze`, `fvm flutter test`, `fvm flutter build ios --no-codesign`

## Testing

- Unit tests for: `isGrandfatheredFromReceipt` cutoff logic
- E2E test: Sandbox purchase monthly/annual/lifetime → app unlocks; restore on new device; grandfather restore for pre-cutoff receipt

## Validation Commands

- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter build ios --no-codesign`

## Acceptance Criteria

- [ ] Non-pro user sees RC remote paywall on launch (full app gate)
- [ ] Sandbox purchase unlocks app immediately
- [ ] Restore purchases works from paywall and More screen
- [ ] Pre-cutoff paid-download buyer grandfathered after restore
- [ ] Post-release free downloader sees paywall
- [ ] `fvm flutter analyze` and `fvm flutter test` pass

## Notes

- RevenueCat MCP was unavailable during implementation — configure dashboard manually
- API key: `--dart-define=RC_IOS_API_KEY=appl_...`
- Grandfather cutoff at release: `--dart-define=GRANDFATHER_CUTOFF_ISO=...`
- Terms of Use (EULA) still needed before App Review
- Enable In-App Purchase capability in Xcode before submission
