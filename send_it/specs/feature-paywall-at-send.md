# Feature: Hard paywall on the first Send tap

## Description
Move the hard paywall from *after* the first send to the moment a non-Pro user taps **Send**. The RevenueCat remote paywall opens as a modal over the composer, so the message, media and recipient selection stay in place. Once the user subscribes or starts the 3-day trial, the send carries on right away. If they close the paywall, they land back in the composer with everything intact.

Also add a `send_tapped` PostHog event so we can measure how many users reach the Send button. Right now that's invisible, and every paywall-placement decision depends on it.

Background and evidence: `specs/research-hard-paywall-placement.md`. In short, the free first batch has no recipient cap, and the free state resets on reinstall. Many group-texting jobs are one-offs, so the free send often finishes the job before the paywall ever shows. Users who tap Send have peak intent, and the annual plan's 3-day free trial (Apple intro offer) means they still see the send loop work before they pay.

## User Story
As a new Sent It user who has built a group and written a message, I want to start my free trial right when I hit Send and have my message go out straight after, so that I can try the app on a real send without losing what I wrote.

## Problem / Solution
**Problem:** Non-Pro users get one unlimited send for free, and the paywall only appears after it (`SubscriptionGate.isLocked` needs `hasCompletedFirstSend`). Users whose need ends after one batch never convert. A reinstall clears SharedPreferences and gives them another free send. We also can't see how many users reach Send, so the funnel from group created to paywall has a gap.

**Solution:**
- **Paywall at Send:** Add a check at the top of the send flow, modelled on `_ensureProForBlast`. Non-Pro users get `RevenueCatUI.presentPaywall(displayCloseButton: true)` over the composer. The send only goes ahead if `hasPro` is true when the paywall closes.
- **No free send:** The free first send is gone.
- **Launch gate stays:** `SubscriptionGate` keeps locking the app at launch for non-Pro users who have completed a send. That now covers lapsed trials and users who got a free send under the old build.
- **Remove dead code:** The paywall handoff after the send goes, along with its banner and the locked results sheet.
- **New event:** Fire `send_tapped` on every valid Send tap.

## Relevant Files
- `lib/screens/group_message_screen.dart` — `_sendMessages` (~110–265) is the send loop. `_confirmSendLoopOnce` (~267–281) shows the one-time explainer. `_showResults` (~283–315) holds the paywall handoff after the send, which this feature removes. `_ensureProForBlast` (~317–326) is the pattern to copy.
- `lib/widgets/subscription_gate.dart` — the launch gate. `isLocked` (~23–28) stays as is. `firstSendCount` handling and `_FirstSendBanner` (~114–182) go. `paywallViewed` trigger choice (~115–121) gets simpler.
- `lib/services/onboarding_service.dart` — remove `firstSendCount` and `presentPaywall`, keep `markFirstSendCompleted` (now called for every first send that delivers, not only non-Pro ones), and update its doc comments.
- `lib/services/analytics_service.dart` — add `send` to `PaywallTrigger`, drop `firstSend`, and add `sendTapped(...)`.
- `lib/screens/group_message/send_results_sheet.dart` — remove `continueLabel` and `dismissible` (the locked sheet that led on to the paywall).
- `lib/services/subscription_service.dart` — the `hasPro` and `isSubscriptionRequired` getters; it's a `ChangeNotifier` that updates after a purchase or restore.
- `lib/screens/settings_screen.dart:139-140` — reference for modal paywall analytics plus `presentPaywall`.
- `ai-docs/revenuecat.md` — remote paywall "Sent It Paywall: v1" on offering `default`. Its CTA already depends on trial eligibility ("Start 3-Day Free Trial & Continue" when eligible, "Unlock Unlimited Messaging" when not), so leading with the trial needs **no app or dashboard change**.
- `test/onboarding_service_test.dart` — tests for `firstSendCount` and `isLocked`.
- `test/send_results_test.dart` — results sheet tests (none cover `continueLabel` today; check after the removal).
- `app-docs/` — feature docs for `/document` after shipping.

## New Files
- `test/send_paywall_test.dart` — unit tests for the new pure decision helper (`SubscriptionGate.needsPaywallToSend`) and for `AnalyticsService` trigger naming, if that can be tested without PostHog.

## Implementation Plan

### Foundation
1. **Decision helper:** add a pure static `SubscriptionGate.needsPaywallToSend({required bool subscriptionRequired, required bool hasPro})`, which returns `subscriptionRequired && !hasPro`. Keep it next to `isLocked` so both gate rules live in one place and stay testable.
2. **Analytics updates:**
   - Add `PaywallTrigger.send`.
   - Remove `PaywallTrigger.firstSend`. Its only caller is the banner path, which goes away. Older events keep their value in PostHog.
   - Add `sendTapped({required int recipientCount, required bool hasMedia, required bool isFirstSend, required bool hasPro})`, which captures `send_tapped` with `recipient_count`, `has_media`, `is_first_send` and `has_pro`. Send no PII (no names, numbers or message text), as the class doc requires.

### Core
3. **Send-time paywall:** add `Future<bool> _ensureProForSend()` to `_GroupMessageScreenState`, modelled on `_ensureProForBlast`:
   - Return true straight away if `needsPaywallToSend` is false.
   - Otherwise log `paywallViewed(PaywallTrigger.send)`, `await RevenueCatUI.presentPaywall(displayCloseButton: true)`, and return `SubscriptionService.instance.hasPro`.
   - It must not clear the controller or media, or move away from the composer.
4. **Wire it into `_sendMessages`.** Order of steps:
   1. The existing empty-message and no-recipient checks (unchanged).
   2. `AnalyticsService.instance.sendTapped(...)`, so the event fires for every valid tap, Pro or not, and the funnel denominator is complete.
   3. `if (!await _ensureProForSend() || !mounted) return;` (the paywall).
   4. `_confirmSendLoopOnce()`, the "One Text per Person" explainer, which still shows once before the first loop.
   5. The send loop.

   Put the paywall before the explainer so it lands at the moment of intent, and so a user who backs out never uses up the one-time explainer.
5. **Simplify `_showResults`:**
   - Keep `firstSendCompleted` analytics on the first send.
   - Call `onboarding.markFirstSendCompleted()` whenever `!onboarding.hasCompletedFirstSend` (no longer only when `paywallNext`), so a lapsed trial still hits the launch gate.
   - Remove `paywallNext`, the `continueLabel` argument, the `popUntil` and the `onboarding.presentPaywall()` call.
   - Always show the ordinary dismissible results sheet.

### Integration
6. **`OnboardingService`:**
   - Change `markFirstSendCompleted` to take no `sentCount`. Remove `_firstSendCount`, the `firstSendCount` getter and `presentPaywall()`.
   - `markFirstSendCompleted` should now call `notifyListeners()` itself. Nothing waits on a sheet any more, and the gate won't lock in that session for a Pro user anyway.
   - Update the class and method doc comments: the first send no longer "turns on" the paywall; it marks the user as one the launch gate applies to once they're not Pro.
7. **`SubscriptionGate`:**
   - Remove the `firstSendCount` banner branch and `_FirstSendBanner`.
   - Always log `paywallViewed(PaywallTrigger.launch)`.
   - Update the class doc: non-Pro users pay at their first Send tap, and the launch gate catches anyone who has sent before but lost Pro (lapsed trial or subscription, or a free send under an older build).
   - Leave `isLocked` unchanged.
8. **`send_results_sheet.dart`:** remove the `continueLabel` parameter from `showSendResults` and `dismissible` from `SendResultsSheet`, so the sheet is always dismissible with a "Done" button. Update the doc comments.

### Polish
9. **Live updates:** while the composer is open, make sure the screen notices `SubscriptionService` changes. Purchasing inside the modal should update `hasPro` before `presentPaywall` returns. If it doesn't do so reliably, read `hasPro` after a fresh `SubscriptionService.instance.refresh()`, or whatever refresh method exists; check the service before choosing.
10. **Tests:** update `test/onboarding_service_test.dart`. Remove the `firstSendCount` expectations, adjust the `markFirstSendCompleted` call signature, and keep the `isLocked` group. Add `needsPaywallToSend` cases: required and not Pro gives true; Pro gives false; not required gives false.
11. **Grep for leftovers:** `firstSendCount`, `presentPaywall()` (the onboarding one, not `RevenueCatUI.presentPaywall`), `PaywallTrigger.firstSend`, `continueLabel`, `Keep Sending`. Nothing should remain.

## Step-by-Step Tasks
Ordered tasks for `/implement`. Do not run them during planning.

1. **Helper:** in `lib/widgets/subscription_gate.dart`, add the static `needsPaywallToSend({required bool subscriptionRequired, required bool hasPro})` next to `isLocked`, with a one-line doc comment.
2. **Analytics:** in `lib/services/analytics_service.dart`, change `PaywallTrigger` to `{ send, launch, blast, settings }` and add `sendTapped(...)` that captures `send_tapped` with `recipient_count`, `has_media`, `is_first_send` and `has_pro`.
3. **Paywall method:** in `lib/screens/group_message_screen.dart`, add `_ensureProForSend()` next to `_ensureProForBlast`. It logs `PaywallTrigger.send`, calls `RevenueCatUI.presentPaywall(displayCloseButton: true)`, and returns `SubscriptionService.instance.hasPro`. Give it a short doc comment in the file's style, e.g. "Non-Pro users subscribe or start the trial here; closing the paywall leaves the message as it was."
4. **Wire it in:** in `_sendMessages`, after the two validation notices, call `sendTapped` (recipients = `selectedContacts.length`, `hasMedia` = `_selectedMedia.isNotEmpty`, `isFirstSend` = `!OnboardingService.instance.hasCompletedFirstSend`, `hasPro` = `SubscriptionService.instance.hasPro`). Then run the `_ensureProForSend` guard, then the existing `_confirmSendLoopOnce` guard.
5. **Results:** rewrite `_showResults`. It logs `firstSendCompleted` and calls `markFirstSendCompleted()` when it's the first send, then calls `showSendResults(context, summary: summary)`. Remove the `SubscriptionGate.isLocked` call there, and remove the import if nothing else uses it (it's still needed for `needsPaywallToSend`).
6. **Onboarding:** in `lib/services/onboarding_service.dart`, remove `_firstSendCount`, `firstSendCount` and `presentPaywall()`. Change `markFirstSendCompleted()` to take no arguments and call `notifyListeners()` after setting the flag. Update the doc comments.
7. **Launch gate:** in `lib/widgets/subscription_gate.dart`, remove the `firstSendCount` branch and `_FirstSendBanner`, always return `paywall`, and log `PaywallTrigger.launch`. Update the class doc comment. Remove any imports that are no longer used (`app_surfaces`/`app_text` are still used by the API-key error view, so check before removing).
8. **Results sheet:** in `lib/screens/group_message/send_results_sheet.dart`, remove `continueLabel` from `showSendResults` (always `barrierDismissible: true`, label `'Done'`) and remove `dismissible` from `SendResultsSheet` along with any branches that read it. Update the doc comments.
9. **Settings call site:** check whether `settings_screen.dart` or anything else calls `showSendResults` or the onboarding `presentPaywall`, and fix any call sites.
10. **Onboarding tests:** update `test/onboarding_service_test.dart` for the new `markFirstSendCompleted()` signature and the removed `firstSendCount`. Add a `SubscriptionGate.needsPaywallToSend` group with three cases.
11. **Results tests:** update `test/send_results_test.dart` if it builds `SendResultsSheet` with `dismissible`, or calls `showSendResults` with `continueLabel`.
12. **Leftover check:** grep `lib/` and `test/` for `firstSendCount`, `PaywallTrigger.firstSend`, `continueLabel`, `Keep Sending` and `onboarding.presentPaywall`. Expect zero matches.
13. **Validate:** run the validation commands below and fix anything that fails.
14. **Simulator check:** run the manual E2E check below on the iOS simulator with the StoreKit config file (`ios/SentItProducts.storekit`), so the trial CTA can be tested.

## Testing
- **Unit tests for:**
  - `SubscriptionGate.needsPaywallToSend` (3 cases).
  - `SubscriptionGate.isLocked`: existing cases unchanged.
  - `OnboardingService.markFirstSendCompleted()` persists `hasCompletedFirstSend` across a simulated relaunch and notifies listeners.
  - `SendResultsSheet` still renders a "Done" button and the headline.
- **E2E test** (manual, iOS simulator, fresh install, StoreKit file with the annual intro offer):
  1. Fresh install, then finish the welcome screen, grant contacts, create a group with 2+ contacts, and open it. The prefilled sample message is selected.
  2. Edit the message and attach a photo, then tap **Send**. The RevenueCat paywall opens as a modal over the composer, with the CTA "Start 3-Day Free Trial & Continue" and a close button.
  3. Close the paywall. You're back in the composer with the edited message, the photo and the selected recipients all unchanged. The app is not locked, and the "One Text per Person" explainer has **not** appeared.
  4. Tap **Send** again. The paywall shows again.
  5. Start the trial (StoreKit sandbox). The paywall closes, the "One Text per Person" explainer appears, then the Messages compose sheets open one per recipient.
  6. Send to all. The results sheet is dismissible with **Done** (no "Keep Sending"), and dismissing it stays on the group screen with no paywall.
  7. Kill and relaunch. The app opens normally (trial active, so `hasPro` is true).
  8. Expire or cancel the trial in the StoreKit transaction manager and relaunch. The launch gate shows the full-screen paywall with no banner.
  9. Pro user check: with an active entitlement, tapping Send goes straight to the explainer or loop with no paywall.
  10. Blast/Shortcut send for a non-Pro user still shows the paywall through `_ensureProForBlast` (unchanged).
- **Analytics check** (debug build with a PostHog key): steps 2 and 4 each log `send_tapped` with `has_pro: false` and `is_first_send: true`, plus `paywall_viewed {trigger: send}`. Step 5 logs `purchase_completed`, and after the loop logs `first_send_completed`.

## Validation Commands
Run all commands after implementation. All must pass.

- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter build ios --no-codesign`, a sanity build. No native changes are expected, but the paywall and gate are iOS-only code paths.

## Acceptance Criteria
- [ ] A non-Pro iOS user who taps Send with a valid message and at least one recipient sees the RevenueCat paywall as a modal over the composer before any Messages sheet opens.
- [ ] Closing the paywall leaves the message text, attached media and recipient selection unchanged, and does not lock the app or show the send explainer.
- [ ] Subscribing or starting the trial in that modal carries the send on (explainer once, then the send loop) with no extra tap.
- [ ] Pro and grandfathered users never see the Send paywall.
- [ ] The paywall CTA leads with "Start 3-Day Free Trial & Continue" for trial-eligible users. This comes from the existing remote paywall; no new paywall is published.
- [ ] After any send, the results sheet is the ordinary dismissible "Done" sheet. No "Keep Sending", no `popUntil`, no in-session gate swap.
- [ ] The launch gate still locks non-Pro users who have completed a send before (lapsed trial, lapsed subscription, or a free send under a previous build). It shows no first-send banner.
- [ ] Every valid Send tap captures `send_tapped` with `recipient_count`, `has_media`, `is_first_send` and `has_pro`, and no PII.
- [ ] Send-time paywall views capture `paywall_viewed` with `trigger: send`. `first_send` is no longer emitted.
- [ ] Blast/Shortcut sends behave exactly as before.
- [ ] `fvm flutter analyze`, `fvm flutter test` and `fvm flutter build ios --no-codesign` all pass.

## Notes
- **Decision on backing out (research open question #4):** closing the paywall returns the user to the composer, and the app stays browsable (groups, settings). Every Send tap is gated, so the paywall is still hard for the thing the app does. Locking the whole app after a dismissal would throw away the composed message, which this feature is meant to keep.
- **Existing users:** non-Pro users who already used the free send under the old build keep hitting the launch gate (unchanged). Non-Pro users who installed but never sent will meet the paywall at Send. Grandfathered paid-download users are unaffected (`hasPro` is true).
- **Trial copy:** handled entirely by the remote paywall's trial-eligible CTA (`ai-docs/revenuecat.md`). The trial was confirmed live in ASC for the US only (research doc). Users in other countries see the non-trial CTA. Check other territories in ASC before relying on the "try it free" story everywhere.
- **Risk:** RevenueCat's 2026 data shows 55% of 3-day trial cancellations happen on the first day. Expect some users to start a trial, send once, and cancel. Measure install to paid at Day 35 and revenue per install, not trial starts.
- **Measuring it:** compare weekly cohorts (installs → `send_tapped` → `paywall_viewed{send}` → `purchase_completed`) against the cohorts that shipped with PD-133. A RevenueCat Experiment driven by Offering metadata is possible later, but out of scope here.
- **Welcome screen price disclosure** ("3 days free, then $X/yr") is recommended by the research to head off any bait-and-switch feeling, but it's **out of scope**. Track it as a separate small issue.
- **Free recipient cap (fallback option):** out of scope. This feature replaces the free send.
- **Linear:** project P-PD-78 "Decide Hard Paywall Placement".
