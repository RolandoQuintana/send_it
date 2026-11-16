# Free first send (`free-first-send` flag)

With the PostHog flag `free-first-send` on, a non-Pro user's first regular Send goes out without the paywall. There's no recipient cap. Plan: `specs/feature-free-first-send-flag.md`.

## What the user sees

| | Flag off or not loaded | Flag on |
|---|---|---|
| First Send tap | Closable paywall | No paywall; the send loop runs |
| After the first batch | Results sheet ("Done") | Results sheet ("Keep Sending"), then the closable paywall once |
| Later Send or Blast taps | Closable paywall until Pro | Closable paywall until Pro |
| Launch lock (no close button) | Locks anyone who has sent before and isn't Pro | **Never** locks users whose first send was free |
| Blast as the first send | Paywall | Paywall. Blast is never free, because the Shortcut can't report what was sent. |

A batch where every recipient was cancelled doesn't use up the free send.

## How it works

- **Flag read:** `AnalyticsService.freeFirstSendArm()` returns `on`, `off` or `unloaded`. `unloaded` (flags not fetched yet, PostHog off) behaves like `off`.
  - A boolean `true` or the variant `test` counts as `on`.
  - `false`, `control` or any other variant counts as `off`.
- **Who reads the flag:** only users who would otherwise see the Send paywall, so Pro and grandfathered users never log a `$feature_flag_called` exposure.
- **Exemption:** `OnboardingService.hasUsedFreeFirstSend` (prefs key `free_first_send_used`) exempts the user from `SubscriptionGate.isLocked` permanently. It's written before `hasCompletedFirstSend`, so the gate never sees a locked state.
- **Targeting:** the app sends person property `app: sent_it` with every flag request (`setPersonPropertiesForFlags`, so no person profile is created). The project is shared with Scroll Less, so **every release condition must include `app = sent_it`**.

## Events

- `send_tapped`: `free_first_send` (when the flag was read) and `paywall_skipped`.
- `first_send_completed`: `was_free`.
- `paywall_viewed`: `trigger` is one of `send`, `blast`, `first_send` (the offer after the free batch), `launch` or `settings`; `free_first_send` is included when known.
- Super property `free_first_send`: registered once flags load, so it's on every later event.

## Rolling it out

The flag currently targets test installs only: `app = sent_it` AND `flag_tester = true`, at 100%.

- **50/50 test:** add a condition `app = sent_it` at 50% (boolean flag). Or convert it to a multivariate flag with `control`/`test`, or a PostHog Experiment on this key.
- **On for everyone:** a condition `app = sent_it` at 100%.
- **Off:** remove the condition, or disable the flag. Users who already got the free send keep their exemption.
- **Comparing the arms:** compare by `free_first_send`:
  - installs → `send_tapped` → `first_send_completed` → `paywall_viewed` → `purchase_completed`
  - day-7 and day-30 `Application Opened`
  - filter on `$app_namespace = com.sent.it`

## Testing on the simulator with the real flag

PostHog is off in debug builds, so turn it on and mark the install as a tester:

```bash
fvm flutter run --dart-define=POSTHOG_IN_DEBUG=true --dart-define=POSTHOG_FLAG_TESTER=true
```

Leave out `POSTHOG_FLAG_TESTER` to get the real `off` arm. `--dart-define=DEBUG_FREE_FIRST_SEND=true` forces `on` without PostHog (offline). Both overrides are ignored in release builds.

## Known gaps

- **Reinstall resets it.** Deleting the app wipes prefs, giving another free send (and losing the user's groups). If that becomes a problem, add a Keychain marker.
- **Lapsed users stay exempt.** A free-send user whose trial later lapses gets the closable paywall, not the lock.
