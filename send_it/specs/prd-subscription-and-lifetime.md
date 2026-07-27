# PRD: Subscription + Lifetime Purchase

> Status: draft (product decisions captured 2026-07-25)
> Author: Research Agent
> Date: 2026-07-25
> Source: User request — add subscription alongside existing one-time purchase (OTP) via App Store

## Executive Summary

Sent It currently monetizes as a **paid App Store download** (no IAP SDK in code). We will move to **free download + IAP**: monthly ($1.99) and annual ($9.99) subscriptions plus a lifetime non-consumable ($19.99), all unlocking a single `pro` entitlement. **Existing paid-download buyers are grandfathered** until release; anyone who downloads after the app goes free must subscribe or buy lifetime. RevenueCat remote paywalls (`purchases_ui_flutter`) handle purchase UI; pricing and paywall layout are adjustable from the RevenueCat dashboard without app updates.

## Problem Statement

### Current State

- **No IAP SDK in the app.** `pubspec.yaml` has no `purchases_flutter`, `in_app_purchase`, or similar dependency.
- **No premium gating in code.** All features (group creation, messaging, Blast shortcut) are available to every user with no entitlement checks.
- **No RevenueCat or App Store Connect configuration in repo.** No `StoreKit` config file, no `ai-docs/revenuecat.md`, no paywall UI.
- **iOS-only focus.** Bundle ID is `com.sent.it`. App uses Cupertino UI and native SMS/Shortcuts integrations.
- **Monetization is a paid App Store download.** Users pay upfront to install the app. There is no IAP product in App Store Connect and no receipt/entitlement logic in the app.

### Desired State

- App becomes **free to download**; new users must subscribe or buy lifetime to use the app (**full app gate** — no partial free tier in v1).
- **Monthly ($1.99)** and **annual ($9.99)** subscriptions plus **lifetime ($19.99)** non-consumable, all unlocking `pro`.
- A single **"pro" entitlement** grants full app access regardless of product purchased.
- **Paid-download buyers grandfathered** only if they originally purchased **before** the freemium release goes live; post-release free downloads are not grandfathered.
- **RevenueCat remote paywall** presents purchase options; prices/packages adjustable via RevenueCat + App Store Connect without code changes.
- Restore purchases available (Apple requirement).

### Why Now

Adding a subscription tier expands recurring revenue while keeping a lifetime option for users who prefer pay-once. Doing this before more premium features ship avoids retrofitting gating across a larger surface area.

## Users & Personas

| Persona | Need | Pain Point |
|---------|------|------------|
| New user (free/trial) | Try core features, then upgrade | No upgrade path exists in-app today |
| Power user (Blast, large groups) | Reliable premium access | May resist paid download-only model; wants subscription or lifetime choice |
| Existing paid-download buyer | Keep access after model change | Risk of double-paying or losing access if migration is mishandled |
| Casual sender | Low commitment | Subscription may feel better than a large one-time price |

## Goals & Non-Goals

### Goals

- Support **monthly + annual** subscriptions and **lifetime** non-consumable on iOS at confirmed price points.
- **Gate the entire app** behind `pro` (v1); partial free tier deferred to future release.
- Unify access behind a single RevenueCat entitlement (`pro`).
- Use **RevenueCat remote paywalls** (`purchases_ui_flutter`) — not custom paywall UI.
- Create a **new RevenueCat project** (none exists today).
- Grandfather pre-release paid-download customers via receipt cutoff at release time.
- Meet Apple IAP requirements (restore, subscription disclosure, legal links).

### Non-Goals

- Android / Google Play billing (iOS-only for v1 unless explicitly expanded).
- Consumable IAP (coins, credits, per-blast packs).
- Server-side receipt validation or custom billing backend (RevenueCat handles this).
- macOS IAP (Flutter macOS target exists but is out of scope).
- Partial free tier / feature-level gating (deferred — v1 gates everything).
- Custom paywall UI (using RC remote paywalls instead).
- Introductory offers or free trial (not in v1).

## User Stories

1. As a **new user**, I want to see subscription and lifetime options on a paywall so that I can pick the plan that fits my budget.
2. As a **subscriber**, I want my premium features to stay unlocked while my subscription is active so that I don't lose access mid-use.
3. As a **lifetime buyer**, I want to pay once and never be asked to subscribe again so that I have permanent access.
4. As an **existing paid-download customer**, I want the app to recognize that I already paid so that I'm not charged again when the model changes.
5. As a **lapsed subscriber**, I want to see a clear re-subscribe path so that I can regain premium features.
6. As a **user on a new device**, I want a "Restore Purchases" action so that Apple-required recovery works.

## Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-1 | Integrate RevenueCat SDK (`purchases_flutter` + `purchases_ui_flutter`) | must | New RC project; iOS key via `--dart-define` |
| FR-2 | Create ASC products: monthly sub, annual sub, lifetime non-consumable | must | Prices: $1.99 / $9.99 / $19.99 |
| FR-3 | Configure RC: entitlement `pro`, default offering, 3 packages | must | `$rc_monthly`, `$rc_annual`, `$rc_lifetime` |
| FR-4 | Present **RevenueCat remote paywall** for non-pro users | must | `PaywallView` / `presentPaywall`; layout editable in RC dashboard |
| FR-5 | **Gate entire app** behind active `pro` entitlement or grandfather flag | must | App unusable without pro (except migration restore flow) |
| FR-6 | "Restore Purchases" on paywall and/or More screen | must | Apple requirement |
| FR-7 | React to entitlement changes via SDK listener | must | Single source of truth |
| FR-8 | Grandfather paid-download buyers who purchased before release cutoff | must | `originalPurchaseDate` < ASC price-change timestamp |
| FR-9 | Subscription auto-renewal disclosure on paywall | must | RC paywall + Apple Guideline 3.1.2 |
| FR-10 | Handle user-cancelled purchase silently | must | Standard RC pattern |
| FR-11 | No free trial in v1 | must | Hard paywall after free download |
| FR-12 | Link Privacy Policy on paywall and ASC listing | must | URL confirmed; Terms/EULA may still be needed — see Legal |
| FR-13 | One-time migration prompt on first launch after IAP update | must | "Restore Access" to sync receipt |
| FR-14 | Cache grandfather status locally after verification | must | SharedPreferences or Keychain |
| FR-15 | Change App Store price to free before releasing migration build | must | Manual release; record cutoff timestamp |

## Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1 | Entitlement check latency (cached) | < 200ms on warm launch |
| NFR-2 | SDK configure before any entitlement read | Zero race on cold start |
| NFR-3 | API keys not committed to source control | Use `--dart-define` or xcconfig |
| NFR-4 | Debug logging off in release builds | No RC debug logs in production |
| NFR-5 | Sandbox testable end-to-end | Purchase → entitlement active → feature unlocked |

## Acceptance Criteria

- [ ] Non-pro user sees RevenueCat remote paywall on launch (full app gate).
- [ ] Sandbox user can purchase monthly, annual, or lifetime and access the app immediately.
- [ ] Sandbox user can purchase lifetime and access remains after app restart.
- [ ] User who cancels StoreKit sheet sees no error; paywall remains.
- [ ] Paid-download customer (pre-cutoff) retains access after migration + restore — no paywall.
- [ ] Post-release free downloader sees paywall and cannot use app without purchase.
- [ ] Grandfathered user never prompted to purchase.
- [ ] Lapsed subscriber sees paywall on next launch.
- [ ] Paywall links to Privacy Policy URL.
- [ ] Price changes in ASC reflected in RC offerings without app redeploy (paywall copy/layout via RC dashboard).
- [ ] `fvm flutter analyze` and `fvm flutter test` pass.

## Technical Context

### Existing Patterns

- **Flutter + Cupertino** dark theme (`lib/main.dart`), iOS-focused.
- **No service layer for monetization** — new `lib/services/` module expected (e.g., `subscription_service.dart`).
- **More screen** (`lib/screens/more_screen.dart`) is a natural home for "Restore", "Manage Subscription", and account status.
- **Project docs already route IAP to RevenueCat:** `conditional-docs.md` → `ai-docs/revenuecat.md` (not yet created).
- **Native iOS:** `AppDelegate.swift` uses MethodChannel for SMS; no StoreKit code today.

### Relevant Files (Initial)

- `pubspec.yaml` — add `purchases_flutter` + `purchases_ui_flutter`
- `lib/main.dart` — SDK configure at launch
- `lib/screens/more_screen.dart` — restore / subscription management entry points
- `lib/screens/group_message_screen.dart` — likely gate Blast or other premium actions
- `ios/Runner.xcodeproj/project.pbxproj` — bundle ID `com.sent.it`
- `ios/Podfile` — may need `platform :ios, '13.0'` minimum for RC
- `conditional-docs.md` — update routing once `ai-docs/revenuecat.md` exists

### Dependencies

| Dependency | Role |
|------------|------|
| RevenueCat (`purchases_flutter`) | IAP SDK, receipt validation, entitlements |
| RevenueCat UI (`purchases_ui_flutter`) | Remote paywall presentation |
| RevenueCat dashboard | **New project** — products, entitlements, offerings, paywall design |
| App Store Connect | Product definitions, subscription group, pricing ($1.99 / $9.99 / $19.99) |
| App Store Connect API key (.p8) | StoreKit 2 / RC server notifications |

**Missing doc:** Run `/ai-doc "revenuecat"` before planning — `ai-docs/revenuecat.md` does not exist.

### Constraints

- iOS-only v1; RevenueCat Flutter SDK supports iOS and Android only (no web/macOS).
- App has no user accounts — RevenueCat will use anonymous IDs by default; restore relies on Apple ID / StoreKit.
- **Paid → freemium migration** requires changing the App Store price to free in ASC before/at release. Grandfathering is client-side via receipt metadata, not an IAP restore of a product ID.
- Apple subscription + non-consumable can coexist; both attach to the same RevenueCat entitlement.
- Blast shortcut flow is partially outside the app (Shortcuts app) — gating must happen before launching Blast, not inside the shortcut.

## Product Catalog (confirmed)

| Product | Type | Price (USD) | Suggested product ID | RC package |
|---------|------|-------------|---------------------|------------|
| Sent It Pro Monthly | Auto-renewable subscription | $1.99/mo | `sent_it_monthly` | `$rc_monthly` |
| Sent It Pro Annual | Auto-renewable subscription | $9.99/yr | `sent_it_annual` | `$rc_annual` |
| Sent It Pro Lifetime | Non-consumable | $19.99 | `sent_it_lifetime` | `$rc_lifetime` |

All three attach to entitlement **`pro`**. Annual saves ~58% vs monthly ($23.88/yr → $9.99/yr). Lifetime is ~2× annual — strong upsell for committed users.

**Adjusting prices later:** Change prices in App Store Connect; RevenueCat syncs product metadata. Paywall copy, package ordering, and highlighting (e.g., "Best value") are editable in the **RevenueCat Paywalls** dashboard without an app update.

## UX / Design Notes

### Paywall placement (confirmed: full app gate)

- **On launch:** Non-pro, non-grandfathered users see RC remote paywall immediately — app is unusable until purchase or restore.
- **More screen:** Restore purchases, manage subscription link, pro status badge for grandfathered/lifetime users.
- **Future:** Partial gating deferred — centralize `hasPro` check for easy refactor later.

### Paywall implementation

- Use **RevenueCat remote paywalls** (`PaywallView` or `presentPaywallIfNeeded`) — design and copy managed in RC dashboard.
- Configure paywall in RC to show all three packages: monthly, annual (highlight as best value), lifetime.
- RC paywall includes restore button and subscription terms by default; add Privacy Policy link in RC paywall config.
- Match app theme where RC supports custom colors (teal `#0fa0ab`, dark background).

### Post-purchase

- Dismiss paywall, full app access via entitlement listener.
- Subscribers: "Manage Subscription" → `https://apps.apple.com/account/subscriptions` from More screen.
- Grandfathered users: optional "Lifetime access (original purchase)" badge in More — no paywall ever.

### Legal

| Document | Status | URL |
|----------|--------|-----|
| Privacy Policy | **Exists** | https://www.termsfeed.com/live/707a5825-ae79-4e86-9ddc-edeeaeba78a9 |
| Terms of Use (EULA) | **Likely needed** | Apple requires a Terms of Use link for auto-renewable subscriptions (Guideline 3.1.2). Create via TermsFeed before submission. |

Add Privacy Policy URL to App Store Connect app listing. Add both links to RC paywall footer and ASC subscription metadata.

## Research Notes

### Codebase finding: greenfield IAP integration

There is **no existing IAP code to migrate**. This is a net-new integration, not a StoreKit → RevenueCat observer-mode migration. The "existing OTP" concern is entirely about **App Store Connect / customer history**, not in-app code.

### Recommended RevenueCat model

```
Entitlement: "pro"
├── Product: sent_it_monthly   (auto-renewable, $1.99/mo)
├── Product: sent_it_annual    (auto-renewable, $9.99/yr)
└── Product: sent_it_lifetime  (non-consumable, $19.99)

Offering: "default"
├── Package $rc_monthly  → sent_it_monthly
├── Package $rc_annual   → sent_it_annual
└── Package $rc_lifetime → sent_it_lifetime

Paywall: RC remote paywall (dashboard-designed) attached to "default" offering
```

App code checks `customerInfo.entitlements.active['pro']` OR cached grandfather flag. **New RevenueCat project** — create from scratch via `create-revenuecat-project` skill.

### App Store Connect setup (iOS)

1. **Subscription group** — create one group (e.g., "Sent It Pro"); add monthly and/or annual products.
2. **Non-consumable** — create lifetime product (e.g., `com.sent.it.lifetime` or `sent_it_lifetime`).
3. **Paid Apps Agreement** — must be active in App Store Connect.
4. **In-App Purchase key** — generate in App Store Connect → Users and Access → Integrations; upload to RevenueCat.
5. **StoreKit Configuration file** — add `.storekit` file in Xcode for local sandbox testing without ASC propagation delay.
6. **App Review metadata** — Privacy Policy URL, Terms of Use (EULA) required on App Store listing for subscriptions.

### Grandfathering Strategy (confirmed: paid download → free + IAP)

**Product decision (confirmed):** Sent It is currently a paid download. The migration makes the app **free to download** with subscription + lifetime IAP for new users. All users who **originally downloaded while the app was paid** receive permanent pro access at no extra charge.

#### How Apple identifies legacy paid buyers

Paid-app purchases are recorded in the **App Store receipt**, not as IAP product IDs. RevenueCat exposes this via `CustomerInfo` after the receipt is synced:

| Field | Use |
|-------|-----|
| `originalPurchaseDate` | **Preferred.** Compare against the cutoff date when the app price changes to free in App Store Connect. Users who purchased before this date are grandfathered. |
| `originalApplicationVersion` | Fallback. On iOS this is the **build number** (`CFBundleVersion`), not the marketing version (`1.2.1`). Only reliable if build numbers were monotonically incremented and never reset. |

**Grandfathering cutoff (confirmed):** Only users who **paid to download before the freemium release** are grandfathered. After release (when price changes to free in ASC), **all new downloads are free and must purchase** — no grandfathering for post-release users. Record the ASC price-change timestamp at release; that is the hard cutoff for `originalPurchaseDate`.

Current app version at time of research: `1.2.1+1`. The IAP migration build should be a new version (e.g. `1.3.0` or `2.0.0`) — record its build number and the ASC price-change timestamp as migration constants.

#### Access check logic

```
hasPro = customerInfo.entitlements.active['pro'] != null
      || isGrandfatheredPaidBuyer   // cached after receipt check
```

Grandfathered users do **not** need to purchase the lifetime IAP — they already paid at download. The lifetime SKU is for **new** free-download users who want pay-once access.

#### Migration UX (critical)

On the **first launch** of the IAP-enabled build, RevenueCat will not have receipt data until the user restores. Existing paid buyers will appear as non-subscribers until restore runs.

1. Show a one-time **"Finish your upgrade"** dialog (What's New or first-launch modal) explaining the model change.
2. User taps **"Restore Access"** → calls `Purchases.restorePurchases()`.
3. App reads `CustomerInfo.originalPurchaseDate` (or build number fallback).
4. If grandfathered → set local cache (`isGrandfatheredPaidBuyer = true` in SharedPreferences/Keychain) and unlock pro.
5. Prompt user to restart the app if needed (some devs report state sync delay).
6. Never auto-call restore on every launch — only on explicit user action or first-launch migration prompt.

#### App Store Connect release process

1. Submit the IAP migration build for review with **manual release** enabled.
2. In reviewer notes: *"This update transitions the app from paid to freemium. I will change the price to free in App Store Connect before releasing."*
3. After approval, **change price to free** in ASC, then release the build.
4. Record the price-change timestamp as the grandfather cutoff date.

#### Sandbox / testing caveats

- Sandbox and App Review environments may return `originalApplicationVersion` as `"1.0"` regardless of actual history — test grandfather logic against `originalPurchaseDate` in production-like TestFlight builds when possible.
- TestFlight testers who never paid may not be grandfathered — use sandbox accounts that "purchased" the paid app before migration, or test the negative path (new free download → paywall).

#### What grandfathered users should NOT see

- Paywall blocking features they already had
- Pressure to buy lifetime (optional "You have lifetime access" badge in More screen is fine)
- Subscription renewal prompts

### Feature gating (confirmed)

**v1: Gate the entire app.** No free tier — users without `pro` (and not grandfathered) see the paywall on launch and cannot access any functionality. Centralize access in a single `SubscriptionService.hasPro` (or similar) so partial gating can be added later without rewiring every screen.

### Implementation sequence (for planner — not this PRD)

1. ~~Product decisions~~ — captured in this PRD.
2. Create **new RevenueCat project** + App Store Connect products.
3. `/ai-doc "revenuecat"` → `ai-docs/revenuecat.md`.
4. SDK integration + entitlement service.
5. Paywall UI + gating hooks.
6. Sandbox QA + TestFlight.
7. App Review submission with subscription metadata.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Receipt not synced on first launch — paid users see paywall | high | One-time migration restore prompt; cache grandfather flag after verify |
| `originalApplicationVersion` is build number, not marketing version | med | Prefer `originalPurchaseDate` cutoff; document ASC price-change timestamp |
| Double-charging existing buyers | high | Grandfather check runs before any paywall; never gate grandfathered users |
| Price changed to free before migration build is ready | high | Manual release; change price only after approval, before release |
| No `ai-docs/revenuecat.md` — planner lacks SDK reference | med | Run `/ai-doc` before `/feature` |
| Blast gating bypassed via direct Shortcuts URL | med | Gate in app before `ShortcutService.launchBlast()` |
| Subscription rejection (missing Terms/EULA on listing) | med | Create Terms of Use; Privacy Policy exists |
| Sandbox returns misleading receipt metadata | low | Document TestFlight vs sandbox behavior; validate on production receipts |

## Open Questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | ~~Paid app download?~~ | human | **resolved** |
| 2 | ~~Free vs. pro boundary?~~ | human | **resolved** — gate entire app (v1) |
| 3 | ~~Subscription tiers?~~ | human | **resolved** — monthly + annual; no trial |
| 4 | ~~Pricing?~~ | human | **resolved** — $1.99 / $9.99 / $19.99 |
| 5 | ~~Freemium model?~~ | human | **resolved** — free download + IAP |
| 6 | ~~Grandfathering policy?~~ | human | **resolved** — pre-release paid buyers only |
| 7 | ~~RevenueCat project?~~ | human | **resolved** — create new project |
| 8 | ~~Privacy Policy / Terms?~~ | human | **partial** — [Privacy Policy exists](https://www.termsfeed.com/live/707a5825-ae79-4e86-9ddc-edeeaeba78a9); **Terms of Use still needed** for subscriptions |
| 9 | ~~Paywall approach?~~ | human | **resolved** — RevenueCat remote paywalls |
| 10 | ~~Grandfather cutoff?~~ | human | **resolved** — ASC price-change timestamp at release; post-release downloads not grandfathered |

## Handoff to Planner

### Suggested Problem Class

`feature`

### Suggested Planner Prompt

```
/feature "Add subscription and lifetime IAP to Sent It"

Read specs/prd-subscription-and-lifetime.md first.

Scope:
- Create NEW RevenueCat project (iOS, bundle com.sent.it)
- Products: sent_it_monthly ($1.99), sent_it_annual ($9.99), sent_it_lifetime ($19.99)
- Entitlement "pro", default offering, RC remote paywall (purchases_ui_flutter)
- Full app gate: paywall on launch for non-pro users
- Grandfather pre-release paid-download buyers via originalPurchaseDate cutoff
- One-time "Restore Access" migration prompt; cache grandfather flag locally
- Privacy Policy: https://www.termsfeed.com/live/707a5825-ae79-4e86-9ddc-edeeaeba78a9
- Flag: Terms of Use (EULA) still needed before App Review

Run /ai-doc "revenuecat" before implementing.
iOS only in v1.
```

### Conditional Docs to Load

- `specs/prd-subscription-and-lifetime.md` (this PRD)
- `conditional-docs.md`
- `ai-docs/revenuecat.md` (create via `/ai-doc` first)
- `lib/main.dart`, `lib/screens/more_screen.dart`, `lib/screens/group_message_screen.dart`
- `lib/services/shortcut_service.dart` (Blast gating touchpoint)
- RevenueCat skills: `integrate-revenuecat`, `revenuecat-purchase-flow`, `revenuecat-entitlements-gate`, `revenuecat-paywall`, `revenuecat-testing-setup`
