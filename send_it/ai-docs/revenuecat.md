# RevenueCat

> IAP/subscription backend + Flutter SDK for Sent It. Read when implementing paywalls, entitlements, purchases, grandfathering, or RevenueCat dashboard setup.

## Official Resources

- Docs index: https://www.revenuecat.com/docs/llms.txt
- Flutter install: https://www.revenuecat.com/docs/getting-started/installation/flutter
- Paywalls: https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls
- Dashboard: https://app.revenuecat.com
- Flutter SDK releases: https://github.com/RevenueCat/purchases-flutter/releases

## Stack Context

- **Flutter** (FVM: `fvm flutter`), **iOS-only v1** (`com.sent.it`)
- Packages: `purchases_flutter` + `purchases_ui_flutter` (remote paywalls)
- **No existing RC project** — bootstrap via MCP or dashboard
- PRD: `specs/prd-subscription-and-lifetime.md`

### Sent It product model

| Item | Value |
|------|-------|
| Entitlement | `pro` |
| Monthly sub | `sent_it_monthly` — $1.99 |
| Annual sub | `sent_it_annual` — $9.99 |
| Lifetime (non-consumable) | `sent_it_lifetime` — $19.99 |
| Offering | `default` with `$rc_monthly`, `$rc_annual`, `$rc_lifetime` |
| Paywall | RC remote paywall on dashboard (edit layout/prices without app update) |
| Paywall name | **Sent It Paywall: v1** (`pwa4f358491d9044ab`) |
| Access | Full app gate — `hasPro` required to use app |
| Grandfather | Paid-download buyers before freemium release via `originalPurchaseDate` |

## Setup

### pubspec.yaml

```yaml
dependencies:
  purchases_flutter: ^<latest from GitHub releases>
  purchases_ui_flutter: ^<same version>
```

```bash
fvm flutter pub get
cd ios && pod install && cd ..
```

### iOS requirements

- `ios/Podfile`: `platform :ios, '15.0'` (required for `purchases_ui_flutter`)
- Xcode: **In-App Purchase** capability enabled
- Public RC SDK key is in `lib/constants/subscription_constants.dart` (`appl_...` — safe in client code). Override with `--dart-define=RC_IOS_API_KEY=...` if needed.

### Configure at launch (`lib/main.dart`)

```dart
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    await Purchases.setLogLevel(LogLevel.debug); // release: LogLevel.info or off
    await Purchases.configure(
      PurchasesConfiguration(
        SubscriptionConstants.iosApiKey,
      ),
    );
  }
  runApp(const SendItApp());
}
```

Log banner on success: `[Purchases] - INFO: 😻‍👼 Purchases is configured`

## Core Patterns

### Entitlement gate (source of truth)

Check **entitlement ID**, not product ID:

```dart
Future<bool> hasPro(CustomerInfo info) =>
    info.entitlements.active.containsKey('pro');
```

Reactive updates — register once, remove on dispose:

```dart
Purchases.addCustomerInfoUpdateListener((info) { /* update state */ });
// Purchases.removeCustomerInfoUpdateListener(listener);
```

Sent It also checks cached `isGrandfatheredPaidBuyer` (see Grandfathering).

### Remote paywall (preferred for Sent It)

Do **not** call `Purchases.purchasePackage` alongside RC paywall — paywall handles purchase internally.

**Full-app gate** — embed paywall as root for non-pro users:

```dart
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

// Option A: declarative (good for launch gate)
PaywallView(
  displayCloseButton: false, // v1: no dismiss without purchase/restore
  onPurchaseCompleted: (info, _) => _onAccessGranted(info),
  onRestoreCompleted: (info) => _onAccessGranted(info),
  onDismiss: () {},
)

// Option B: imperative
final result = await RevenueCatUI.presentPaywallIfNeeded('pro');
// PaywallResult.purchased | restored | cancelled | error | notPresented
```

Attach a paywall template to the `default` offering in the RC dashboard. Fallback layout = no paywall configured.

### Restore purchases

Required by Apple. Expose on paywall (built-in) and More screen:

```dart
final info = await Purchases.restorePurchases();
```

User-cancelled purchase: `PurchasesErrorCode.purchaseCancelledError` — no error alert.

### Grandfathering (paid app → freemium)

Not an RC product — uses App Store receipt metadata on `CustomerInfo`:

```dart
bool isGrandfathered(CustomerInfo info, DateTime cutoffUtc) {
  final dateStr = info.originalPurchaseDate; // ISO8601
  if (dateStr == null) return false;
  return DateTime.parse(dateStr).isBefore(cutoffUtc);
}
```

Prefer `originalPurchaseDate` over `originalApplicationVersion` (iOS returns **build number**, unreliable).

Migration flow: first launch → "Restore Access" → `restorePurchases()` → check date → cache flag locally. Record ASC price-change timestamp as cutoff at release.

## Configuration

| Key | Where | Notes |
|-----|-------|-------|
| `RC_IOS_API_KEY` | `subscription_constants.dart` | Public SDK key `appl_...`; optional `--dart-define` override |
| Entitlement `pro` | RC dashboard | All products attach here |
| Product IDs | ASC + RC | `sent_it_monthly`, `sent_it_annual`, `sent_it_lifetime` |
| Paywall design | RC Paywalls UI | Remote — no app redeploy for copy/layout |
| ASC In-App Purchase key (.p8) | RC app settings | StoreKit 2 server notifications |
| Grandfather cutoff | App constant | Set at release from ASC price-change time |

**Price changes:** Update in App Store Connect; RC syncs. Paywall highlighting/order in RC dashboard.

### Paywall copy (v1)

Remote paywall **Sent It Paywall: v1** (`pwa4f358491d9044ab`) on offering `default`. Layout/copy changes are **remote** — no app redeploy after `publish-paywall`.

| Element | Copy |
|---------|------|
| Headline | Send Personalized Mass iMessages In Seconds — Without Group Chats |
| Sub-headline | No messy group chats. No manual copying and pasting. |
| Bullets | Dynamic tags; photos/videos/media; unlimited groups & sends; 100% on-device privacy |
| Default package | Annual (`$rc_annual`) — badge "SAVE 58% • MOST POPULAR" |
| Secondary packages | Monthly + Lifetime side-by-side below annual |
| CTA (annual + trial) | Start 3-Day Free Trial & Continue |
| CTA (fallback) | Unlock Unlimited Messaging |
| Trust line | 🔒 No risk. Cancel anytime in App Store |
| Social proof | ★★★★★ "Saved me hours sending event invites!" — Petrus R. |
| Privacy Policy | https://www.termsfeed.com/live/707a5825-ae79-4e86-9ddc-edeeaeba78a9 |
| Terms of Use | https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ (interim Apple EULA) |

**Trial dependency:** CTA trial copy requires a 3-day free intro offer on `sent_it_annual` in ASC. Local simulator testing uses `ios/SentItProducts.storekit` intro offer. Gate: `displayCloseButton: false` in `subscription_gate.dart`.

## RevenueCat MCP (agent setup)

When `plugin-revenuecat-RevenueCat` MCP is available, bootstrap in this order:

1. `list-projects` → `create-project` (Sent It)
2. `create-app` — `type: app_store`, `bundle_id: com.sent.it`
3. `create-product` × 3 (monthly P1M, annual P1Y, lifetime non-consumable)
4. `create-entitlement` — `pro`
5. `attach-products-to-entitlement`
6. `create-offering` — lookup `default`
7. `create-packages` + `attach-products-to-package`
8. `list-app-public-api-keys` → `appl_...`
9. `create-paywall-ai` or configure paywall in dashboard; `publish-paywall`

Useful later: `get-customer`, `grant-customer-entitlement` (support), `get-overview-metrics`.

## Testing / Sandbox

| Channel | Use for |
|---------|---------|
| **Test Store** (`test_...` key) | Fast UI/paywall iteration; deterministic outcomes; debug only |
| **StoreKit config file** (.storekit in Xcode) | Local StoreKit without ASC delay |
| **Sandbox Apple ID** | Real receipt → RC Sandbox dashboard view |
| **TestFlight** | Near-production; transactions in **Production** RC view |

Verify each purchase: (1) device success, (2) RC dashboard (Sandbox toggle), (3) `pro` active on `CustomerInfo`.

Sandbox subs renew on accelerated clock (monthly ≈ 5 min, max 6 renewals then expire).

Fresh sandbox account for first-purchase / intro-offer tests.

## Common Pitfalls

- **Offerings empty** → products not in ASC, ASC key not in RC, or propagation delay (use .storekit locally)
- **Paywall shows default template** → no paywall attached to offering in dashboard
- **Wrong API key** → auth error in logs on first `getOfferings()`
- **Double purchase calls** → don't use `purchasePackage` with `PaywallView`
- **Grandfather on first launch fails** → receipt not synced until user taps Restore
- **`originalApplicationVersion` confusion** → it's build number on iOS; use `originalPurchaseDate`
- **Secret API key in app** → only public `appl_...` SDK keys in client code
- **iOS < 15** → `purchases_ui_flutter` requires iOS 15+

## Related

- `specs/prd-subscription-and-lifetime.md` — product requirements
- RC skills (Cursor): `integrate-revenuecat`, `revenuecat-paywall`, `revenuecat-entitlements-gate`, `revenuecat-purchase-flow`, `revenuecat-testing-setup`, `create-revenuecat-project`
