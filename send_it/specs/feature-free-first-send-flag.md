# Feature: Free first send behind a PostHog feature flag

## Description

Add a PostHog feature flag, `free-first-send`, that lets a non-Pro user complete **one** regular Send without seeing the paywall. There is no recipient cap.

After that batch:
- The results sheet shows, and its button leads into the **closable** RevenueCat paywall (swipe down to close).
- The app is **never locked**. Users who skip the paywall keep the whole UI: groups, editing and composing. Only Send and Blast ask for Pro, using the closable paywall they get today.

The point is to keep the app installed. Someone who can still open and use it is more likely to come back and pay than someone shut out by a lock screen.

With the flag off, not loaded, or in a build without PostHog, nothing changes: the paywall appears at the first Send tap, as it does today (`9feed6b`).

Every relevant event records which arm the user was in, so the two placements can be compared in PostHog.

## User Story

As a new Sent It user, I want to send my first group text before I'm asked to pay, and keep using the app afterwards, so that I can see it work and decide to buy when I next need it.

As the developer, I want to switch that on or off, or split it 50/50, from PostHog without a new build, so that I can measure whether it helps conversion.

## Problem / Solution

**Problem:**
- The paywall placement is fixed in the build. A free first send shipped in PD-133 (`19332fb`, Oct 20) and was removed in `9feed6b` (Oct 21), following `specs/research-hard-paywall-placement.md`.
- The PD-133 version also locked the whole app after the free send, which pushes users to delete it.

**Solution:**
- **Flag check:** when the flag is on, `_ensureProForSend` lets the user's first regular send through.
- **Soft prompt:** after the batch, show the results sheet, then the closable paywall once.
- **Launch gate exemption:** users whose first send was the free one are exempt from the launch gate (which locks the app with no close button), so the app stays usable. Every later Send or Blast still needs Pro through the closable paywall.
- **Recording the arm:** the flag value goes on the relevant events.

## Relevant Files

- `lib/services/analytics_service.dart` — PostHog setup, event helpers and `PaywallTrigger`. The flag read lives here, because PostHog is only set up here and is skipped in debug.
- `lib/screens/group_message_screen.dart` — `_sendMessages` (~111), `_showResults` (~292), `_ensureProForSend` (~309) and `_ensureProForBlast` (~327).
- `lib/widgets/subscription_gate.dart` — `isLocked` (the launch gate), `needsPaywallToSend`, and the `paywall_viewed {trigger: launch}` logging.
- `lib/services/onboarding_service.dart` — `hasCompletedFirstSend` and `markFirstSendCompleted`.
- `lib/screens/group_message/send_results_sheet.dart` — `showSendResults` currently hardcodes `buttonLabel: 'Done'`.
- `lib/constants/analytics_constants.dart` — the place for the flag key and a debug override.
- `lib/constants/subscription_constants.dart` — the existing debug-override pattern (`debugOriginalAppVersion`) to copy.
- `test/subscription_service_test.dart`, `test/onboarding_service_test.dart`, `test/send_results_test.dart` — existing tests to extend.
- Reference only (read with `git show`):
  - `git show 9feed6b^:send_it/lib/screens/group_message_screen.dart`: `_showResults` with `continueLabel: 'Keep Sending'`.
  - `git show 9feed6b^:send_it/lib/widgets/subscription_gate.dart`: the `_FirstSendBanner` copy ("You just texted N people…"), which can be reused for the sheet's button text or the paywall context.
- `ai-docs/revenuecat.md` — paywall and entitlement rules (per `conditional-docs.md`).
- `specs/research-hard-paywall-placement.md` — why the free send was removed (context only).

## New Files

- `test/free_first_send_test.dart` — unit tests for the pure decision helpers and flag-value parsing.

No new dependencies. `posthog_flutter` 5.55.0 (locked) already has `getFeatureFlagResult`, `reloadFeatureFlags` and `onFeatureFlags`.

## Implementation Plan

### Foundation

1. **Flag constants** in `AnalyticsConstants`:
   - `freeFirstSendFlagKey = 'free-first-send'`.
   - `debugFreeFirstSend = bool.fromEnvironment('DEBUG_FREE_FIRST_SEND')`, honoured only under `kDebugMode`, the same way as `debugOriginalAppVersion`. PostHog is off in debug, so without this the feature couldn't be tested.
2. **Flag read in `AnalyticsService`:** `Future<FreeFirstSendArm> freeFirstSendArm()`.
   - `enum FreeFirstSendArm { on, off, unloaded }`.
   - In debug with the override set, return `on`.
   - If PostHog isn't enabled, return `unloaded`.
   - Otherwise call `Posthog().getFeatureFlagResult(key)`:
     - `null` → `unloaded`
     - `enabled == false` or variant `control` → `off`
     - `enabled == true` with no variant, or variant `test` → `on`
     - any other variant → `off`
   - Keep the mapping in a pure static `armFrom({required bool? enabled, required String? variant})`.
   - Wrap the read in try/catch; an exception counts as `unloaded`.
3. **Record the arm on events:** call `Posthog().register('free_first_send', arm.name)` from `config.onFeatureFlags`, and again after each `freeFirstSendArm()` read, so later events carry the arm.
4. **Persist that the free send was used:** in `OnboardingService`, add the key `free_first_send_used`, with `bool get hasUsedFreeFirstSend` and `Future<void> markFreeFirstSendUsed()`. Load it in `initialize()` next to `hasCompletedFirstSend`.

### Core

5. **Decision helpers** in `SubscriptionGate`:
   - `static bool freeFirstSendAllowed({required bool subscriptionRequired, required bool hasPro, required bool hasCompletedFirstSend, required FreeFirstSendArm arm})` returns `subscriptionRequired && !hasPro && !hasCompletedFirstSend && arm == FreeFirstSendArm.on`.
   - `isLocked(...)` gets a new `bool usedFreeFirstSend = false` parameter and returns false when it's true. Everything else stays the same.
   - `needsPaywallToSend` is unchanged. Every Send after the free one is paywalled.
6. **`_ensureProForSend`:**
   - After `waitForEvaluation()`, and only when `needsPaywallToSend` is true, read the arm.
   - If `freeFirstSendAllowed`, set `_isFreeSend = true` and return true.
   - Otherwise, behave as today.
   - Only read the flag when the paywall would otherwise show, so Pro and grandfathered users never trigger `$feature_flag_called`.
7. **Blast stays paywalled.** `_ensureProForBlast` is unchanged; only its doc comment changes. The Blast Shortcut can't report whether anything was sent, so it can't count as the first send.
8. **`_showResults` when `_isFreeSend` is true:**
   - Log `firstSendCompleted(..., wasFree: true)`.
   - **Before** the sheet, so a kill during the sheet still counts the free send, call `markFreeFirstSendUsed()` and then `markFirstSendCompleted()`, **in that order**. `markFirstSendCompleted()` notifies the gate's listeners, and the gate must already see `hasUsedFreeFirstSend == true` by then, or it would lock.
   - Show the results sheet with `continueLabel: 'Keep Sending'` (add an optional `continueLabel` to `showSendResults`, defaulting to `'Done'`).
   - After the sheet closes, if `mounted`, log `paywall_viewed {trigger: first_send}` and call `RevenueCatUI.presentPaywall(displayCloseButton: true)` **once**. Closing it leaves the user on the group screen with the full app.
   - A batch where everything was cancelled (`sentCount == 0`) returns before `_showResults`, as it does today, so the free send isn't used up.

### Integration

9. **Wire the gate** in `SubscriptionGate.build`: pass `usedFreeFirstSend: _onboarding.hasUsedFreeFirstSend` to `isLocked`. Add `firstSend` back to `PaywallTrigger`; `_snake` maps it to `first_send`.
10. **Explicit event properties:**
    - `sendTapped(...)`: add `free_first_send: arm.name` (`unloaded` when the arm wasn't read, for example for Pro users) and `paywall_skipped: bool`. Log it after `_ensureProForSend` has read the arm, still exactly once per valid tap, including when the paywall then closes without a purchase.
    - `paywallViewed(trigger, {FreeFirstSendArm? arm})`: include `free_first_send` when known.
    - `firstSendCompleted(...)`: add `was_free: bool`.

### Polish

11. Update the doc comments:
    - `SubscriptionGate` and `isLocked`: the launch gate now exempts free-send users and still catches lapsed trials and subscriptions for everyone else.
    - `_ensureProForSend` and `OnboardingService`.
12. Write `app-docs/free-first-send.md`: what the flag does, how to turn it on or split it, which events to compare, the launch-gate exemption, and the reinstall loophole.
13. Update the "Notes" line in `specs/feature-paywall-at-send.md` to point to this flag.

## Step-by-Step Tasks

1. Add `freeFirstSendFlagKey` and `debugFreeFirstSend` to `lib/constants/analytics_constants.dart`.
2. In `lib/services/analytics_service.dart`:
   - add `FreeFirstSendArm`, `armFrom` and `freeFirstSendArm()`
   - register the `free_first_send` super property
   - add `PaywallTrigger.firstSend`
   - extend `sendTapped`, `paywallViewed` and `firstSendCompleted`
3. In `lib/services/onboarding_service.dart`, add the `free_first_send_used` key, `hasUsedFreeFirstSend` and `markFreeFirstSendUsed()`, and load it in `initialize()`.
4. In `lib/widgets/subscription_gate.dart`, add `freeFirstSendAllowed(...)` and the `usedFreeFirstSend` parameter on `isLocked`, then wire it up in `build`.
5. In `lib/screens/group_message/send_results_sheet.dart`, add an optional `continueLabel` to `showSendResults`.
6. In `lib/screens/group_message_screen.dart`:
   - read the arm in `_ensureProForSend` and set `_isFreeSend`
   - move `sendTapped` after the arm is known
   - in `_showResults` when `_isFreeSend` is true: mark it used, then mark the first send completed, show the sheet with "Keep Sending", then present the closable paywall once
   - leave `_ensureProForBlast` unchanged apart from its comment
7. Write `test/free_first_send_test.dart`, and extend `test/onboarding_service_test.dart` (see Testing).
8. Write `app-docs/free-first-send.md`, and update the note in `specs/feature-paywall-at-send.md`.
9. Run the validation commands.
10. Do the simulator check below with `--dart-define=DEBUG_FREE_FIRST_SEND=true`, then without it.
11. **PostHog setup** (only after the user approves it in chat):
    - create the boolean flag `free-first-send` at 0% rollout, filtered to `$app_namespace = com.sent.it`
    - or create a PostHog Experiment with `control`/`test` variants on the same key
    - don't turn it on

## Testing

- **Unit tests for:**
  - `AnalyticsService.armFrom`:
    - `null` → `unloaded`
    - `enabled:false` → `off`
    - `enabled:true`, no variant → `on`
    - `test` → `on`
    - `control` → `off`
    - any other variant → `off`
  - `SubscriptionGate.freeFirstSendAllowed`:
    - true only when the subscription is required, the user isn't Pro, hasn't completed a first send, and the arm is `on`
    - false for `off`, `unloaded`, Pro users, and after a first send
  - `SubscriptionGate.isLocked`:
    - with `usedFreeFirstSend: true` → false, even with `hasCompletedFirstSend: true` and `hasPro: false`
    - with `usedFreeFirstSend: false`, it behaves as today: a lapsed user who has sent before and isn't Pro is locked
  - Combined: an `on`-arm user's first Send needs no paywall, and after the free send `needsPaywallToSend` is true again and `isLocked` is false.
  - `OnboardingService`:
    - `markFreeFirstSendUsed()` persists, and a new instance reads `hasUsedFreeFirstSend == true` after `initialize()`
    - existing users (the existing-prefs branch) start with it false
  - A regression check that the current behaviour (arm `off`/`unloaded`) still paywalls at the first Send tap.
- **E2E test (simulator, debug):** run `fvm flutter run --dart-define=DEBUG_FREE_FIRST_SEND=true` on a fresh simulator install with a non-Pro Test Store user.
  1. Go through the welcome screen, create a group with 2 or more contacts, write a message and tap Send. There should be no paywall; the explainer appears, then the send loop runs.
  2. Send to at least one recipient. The results sheet shows with a "Keep Sending" button.
  3. Tap it. The closable paywall appears. Swipe it down. You're back on the group screen, and the app is usable: open other groups, edit a group, create a new group.
  4. Tap Send again. The closable paywall shows. Swipe it down; nothing is sent, and the message and recipients are still there.
  5. Kill and relaunch the app. There's **no** lock screen; the groups list shows.
  6. Buy with the Test Store from the Send paywall. The send continues, and later sends need no paywall.
  7. On a fresh install, repeat step 1 but cancel every recipient. There's no results sheet, and the next Send tap is still free.
  8. With the override set, tap Blast on a non-Pro fresh install. The paywall shows.
  9. Run without the override (arm `unloaded` in debug). Tapping Send shows the closable paywall, as it does today.

## Validation Commands

Run all commands after implementation. All must pass.

- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter build ios --no-codesign`
- E2E: the manual simulator steps above, with `fvm flutter run --dart-define=DEBUG_FREE_FIRST_SEND=true`

## Acceptance Criteria

- [ ] With the flag off, unloaded, or PostHog disabled, behaviour is identical to today: the paywall appears at the first Send tap, Blast needs Pro, and the launch gate behaves as now.
- [ ] With the flag on, a non-Pro user who hasn't sent yet completes one regular Send with no paywall and no recipient cap.
- [ ] After that send: results sheet with "Keep Sending", then the **closable** paywall once (`paywall_viewed {trigger: first_send}`).
- [ ] After the free send, the app is never locked, including after a relaunch. Groups, editing and composing all work. Every later Send and every Blast shows the closable paywall until the user has Pro.
- [ ] Users who didn't get the free send keep today's launch gate. A lapsed trial or subscription still locks the app for them.
- [ ] A batch where every recipient was cancelled doesn't use up the free send.
- [ ] Blast is never free.
- [ ] Pro and grandfathered users never trigger a flag read.
- [ ] `send_tapped`, `paywall_viewed` and `first_send_completed` carry `free_first_send` (`on`, `off` or `unloaded`). `send_tapped` also has `paywall_skipped`, and `first_send_completed` has `was_free`.
- [ ] `DEBUG_FREE_FIRST_SEND` is ignored in release builds.
- [ ] `fvm flutter analyze` and `fvm flutter test` pass, and `fvm flutter build ios --no-codesign` succeeds.

## Notes

- **No recipient cap, and no app lock after the free send**, by decision. The user wants the full first send, and wants people to keep the app because they can still use the UI.
- **Lapsed free-send users aren't locked either:**
  - The `usedFreeFirstSend` exemption stays in place for good. A free-send user who later starts a trial and lets it lapse also gets the closable Send paywall instead of the lock.
  - That's consistent with the goal of keeping the app installed, but it does weaken the launch gate for that group.
  - If it matters later, narrow the exemption to "has never had the `pro` entitlement", using RevenueCat `CustomerInfo.entitlements.all`.
- **Reinstall loophole:**
  - The free send is tracked in SharedPreferences, which iOS wipes on delete. A reinstall gives another free send, though it also loses the user's groups.
  - **Out of scope for v1.** Measure it first.
  - If it matters, add a Keychain marker, which survives reinstall: either `flutter_secure_storage` (a new dependency) or a small native method on the existing `com.sendit/messages` channel.
- **Flag timing:** `preloadFeatureFlags` is on by default, and new users take well over the load time to reach Send. Unloaded flags behave as `off`, the safe default. Don't add a blocking wait.
- **The arm can change between taps:** the arm is read on each first-send attempt until a send completes. A flag change in between just applies the new behaviour, and `send_tapped` records the arm that applied.
- **Analysis:** compare by `free_first_send` arm:
  - installs → `send_tapped` → `first_send_completed` → `paywall_viewed` → `purchase_completed`
  - retention: does the app stay installed and get reopened? (`Application Opened` on day 7 and day 30)
  - RevenueCat trial starts and conversions
  - filter on `$app_namespace = com.sent.it`
  - with a few installs a day, expect weeks before the difference is clear
- **PostHog project is shared:**
  - Flags evaluate on person properties, not event properties, so `$app_namespace` can't be used for targeting.
  - Instead, the app sends `app: sent_it` (and `flag_tester: 'true'` in debug with `POSTHOG_FLAG_TESTER=true`) through `setPersonPropertiesForFlags`, which creates no person profile.
  - Every release condition must include `app = sent_it`.
- **Paywall close button:** the Send paywall currently closes only by swiping down. No X appeared in testing; RevenueCat's newer templates take the close button from the dashboard's paywall settings. Turning it on there is a separate dashboard change, not part of this code.
- **Shipping:**
  - Recommend submitting 1.2.4 (build 10) as it is, and shipping this in **1.3.0**.
  - Build numbers must stay at or above 11.
  - Bumping `pubspec.yaml` isn't part of this plan.
- **Out of scope:** a recipient cap, a Keychain marker, RevenueCat Experiments or offering changes, the dashboard close-button setting, and any change to grandfathering.
