# PRD: Free Trial for Sent It Pro

> Status: draft (product decisions captured 2026-07-27)
> Author: Research Agent
> Date: 2026-07-27
> Source: User request — add free trial support; investigate implementation and real-world best practices

## Executive Summary

Sent It currently gates the full app behind a hard paywall with no way to try Pro before committing. We will add a **3-day free trial on the annual subscription** (`sent_it_annual`) using Apple's **Introductory Offer** mechanism, surfaced through the existing RevenueCat remote paywall. This is primarily a **store + dashboard configuration** change — Apple applies the trial automatically at purchase, RevenueCat grants the `pro` entitlement during the trial, and the app's existing entitlement gate unlocks the app with little or no new code.

## Problem Statement

### Current State

- **Hard paywall on launch.** Non-pro, non-grandfathered users see `PaywallView` immediately and cannot use the app without purchasing (`subscription_gate.dart`, `displayCloseButton: false`).
- **No introductory offer in production.** RevenueCat products show `trial_duration: null` for `sent_it_annual`. App Store Connect has not yet been confirmed as having a 3-day free intro offer live.
- **Local StoreKit config is ahead of production.** `ios/SentItProducts.storekit` already defines a 3-day free trial on `sent_it_annual`; monthly has `introductoryOffer: null`.
- **Paywall copy anticipates a trial.** RevenueCat paywall **Sent It Paywall: v1** (`pwa4f358491d9044ab`) targets CTA copy "Start 3-Day Free Trial & Continue" for annual selection — but this only works when ASC intro offer is active.
- **Original subscription PRD excluded trials.** `specs/prd-subscription-and-lifetime.md` listed "No free trial in v1" (FR-11). Product direction has since shifted (see `specs/chore-update-paywall-v1.md`, `ai-docs/revenuecat.md`).
- **App code has no trial-specific logic.** `SubscriptionService` checks `entitlements.active['pro']` only — no eligibility checks, no trial status display, no custom trial timers.

### Desired State

- New users can **start a 3-day free trial of the annual plan** from the paywall, get immediate full app access, and convert to paid annual ($9.99/yr) unless they cancel before trial ends.
- Paywall copy **accurately reflects trial eligibility** — trial CTA for eligible users, fallback CTA for ineligible users (e.g., returning subscribers).
- Trial users experience the **same full-app access** as paid subscribers during the trial period.
- Grandfathered paid-download buyers are **unaffected** — they never see the paywall or trial flow.
- Monthly and lifetime options remain available **without a trial** (industry-standard pattern to anchor annual).

### Why Now

The paywall redesign already positions annual as the default package with trial-oriented CTA copy. Shipping without the ASC intro offer creates misleading UX and leaves conversion on the table. Utility/messaging apps with fast time-to-value (send one blast → see value) benefit from short opt-out trials that reduce purchase friction while pushing annual LTV.

## Users & Personas

| Persona | Need | Pain Point |
|---------|------|------------|
| New free downloader | Try Pro before paying | Hard paywall with no evaluation period |
| Annual trial user | Full access during trial, easy cancel | Unclear trial terms or surprise charges |
| Monthly buyer | Low commitment without trial | Doesn't want annual commitment; monthly stays no-trial |
| Grandfathered buyer | Keep lifetime access | Must not be pushed into trial or re-purchase |
| Lapsed subscriber (never trialed) | Second chance at trial | Eligible for intro offer if never used in subscription group |
| Lapsed subscriber (used trial) | Re-subscribe without trial | Sees standard pricing; no misleading trial CTA |

## Goals & Non-Goals

### Goals

- Enable a **3-day free trial** on `sent_it_annual` via App Store Connect Introductory Offer.
- Ensure trial users receive active **`pro` entitlement** for the trial duration (handled by Apple + RevenueCat).
- Update paywall to show **eligibility-aware trial copy** on annual package (RC template variables).
- Keep **annual as default** pre-selected package on paywall (conversion best practice).
- Support **local simulator testing** via existing StoreKit config file.
- Meet **Apple Guideline 3.1.2** disclosure requirements (trial terms, auto-renewal, cancel instructions).
- Document trial behavior in `ai-docs/revenuecat.md` for future agents.

### Non-Goals

- Custom app-side trial timers or "try before you subscribe" without StoreKit (violates Apple IAP rules for subscription apps).
- Free trial on monthly (`sent_it_monthly`) — annual-only trial is the recommended pattern for this paywall layout.
- Trial on lifetime non-consumable (`sent_it_lifetime`).
- Push notification trial reminders or win-back campaigns (future growth work).
- Promotional offers / offer codes for lapsed users (separate Apple offer type; not introductory).
- Android trials (iOS-only v1).
- Changing full-app gate policy (paywall remains non-dismissible without purchase/restore/trial start).
- Partial free tier or freemium model (deferred).

## User Stories

1. As a **new user**, I want to start a free trial of the annual plan so that I can try Sent It before paying.
2. As a **trial user**, I want full app access immediately after starting my trial so that I can send a real blast and evaluate the product.
3. As a **trial user**, I want clear terms on the paywall (duration, price after trial, cancel instructions) so that I know what I'm signing up for.
4. As a **user who already used a trial**, I want to see honest non-trial pricing so that I'm not misled by trial copy I can't redeem.
5. As a **grandfathered buyer**, I want to bypass the paywall entirely so that I'm never asked to start a trial.
6. As a **monthly subscriber**, I want to subscribe monthly without being forced into an annual trial so that I can choose my commitment level.
7. As a **developer**, I want to test trial purchase and conversion in sandbox without real charges so that I can verify the flow before release.

## Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-1 | Configure 3-day free Introductory Offer on `sent_it_annual` in App Store Connect | must | Type: Free; duration: 3 days; eligible: new subscribers |
| FR-2 | Keep `ios/SentItProducts.storekit` annual intro offer in sync with ASC for local testing | must | Already configured locally |
| FR-3 | Paywall CTA shows trial copy for eligible users on annual package | must | RC intro-offer template variables; fallback CTA when ineligible |
| FR-4 | Trial start grants immediate `pro` entitlement and unlocks app | must | No app code change expected — RC/Apple handle this |
| FR-5 | Trial auto-converts to paid annual unless user cancels in App Store | must | Standard Apple opt-out trial behavior |
| FR-6 | Ineligible users see non-trial pricing/CTA on paywall | must | RC paywall eligibility-aware components |
| FR-7 | Monthly and lifetime packages show no trial offer | must | No intro offer on those products |
| FR-8 | Grandfathered users never see paywall or trial flow | must | Existing `SubscriptionService` logic |
| FR-9 | Restore purchases works for trial and post-trial states | must | Existing paywall + More screen restore |
| FR-10 | Paywall discloses auto-renewal, trial duration, and post-trial price | must | Apple 3.1.2; RC paywall footer + package terms |
| FR-11 | Privacy Policy and Terms of Use linked on paywall | must | URLs in `subscription_constants.dart` |
| FR-12 | Show trial status in More screen (e.g., "Trial — ends [date]") | must | Confirmed in scope; uses `CustomerInfo` period type |
| FR-13 | Do not ship trial CTA copy until ASC intro offer is live | must | Avoid misleading App Review / users |
| FR-14 | Sandbox QA with fresh Apple ID for first-time trial eligibility | must | One intro offer per subscription group per Apple ID |

## Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1 | ASC intro offer propagation | Allow up to 24h after ASC config before production QA |
| NFR-2 | No custom trial logic in app | Prefer store-managed trial; minimize maintenance |
| NFR-3 | Paywall trial copy updatable without app deploy | RC remote paywall |
| NFR-4 | Trial entitlement check latency | Same as existing gate (< 200ms warm launch) |
| NFR-5 | Sandbox trial renewal clock | Apple accelerates (annual trial does not renew as annual in sandbox the same way — verify in QA) |

## Acceptance Criteria

- [ ] `sent_it_annual` has active 3-day free Introductory Offer in App Store Connect (visible in RC product metadata after sync).
- [ ] Eligible sandbox user taps "Start 3-Day Free Trial" on paywall → Apple payment sheet shows 3-day free trial → app unlocks immediately.
- [ ] Trial user's `CustomerInfo` shows active `pro` entitlement with trial period type.
- [ ] Ineligible sandbox user (prior intro offer consumed in subscription group) sees fallback CTA without trial language.
- [ ] Monthly package selection shows no trial terms.
- [ ] Grandfathered user bypasses paywall; no trial prompt.
- [ ] User cancels trial in App Store settings → access ends at trial expiration → paywall reappears.
- [ ] Paywall footer links resolve to Sent It Privacy Policy and Terms of Use.
- [ ] Local Xcode + StoreKit config file reproduces trial flow without ASC propagation delay.
- [ ] `fvm flutter analyze` and `fvm flutter test` pass (no regressions from any code changes).

## Technical Context

### Existing Patterns

- **Entitlement gate is the access model.** `SubscriptionService.hasPro` returns true when `entitlements.active['pro']` OR grandfather flag is set. Trial subscribers will have an active entitlement during trial — no separate "trial mode" needed.
- **Remote paywall handles purchase.** `PaywallView` in `subscription_gate.dart` — do not add parallel `purchasePackage` calls.
- **Annual is paywall default.** RC offering `default` has `$rc_annual` pre-selected; paywall v1 uses annual-first layout.
- **StoreKit config attached to Xcode scheme.** `Runner.xcscheme` references `SentItProducts.storekit` for local testing.
- **Debug uses RC Test Store key; release uses App Store key.** Intro offers behave differently in Test Store vs real ASC — validate on sandbox/TestFlight before release.

### Relevant Files (Initial)

- `ios/SentItProducts.storekit` — local 3-day annual intro offer (already set)
- `lib/widgets/subscription_gate.dart` — `PaywallView` full-app gate
- `lib/services/subscription_service.dart` — entitlement + grandfather logic (may add trial status display)
- `lib/constants/subscription_constants.dart` — legal URLs, product IDs
- `lib/screens/more_screen.dart` — optional trial status label
- `ai-docs/revenuecat.md` — paywall copy, trial dependency notes
- `ai-docs/asc.md` — ASC app `6746167372`, intro offer setup
- `specs/chore-update-paywall-v1.md` — paywall redesign with trial CTA dependency
- `specs/prd-subscription-and-lifetime.md` — base subscription model (superseded on trial scope)

### Dependencies

| Dependency | Role |
|------------|------|
| App Store Connect | Introductory Offer on `sent_it_annual` (authoritative for production) |
| RevenueCat dashboard | Paywall eligibility-aware copy; product sync from ASC |
| RevenueCat Flutter SDK | Entitlement during trial; optional eligibility API |
| Apple StoreKit | Applies intro offer automatically at purchase |
| `ai-docs/revenuecat.md` | SDK patterns — exists |
| `ai-docs/asc.md` | ASC automation — exists |

### Constraints

- **Apple controls trial application.** Introductory offers are applied automatically by the App Store payment sheet; RevenueCat cannot force a trial on ineligible users.
- **One intro offer per subscription group per Apple ID.** Users who previously trialed any product in "Sent It Pro" group cannot get another intro offer (including lapsed users who already consumed it).
- **iOS-only eligibility API.** `Purchases.checkTrialOrIntroductoryPriceEligibility` is iOS-only; not needed if using RC remote paywall components (RC handles display logic).
- **No app-side free access without StoreKit.** A local timer granting Pro without a StoreKit transaction would violate Apple guidelines and bypass receipt validation.
- **Test Store vs App Store.** Debug builds use RC Test Store key — trial behavior for QA should use StoreKit file or sandbox Apple ID with App Store key, not Test Store alone, before release.
- **Propagation delay.** ASC intro offer changes can take up to 24 hours to appear in production API responses.

## UX / Design Notes

### Recommended trial model (industry best practice)

**Annual-only, 3-day, opt-out trial** attached to the default paywall package:

| Element | Recommendation | Rationale |
|---------|----------------|-----------|
| Which product | Annual only | Pushes higher LTV; matches existing paywall layout; Headspace/industry pattern |
| Duration | 3 days | Fast time-to-value for messaging utility; already in paywall copy; creates urgency |
| Trial type | Apple Introductory Offer (free) | Store-managed billing, auto-renewal, App Review compliant |
| Default package | Annual pre-selected | Default effect increases annual trial starts |
| Monthly trial | No | Avoids anchoring low-commitment users on monthly |
| Lifetime trial | No | Non-consumables don't support intro offers |
| CTA (eligible) | "Start 3-Day Free Trial & Continue" | Already designed in paywall v1 |
| CTA (ineligible) | "Unlock Unlimited Messaging" | Honest fallback per `chore-update-paywall-v1.md` |
| Trust line | "🔒 No risk. Cancel anytime in App Store" | Already in paywall design |
| Gate behavior | Full app access during trial | Standard for full-app-gate apps; entitlement active during trial |

### User flow

```
Launch → SubscriptionGate
  ├─ hasPro (entitlement or grandfather) → App
  └─ no access → PaywallView
       ├─ Annual selected (default)
       │    ├─ Eligible → CTA "Start 3-Day Free Trial…"
       │    └─ Ineligible → CTA "Unlock Unlimited Messaging"
       ├─ Monthly / Lifetime → standard pricing, no trial
       └─ Purchase / trial start → Apple sheet (shows trial terms)
            → pro entitlement active → App unlocked
```

### More screen (in scope)

Display subscription status with trial awareness:
- "Pro subscriber" (paid)
- "Free trial — ends [date]" (trial period)
- "Lifetime Pro" / "Lifetime access (original purchase)" (existing patterns)

Uses RevenueCat `CustomerInfo` entitlement `periodType` (`trial`, `intro`, `normal`) — no custom timer.

### Legal / App Review

Apple Guideline 3.1.2 requires on paywall and/or App Store metadata:
- Subscription title, length, price
- Trial duration and price after trial
- Auto-renewal disclosure
- Privacy Policy and Terms of Use links
- Link to manage/cancel subscriptions

RC paywall components can render intro-offer terms dynamically. Ensure ASC subscription localization includes trial description.

## Research Notes

### How free trials work with RevenueCat (no custom app trial logic)

Per [RevenueCat subscription offers docs](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers):

1. Configure Introductory Offer in **App Store Connect** on the subscription product.
2. Apple **automatically applies** the offer to eligible purchasers in the payment sheet.
3. RevenueCat receives the transaction and grants the **`pro` entitlement** for the trial period.
4. RC remote paywall can show **eligibility-aware copy** via intro-offer template variables (`offer_period_with_unit`, `offer_price`, etc.).
5. After trial, Apple auto-renews to paid annual unless cancelled (opt-out trial).

**The app does not need a separate "trial mode."** Existing `hasPro` check covers trial users because their entitlement is active.

### Three implementation approaches considered

| Approach | Description | Verdict |
|----------|-------------|---------|
| **A. ASC Introductory Offer + RC Paywall (recommended)** | Configure 3-day free trial on annual in ASC; RC paywall shows eligibility-aware copy; existing gate unlocks on entitlement | ✅ Industry standard; minimal code; already aligned with paywall v1 design |
| **B. Custom eligibility checks in Flutter** | Call `Purchases.checkTrialOrIntroductoryPriceEligibility` and build custom paywall copy | ❌ Unnecessary — Sent It uses RC remote paywall, not custom UI |
| **C. App-side timer / local trial** | Grant Pro access for N days without StoreKit transaction | ❌ Violates Apple IAP guidelines; bypasses receipt validation; do not implement |

### Eligibility rules (Apple)

- **New subscribers:** Always eligible for intro offer.
- **Lapsed subscribers:** Eligible only if they **never consumed** an intro offer in the subscription group.
- **Existing subscribers:** Not eligible when upgrading/downgrading/crossgrading within the same subscription group.
- **Grandfathered users:** Bypass paywall entirely — trial is irrelevant.

### Industry benchmarks (2024–2026)

- **Annual-only trials** are common for apps pushing annual as the default (Headspace: 14-day annual trial, 7-day monthly).
- **5–9 day trials** are the most common duration band; **3–5 days** suits simple utility apps with fast time-to-value.
- **Opt-out trials** (Apple default) convert higher than opt-in but require clear disclosure to avoid surprise charges and bad reviews.
- **Trial subscribers retain 1.4–1.7× better** than direct purchasers at first renewal (industry data).
- Sent It's use case (send one personalized blast) likely reaches value in minutes — 3 days is sufficient evaluation time.

### Current infrastructure gap analysis

| Layer | Trial ready? | Gap |
|-------|-------------|-----|
| StoreKit local file | ✅ | Annual has 3-day free intro offer |
| ASC production | ❌ | **Confirmed empty** via `asc subscriptions offers introductory list --subscription-id 6794926795` (2026-07-27) |
| RevenueCat products | ❌ | `trial_duration: null` on annual |
| RC paywall v1 | ⚠️ | Copy references trial; needs ASC offer + eligibility templates |
| App code (`SubscriptionService`) | ✅ | Entitlement gate works for trial users |
| App code (`SubscriptionGate`) | ✅ | No changes required for basic trial |
| More screen trial status | ❌ | Optional enhancement not implemented |

### Relationship to prior PRD

`specs/prd-subscription-and-lifetime.md` FR-11 stated "No free trial in v1." This PRD **supersedes** that requirement. Subsequent work (`chore-update-paywall-v1.md`, `ai-docs/revenuecat.md`) already assumed a 3-day annual trial — this PRD formalizes that product decision.

### Sandbox testing notes

- Use a **fresh sandbox Apple ID** for first-time intro offer tests (one redemption per subscription group).
- Sandbox subscriptions renew on accelerated schedule; annual sandbox behavior differs from production — validate entitlement grant/cancel, not exact renewal timing.
- StoreKit config file enables local testing without ASC propagation delay.
- TestFlight uses production ASC products — intro offer must be live in ASC.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Trial CTA shown before ASC offer is live | high | Gate paywall publish on ASC config; use fallback CTA until verified |
| Misleading trial copy for ineligible users | med | RC eligibility-aware templates; fallback CTA |
| User surprised by charge after trial | med | Clear paywall disclosure; Apple payment sheet shows terms; trust micro-copy |
| ASC propagation delay (up to 24h) | med | Use StoreKit file for dev; wait before TestFlight QA |
| Grandfathered user sees trial paywall | high | Existing grandfather check runs before paywall; regression test |
| Test Store key doesn't reflect real intro offers | med | Validate with StoreKit file + sandbox Apple ID before release |
| App Review rejection (missing subscription metadata) | med | Complete ASC subscription localization; Terms + Privacy links |
| User consumes trial, cancels, expects another trial | low | Apple enforces one intro offer per group; ineligible CTA handles UX |

## Open Questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | ~~Confirm **3-day** trial duration?~~ | human | **resolved** — 3 days |
| 2 | ~~Confirm **annual-only** trial?~~ | human | **resolved** — annual only |
| 3 | ~~ASC Introductory Offer on `sent_it_annual`?~~ | human | **resolved** — none yet; ASC CLI confirms `introductoryOffers: []` on sub `6794926795` |
| 4 | ~~Trial status in More screen?~~ | human | **resolved** — yes, in scope |
| 5 | ~~When to publish paywall trial CTA?~~ | human | **resolved** — after ASC intro offer is created **and** verified in sandbox; paywall copy via RC MCP (`edit-paywall-ai`) then `publish-paywall` with user approval |
| 6 | ~~Promotional offers for lapsed users?~~ | human | **resolved** — not now |
| 7 | Terms of Use / EULA creation | human | **open** — owner will create before App Review; interim Apple EULA link exists in `subscription_constants.dart` |

## Handoff to Planner

### Suggested Problem Class

`chore` (ASC + RC dashboard) plus small app change for More screen trial status

### Suggested Planner Prompt

```
/chore "Enable 3-day free trial on Sent It Pro annual subscription"

Read specs/prd-free-trial.md first.

Scope:
1. ASC: create 3-day free Introductory Offer on sent_it_annual (sub ID 6794926795, app 6746167372)
   - CLI: asc subscriptions offers introductory import --subscription-id 6794926795 ...
   - Or ASC dashboard → Introductory Offers tab
2. Verify ios/SentItProducts.storekit annual intro offer matches ASC (already P3D free trial)
3. Sandbox QA: fresh Apple ID → trial purchase → pro entitlement → app unlock
4. RC paywall v1 (pwa4f358491d9044ab): edit via MCP (edit-paywall-ai) — eligibility-aware trial CTA on annual; fallback for ineligible
5. Publish paywall (publish-paywall) ONLY after ASC offer verified in sandbox + explicit user approval
6. More screen: show trial status ("Trial — ends [date]") via CustomerInfo period type
7. No custom app-side trial timers; do not change subscription_gate.dart gate policy
8. Update ai-docs/revenuecat.md with trial configuration notes
9. Blocker: owner creating Terms of Use/EULA before App Review (Privacy Policy exists)

Validate: fresh sandbox Apple ID trial purchase → pro entitlement → app unlock; ineligible user sees fallback CTA; grandfathered user bypasses paywall.
```

### Conditional Docs to Load

- `specs/prd-free-trial.md` (this PRD)
- `specs/prd-subscription-and-lifetime.md` (base subscription model)
- `specs/chore-update-paywall-v1.md` (paywall trial CTA dependency)
- `ai-docs/revenuecat.md`
- `ai-docs/asc.md`
- `lib/widgets/subscription_gate.dart`
- `lib/services/subscription_service.dart`
- `ios/SentItProducts.storekit`
- RevenueCat skills: `revenuecat-testing-setup`, `revenuecat-paywall`, `revenuecat-troubleshoot`
