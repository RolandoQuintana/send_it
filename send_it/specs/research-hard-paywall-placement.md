# Research: Hard paywall placement — before or after the first send?

> Status: research (no code changed)
> Date: 2026-10-21
> Related: `specs/prd-free-trial.md`, `specs/chore-free-trial.md`, `specs/prd-subscription-and-lifetime.md`, `specs/chore-update-paywall-v1.md`, `app-docs/research/competitor-onboarding/proposal.md` (P-PD-71), commit `19332fb` (PD-133)

## Question

Sent It runs a RevenueCat hard paywall (no close button). Since PD-133 (commit `19332fb`, 2026-10-20) a non-Pro user gets one free batch and the paywall appears **after** that first send completes. Should the paywall instead appear **before** the first send, when the user taps Send on their first group message?

## TL;DR recommendation

**Move the paywall to the Send tap (a hybrid: after the user has built a group and written a message, before the send loop starts), present it modally over the composer so the message survives, and lead with the 3-day free trial that is already live on the annual plan.** Confidence: **moderate-low (about 60/40)**. The public data is thin and none of it tests this exact choice.

The reasons, in order of weight:

1. **For this app the free first send is not a sample. It is the whole job.** Group texting is often occasional (an invite, an announcement). Today the free batch has no recipient cap, and the free state comes back on every reinstall (SharedPreferences). For a meaningful share of users, the paywall then asks them to pay for something they have already finished.
2. **A free trial is live** (ASC intro offer on `sent_it_annual`: `FREE_TRIAL`, `THREE_DAYS`, start 2026-07-27, checked with `asc subscriptions offers introductory list` on 2026-10-21). A paywall at Send is therefore "start a free trial to send this", not "pay before you've seen anything". The user still gets the aha, inside an Apple-managed trial that is limited to one per Apple ID.
3. **The first-party benchmarks put the money on Day 0, and the documented case studies that moved a paywall earlier all report gains.** None of those case studies is a controlled before/after-value test, though (see Evidence).

If the user does not want to give up the free taste, the second-best option is to **keep the paywall after the first send but cap the free batch** (for example, paywall before sending to a group larger than N). That closes the biggest leak without reversing PD-133.

Whichever option ships, the result should be measured (see How to validate). The RevenueCat Experiments + offering-metadata route avoids a PostHog feature flag.

## Current implementation

| Where | What it does |
|---|---|
| `lib/widgets/subscription_gate.dart:23-28` | `isLocked = subscriptionRequired && !hasPro && hasCompletedFirstSend`. A user who never completes a send **never sees the gate**. |
| `lib/widgets/subscription_gate.dart:114-122` | Logs `paywall_viewed` with trigger `first_send`, or `launch` when there is no in-memory send count (a relaunch after the first send). |
| `lib/widgets/subscription_gate.dart:124-139` | `PaywallView(displayCloseButton: false)`: a hard gate. |
| `lib/widgets/subscription_gate.dart:141-150`, banner ~`163-181` | `_FirstSendBanner`: "You just texted N people… Keep sending with Sent It Pro." |
| `lib/screens/group_message_screen.dart:110-129` | `_sendMessages`: validation, then the one-time send-loop explainer (`_confirmSendLoopOnce`, 266-281). **No Pro check.** |
| `lib/screens/group_message_screen.dart:135-231` | Send loop, one `MFMessageComposeViewController` per recipient. **No cap on recipients for the free batch.** |
| `lib/screens/group_message_screen.dart:261-263` | A batch where everything was cancelled does not count (no sheet, no paywall). |
| `lib/screens/group_message_screen.dart:283-315` | `_showResults`: fires `first_send_completed`, `markFirstSendCompleted`, the results sheet with "Keep Sending", `popUntil(isFirst)`, `presentPaywall()`. The gate then swaps in the paywall. |
| `lib/screens/group_message_screen.dart:317-326` | `_ensureProForBlast`: Blast needs Pro up front (modal `RevenueCatUI.presentPaywall(displayCloseButton: true)`, trigger `blast`). |
| `lib/services/onboarding_service.dart:19, 109-117` | `onboarding_has_completed_first_send` in SharedPreferences. It resets on reinstall, which the proposal accepted ("one free batch per install is cheap"). |
| `lib/services/analytics_service.dart:9, 45-72` | PostHog events: `onboarding_welcome_viewed`, `first_group_created`, `first_send_completed`, `paywall_viewed{trigger: first_send\|launch\|blast\|settings}`, `purchase_completed`, `restore_completed`. There is **no `send_tapped` event**. |
| `lib/screens/welcome_screen.dart` | The welcome copy does not mention that the app is paid or has a trial. |

Prior decisions:

- `specs/prd-subscription-and-lifetime.md` (v1): paywall at launch. Prices are $1.99/mo, $9.99/yr and $19.99 lifetime.
- `specs/prd-free-trial.md`: 3-day free trial on annual only. The paywall CTA is "Start 3-Day Free Trial & Continue".
- `app-docs/research/competitor-onboarding/proposal.md`: moved the paywall to after the first send ("users reach the aha… intent to buy is highest"). It left two open questions: a **free batch cap of about 10 recipients** (not implemented) and **App Review** of the post-value hard gate.
- PD-133 and PD-140 shipped in commit `8ff1696` the day before this research, so there is **no production funnel data yet** for the current placement.

## Evidence

Each item is marked **[Primary]** (the publisher's own data or docs), **[Vendor opinion]** (first-party but no data), or **[Secondary/unverified]**.

### Paywall model and timing

1. **[Primary] Hard paywalls convert about 5x better than freemium.** The median Day-35 download-to-paid rate is 10.7% for hard paywalls (top quartile above 20%) and 2.1% for freemium. Year-one retention is about the same (27% vs 28%). RPI at day 60 is $3.09 vs $0.38. Source: RevenueCat, *State of Subscription Apps 2026* — https://www.revenuecat.com/state-of-subscription-apps ; https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026 . *Relevance:* this backs keeping a hard paywall. It compares models, not placements.
2. **[Primary] Day 0 dominates.** About 50.6% of conversions happen on Day 0. The share of trials started on Day 0 is 78% for Productivity and 89.9% for Business. 55.4% of 3-day-trial cancellations happen on Day 0, and 84% happen by Day 1. Source: RevenueCat SOSA 2026 (same URLs). The report's own charts are internally inconsistent in places (one chart says "one-third" of conversions are on Day 0), so read these as directional. *Relevance:* whatever placement we pick has to put the paywall in front of users during their first session. Both options do that for users who reach a send.
3. **[Primary] 89.4% of trial starts happen on Day 0.** Hard paywalls show about 21% higher LTV per subscriber than soft paywalls. Utilities trial users have the highest 12-month LTV ($68.90). Source: Adapty, *State of In-App Subscriptions 2026* — https://adapty.io/state-of-in-app-subscriptions/ .
4. **[Primary, anecdotal] Moving paywalls earlier raised revenue in the documented cases.**
   - Greg moved its paywall from "after adding 5 plants" into onboarding: about 400% more trial sign-ups and sign-up-to-trial up from 3% to 15%. Monetization changed from usage-based to feature-based at the same time, so the effect is confounded.
   - Rootd moved its paywall to the start of onboarding: about 5x revenue.
   - PhotoRoom shows its paywall right after the core action (background removal). No numbers are given.

   Source: RevenueCat, "Optimizing paywall placement" (Meinertzhagen, 2023) — https://www.revenuecat.com/blog/growth/paywall-placement.md
5. **[Primary, anecdotal] FitnessAI (Jake Mor, Superwall) moved its paywall before onboarding.** The share of users who saw the paywall rose 50%, install-to-trial doubled, trial-to-paid stayed flat, and revenue roughly doubled. Mor treats "% of users who see the paywall" as a key metric. Source: https://www.revenuecat.com/blog/paywall-tests-grow-app-revenue/ . The same piece gives Mor's heuristic: if many users drop before the aha, a paywall before it may make sense.
6. **[Vendor opinion] Superwall advises triggering the paywall "shortly after" the aha moment**, with no data, sample sizes or case study attached. Source: Superwall blog (Butz, 2025-08-07) — https://api.superwall.me/blog/superwall-best-practices-winning-paywall-strategies-and-experiments-to
7. **[Secondary/unverified] "Apps that trigger paywalls after a value moment see 2.1x higher trial start rates than immediate hard paywalls" (attributed to Adapty 2026).** I could not find this on Adapty's report page. **Do not rely on it.**
8. **[Primary, anecdotal] A move from hard paywall to freemium in one RevenueCat client cut conversion by more than 50% and was reverted.** Another client gained 75% LTV going freemium, alongside other pricing changes. Source: https://www.revenuecat.com/blog/growth/hard-paywall-vs-freemium.md . *Relevance:* a free unit before the wall pushes the app toward freemium. The effect can go either way and depends on the app.

**What the evidence does not contain:** no first-party, controlled test of "paywall before the core action" vs "paywall right after the first core action" in a utility app. The case studies are early-vs-late (onboarding vs milestone), they are confounded, and they come from vendors that sell paywall tooling. Treat them as a prior, not proof.

### Trial

9. **[Primary, this repo] The trial is live.** ASC intro offer on subscription `6794926795` (`sent_it_annual`): `offerMode: FREE_TRIAL`, `duration: THREE_DAYS`, `startDate: 2026-07-27` (queried 2026-10-21; the offer id encodes territory `US`, and other territories were not checked). The paywall copy is "Start 3-Day Free Trial & Continue" (`ai-docs/revenuecat.md`). Monthly and lifetime have no trial.
10. **[Primary] Short trials convert worse.** Trials of 4 days or less have a median conversion of 25.5%, against 42.5% for 17–32 days. Source: RevenueCat SOSA 2026. *Relevance:* a 3-day trial plus a 55% Day-0 cancellation share means many users who start a trial at Send will send once and cancel. That is roughly what the free first send gives them today, but it is capped at one per Apple ID and it requires a deliberate cancel.

### App Review

11. **[Primary] App Review Guidelines** — https://developer.apple.com/app-store/review/guidelines/
    - **3.1.1:** unlocking functionality must use IAP. Both options comply.
    - **3.1.2(a):** apps that "trick users into purchasing a subscription under false pretenses or engage in bait-and-switch" are removed.
    - **3.1.2(c):** "Before asking a customer to subscribe, you should clearly describe what the user will get for the price."

    I found **no guideline that requires a free taste before a paywall, or that bans a hard gate.** The app already passed review with a launch gate (v1, `prd-subscription-and-lifetime.md`), which is stricter than either option here.
12. **App Review risk, my assessment (not sourced):**
    - **Paywall at Send:** low. The main exposure is a perceived bait-and-switch: the user builds a group, grants Contacts, and writes a message before learning the app is paid, and the welcome screen does not mention price today. Mitigations: a light "Free for 3 days, then $9.99/yr" line on the welcome or Send step, and the RC paywall's 3.1.2(c) disclosures.
    - **Current after-send gate:** also low. The proposal's open question #5 still applies (the reviewer must be able to find the IAP). Settings exposes the paywall (`settings_screen.dart:139`), which covers this.

### Refunds, churn and ratings

13. **[Secondary] Higher refund rates for hard paywalls (5.8% vs 3.4%), attributed to RevenueCat 2025** — https://www.airbridge.io/en/blog/paywall-conversion-structural-decisions . I could not find this on the RevenueCat 2026 pages I read. **Unverified.**
14. **[No data found] Effect on App Store ratings or reviews of "wall before value" vs "taste then wall".** Rootd reported "almost no negative feedback" after moving its paywall early ([Primary, anecdotal], source in item 5). Everything else is folklore.

## Options compared

| | A. After first send (current) | B. Before first send, at Send tap (recommended) | C. After first send, with a free batch cap of N | D. At launch (pre-PD-133) |
|---|---|---|---|---|
| Who sees the paywall | Only users who complete a send (≥1 `sent`) | Everyone who taps Send (a superset of A) | A, plus anyone sending to a group larger than N | Every install |
| User state at the paywall | Job done, rewarded | Invested (group, contacts, message) but not rewarded | Same as A, or same as B for big groups | Nothing invested |
| Value given away | One full batch, **any size**, once per install (reinstall resets) | None without starting a trial (one per Apple ID) | One batch of ≤ N | None |
| Aha before paying | Yes | Yes, inside the 3-day trial | Yes (≤ N) | Yes, inside the trial |
| Fit with episodic use | Weak: the occasional user is done | Strong | Medium | Strong, but high early drop-off |
| Trial interaction | Trial at the wall buys "more sends" | Trial at the wall buys "this send". The CTA lines up with intent | Mixed | Trial before anything |
| Refund / chargeback risk | Lowest (they know the product) | Low: trial-first, Apple-managed cancel | Low | Higher (unverified data, item 13) |
| App Review risk | Low | Low (perceived bait-and-switch unless price is disclosed) | Low | Low (shipped before) |
| Code size | — | Small–medium (see below) | Small | Revert PD-133 |
| Data to date | None (shipped 2026-10-20) | None | None | Pre-PD-140, no funnel events |

## Recommendation

**Option B, paywall at Send tap, with the trial CTA.** Confidence **moderate-low (~60%)**.

**Rationale**

- The product's value is delivered in a single action, and that action is often a one-off. A free first send hands over the complete job, not a preview of it. That is the opposite of apps like PhotoRoom, where one free edit leaves you wanting the next.
- The send loop is unusual (one compose sheet per person), and the strongest argument for A is that users must feel it before paying. With a live free trial, B keeps that "feel it" moment. It just happens inside the trial, so trial starts carry real intent.
- Users who tap Send have already done the hard parts: the Contacts permission, building a group, writing a message. Their intent peaks at the Send tap. B catches them there instead of after the need is met.
- The first-party benchmarks favour hard paywalls and Day-0 capture, and every documented case of moving a paywall earlier reports gains. That fits B but does not prove it (items 4–8).

**Why not more confident:**

- No controlled before/after-aha study exists for a utility app.
- The vendors publishing the case studies sell paywall placement tooling.
- 3-day trials have the weakest trial-to-paid rates and a 55% Day-0 cancellation share, so B may turn many sends into trial-then-cancel.
- PD-133 was a deliberate product bet ("unclaimed position") that has not been measured yet.

**If the user prefers to keep the taste:** ship **Option C** (cap the free batch, for example N = 5–10) instead. It is the smallest change that fixes A's main leak.

## What changes in code if we switch (pointers only, no edits made)

1. **`lib/screens/group_message_screen.dart:110-129` (`_sendMessages`).** After validation, and before or after `_confirmSendLoopOnce` (266-281), add a Pro check modelled on `_ensureProForBlast` (317-326).
   - Present it **modally** (`RevenueCatUI.presentPaywall`) over the composer so the composed message and media survive the purchase, then continue straight into the loop.
   - Do not route through the root gate swap (`popUntil(isFirst)` at 312). That disposes the screen and loses the message.
   - Decide the dismiss behaviour. A hard modal (`displayCloseButton: false`) keeps "hard". Alternatively, mark a "hit paywall" flag so `SubscriptionGate` locks the app on dismissal or relaunch.
2. **`lib/widgets/subscription_gate.dart:23-28` (`isLocked`).** Swap or extend `hasCompletedFirstSend` with a "reached the send paywall" flag, so a user who backs out stays gated on relaunch.
3. **`lib/widgets/subscription_gate.dart:114-122, 141-181`.** The `first_send`/`launch` trigger logic and `_FirstSendBanner` ("You just texted N people…") no longer apply before a send. Change the copy to "Your message to N people is ready" or remove the banner.
4. **`lib/screens/group_message_screen.dart:283-315` (`_showResults`).** The `paywallNext` branch, the `continueLabel: 'Keep Sending'` label and the `popUntil` + `presentPaywall()` calls become dead for non-Pro users. Simplify them. Keep `first_send_completed` analytics.
5. **`lib/services/onboarding_service.dart:19, 109-117`.** Retire or repurpose `markFirstSendCompleted` and `presentPaywall`, or add a `hasHitSendPaywall` key.
6. **`lib/services/analytics_service.dart:9`.** Add a `PaywallTrigger.send` (or `sendTap`) trigger. Add a `send_tapped` event (recipient count, first-time flag) so view rate can be computed.
7. **Option C only:** at `group_message_screen.dart:~129`, if `!hasPro && !hasCompletedFirstSend && recipients.length > N`, show the paywall first ("Send to all 48 with Pro").
8. **Disclosure (App Review hygiene):** add a short trial/price line to `lib/screens/welcome_screen.dart` or the send explainer (`group_message_screen.dart:272-277`).
9. **Tests:** update `test/onboarding_service_test.dart` (it covers `isLocked`) and `test/send_results_test.dart`.

## How to validate

**Metrics (per cohort, by install week):**

- **Paywall view rate** = installs with `paywall_viewed` / installs. B should be higher than A, since every user who reaches a send sees it.
- **View → trial/purchase** (`purchase_completed` / `paywall_viewed`). Use RC data to tell trial starts from paid starts.
- **Trial → paid at Day 4** for the 3-day trial (RevenueCat Charts: Trial Conversion).
- **Install → paid, Day 35**, and **RPI / realized LTV** (RevenueCat Charts). **This is the decision metric.** Conversion rate alone can mislead.
- **Refund rate** (RC Charts), **Day-0 trial cancellations**, and App Store rating trend.
- **Funnel drop-off:** `onboarding_welcome_viewed` → `first_group_created` → `send_tapped` (new) → `paywall_viewed` → `purchase_completed`.

**Is a test worth it?**

- **Sample size.** With an install→paid baseline near the RC hard-paywall median (~10%), detecting a ~30% relative lift (10.7% → 14%) at 95% confidence / 80% power needs roughly **1,500+ installs per arm** (standard two-proportion approximation). Below that volume, an A/B test will not be conclusive in a reasonable time.
- **If volume is low:** ship B (or C) and compare to the A cohort sequentially, with the confounds noted (seasonality, ASO changes).
- **No-PostHog-flag option:** RevenueCat Experiments can drive placement. Create two Offerings that are identical except for offering metadata (for example `{"paywall_timing": "before_send"}` vs `"after_first_send"`), run an Experiment between them, and have the app read `offerings.current.metadata` to choose the placement. RC then reports the full subscription lifecycle (LTV, refunds) per arm. RC staff confirm that placement timing can be tested this way ("just change the logic on when to show it"), and the metadata approach is documented.
  - https://community.revenuecat.com/general-questions-7/how-to-dynamically-configure-when-the-paywall-is-shown-5222
  - https://www.revenuecat.com/docs/tools/offering-metadata
  - https://www.revenuecat.com/docs/tools/experiments-v1

  Caveats:
  - Check that the RC plan includes Experiments.
  - Offerings must be fetched before the first Send tap. The app must have a default for when they are not fetched (fall back to the current behaviour).
  - Do not run it alongside another offering experiment on the same audience.
- **PostHog feature flag:** works too, but RC Experiments measure revenue natively, and PostHog would need RC revenue piped in to do the same.

## Open questions

1. **Volume:** how many installs per week does Sent It get? This decides whether to run an A/B test or a sequential comparison. Check RC Overview or ASC analytics.
2. **Usage pattern:** what share of users send more than once per month? If most users are repeat senders, A's "taste" costs little and the case for B weakens. PostHog will answer this once PD-140 events are in production.
3. **Trial territories:** is the 3-day intro offer configured in all storefronts, or only the US? The `asc` result showed one offer with territory `US`.
4. **Back-out behaviour for B:** if a user dismisses or kills the app at the Send paywall, should the app lock entirely on relaunch (hard) or return to the composer?
5. **Option C's N**, if chosen: 5? 10? It should be small enough that a real group (party, team) needs Pro.
6. **Reinstall loophole:** the free-first-send flag resets on reinstall. Is that acceptable under A or C? It is moot under B, because trials are one per Apple ID.
7. **Disclosure:** should the welcome screen say "3 days free, then $9.99/yr" so the Send-tap paywall is not a surprise (3.1.2(a) perception)?
