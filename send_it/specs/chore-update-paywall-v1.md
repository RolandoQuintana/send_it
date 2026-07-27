# Chore: Update RevenueCat paywall — Sent It Paywall v1 (conversion optimization)

## Description

Redesign the published RevenueCat remote paywall **"Sent It Paywall: v1"** to match the conversion-optimized layout and copy provided by the product team. The paywall is the full-app gate for non-pro iOS users (`PaywallView` in `subscription_gate.dart`); most work is **dashboard-side** (RevenueCat Paywall AI Editor via MCP), with small supporting changes for the 3-day annual trial and legal links.

**Why:** The current paywall uses generic copy ("Unlock Sent It Pro"), placeholder "Lorem ipsum" text, wrong footer URLs (RevenueCat defaults), and a suboptimal package layout (monthly → lifetime → annual stack). The new design leads with Sent It's unique value prop (personalized mass iMessages, on-device privacy), anchors annual as the default with savings framing, and adds social proof + trust micro-copy to improve subscription conversion.

**Current RC state (research snapshot):**

| Item | Value |
|------|-------|
| Project | Sent It — `projba51c129` |
| Paywall | Sent It Paywall: v1 — `pwa4f358491d9044ab` |
| Offering | `default` — `ofrngd93b6b0c31` (current, active) |
| Packages | `$rc_monthly` → `sent_it_monthly`, `$rc_annual` → `sent_it_annual`, `$rc_lifetime` → `sent_it_lifetime` |
| Published headline | "Unlock Sent It Pro" |
| Published subhead | "Unlimited group messaging and shortcuts" |
| Annual default | Yes (`is_selected_by_default: true` on `$rc_annual`) — keep |
| 3-day intro offer | **Not configured** — `introductoryOffer: null` in `ios/SentItProducts.storekit`; CTA trial copy depends on this |
| Footer URLs | Wrong — `https://www.revenuecat.com/terms/` and `.../privacy/` |
| Placeholder copy | Multiple "Lorem ipsum" strings in draft/published localizations |
| App gate | `displayCloseButton: false` — user cannot dismiss without purchase/restore (per PRD) |

## Relevant Files

- `ai-docs/revenuecat.md` — RC paywall patterns, product IDs, testing channels
- `ai-docs/asc.md` — ASC App ID `6746167372`; intro offer setup on App Store Connect
- `lib/widgets/subscription_gate.dart` — `PaywallView` full-app gate (`displayCloseButton: false`)
- `lib/constants/subscription_constants.dart` — Privacy Policy URL; add Terms of Use URL when available
- `ios/SentItProducts.storekit` — local StoreKit products; add 3-day free trial on annual for simulator testing
- `specs/prd-subscription-and-lifetime.md` — legal requirements, product model, gate behavior

## New Files

None expected. If Terms of Use URL is created during implementation, only add a constant — no new files.

## Step-by-Step Tasks

### 1. Prerequisite — configure 3-day free trial on annual (ASC + StoreKit)

The target CTA is **"Start 3-Day Free Trial & Continue"**. This only works if `sent_it_annual` has a 3-day introductory free trial in App Store Connect.

1. In **App Store Connect** (app `6746167372`, subscription `sent_it_annual`):
   - Add introductory offer: **Free trial, 3 days**, eligible for new subscribers.
   - Wait for propagation (or use StoreKit file locally meanwhile).
2. Update `ios/SentItProducts.storekit` — set `introductoryOffer` on `sent_it_annual`:
   ```json
   "introductoryOffer" : {
     "internalID" : "<generated>",
     "numberOfPeriods" : 1,
     "paymentMode" : "free",
     "subscriptionPeriod" : "P3D"
   }
   ```
3. Verify RC paywall CTA can use intro-offer template variables (`{{ product.offer_period_with_unit }}`) when annual is selected. If trial is not live yet, use fallback CTA **"Unlock Unlimited Messaging"** until ASC offer is active — do not ship misleading trial copy.

### 2. Resolve Terms of Use URL (legal blocker)

PRD notes Terms of Use (EULA) is still needed for App Review (Guideline 3.1.2).

1. If a TermsFeed EULA URL exists, add to `subscription_constants.dart`:
   ```dart
   static const termsOfUseUrl = '<url>';
   ```
2. If no URL exists yet, create via TermsFeed (same flow as Privacy Policy) **before** publishing the paywall, or use Apple's standard EULA link as interim: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
3. Paywall footer must link:
   - **Privacy Policy:** `https://www.termsfeed.com/live/707a5825-ae79-4e86-9ddc-edeeaeba78a9`
   - **Terms of Use:** value from `termsOfUseUrl` (not RevenueCat defaults)

### 3. Edit paywall via RevenueCat MCP (`edit-paywall-ai`)

Use `edit-paywall-ai` on paywall `pwa4f358491d9044ab` in project `projba51c129`. Poll `get-paywall-ai-task` every 10–15s until complete. Pass structured `app_context`:

```json
{
  "app_identity": {
    "app_name": "Sent It",
    "app_category": "Productivity / Messaging",
    "app_description": "Send personalized mass iMessages individually — no group chats, 100% on-device."
  },
  "brand_identity": {
    "brand_personality_archetype": "Efficient, trustworthy, privacy-first",
    "core_values": ["privacy", "speed", "personalization"]
  },
  "visual_language": {
    "primary_brand_color": "#0fa0ab",
    "palette_mood": "Dark iOS Cupertino — background #1C1C1E, teal accent"
  }
}
```

**Full edit prompt** (include in MCP `prompt` parameter):

> Redesign "Sent It Paywall: v1" for conversion optimization. Dark theme with teal accent #0fa0ab matching the Sent It iOS app.
>
> **Header row:** "Restore Purchases" button on the trailing side. **Remove/hide the close (X) button** — this is a full-app gate with no dismiss.
>
> **Hero:** App icon centered at top (use Sent It app icon from App Store if available).
>
> **Headline (large, outcome-focused):** "Send Personalized Mass iMessages In Seconds — Without Group Chats"
>
> **Sub-headline:** "No messy group chats. No manual copying and pasting."
>
> **Benefit bullets (4 items, checkmark icons):**
> - Dynamic tags (First Name, Custom)
> - Attach photos, videos & media
> - Unlimited groups & individual sends
> - 100% Private — Stays on your device
>
> **Package layout (critical):**
> 1. **Annual (`$rc_annual`)** — large primary card on top, **pre-selected by default**. Badge: "SAVE 58% • MOST POPULAR". Show price "$9.99 / year" with secondary line "$0.83 / mo" (use `{{ product.price_per_period }}` or equivalent). Teal border/highlight fill (#0fa0ab).
> 2. **Monthly (`$rc_monthly`) + Lifetime (`$rc_lifetime`)** — two smaller cards **side by side** below annual. Monthly: "$1.99 / month". Lifetime: "$19.99 once".
>
> **Primary CTA button:** "Start 3-Day Free Trial & Continue" (when annual selected and intro offer exists; otherwise "Unlock Unlimited Messaging"). Use intro-offer-aware template text for trial state.
>
> **Trust micro-copy under CTA:** "🔒 No risk. Cancel anytime in App Store"
>
> **Social proof block:** ★★★★★ "Saved me hours sending event invites!" — Petrus R.
>
> **Footer links:** "Terms of Use • Privacy Policy" with correct Sent It URLs (not revenuecat.com).
>
> **Remove all "Lorem ipsum" placeholder text.** Replace generic "Unlock Sent It Pro" / "Pick the plan" copy throughout.

### 4. Review draft and render screenshot

1. `get-paywall` with `expand: ["components"]` — confirm:
   - No Lorem ipsum remains
   - Package order: annual (top, large, default) → monthly + lifetime (side-by-side)
   - Close/X button removed from layout
   - Footer URLs point to Sent It Privacy Policy and Terms of Use
   - Brand teal `#0fa0ab` on annual card and CTA
2. `render-paywall-screenshot` for visual QA before publish.
3. Compare against the ASCII blueprint in the chore request; iterate with another `edit-paywall-ai` pass if layout diverges (especially side-by-side monthly/lifetime).

### 5. Publish paywall (explicit user approval only)

Per RevenueCat MCP rules: **do not publish proactively**.

1. Present draft screenshot to user for approval.
2. Only when user explicitly approves: `publish-paywall` on `pwa4f358491d9044ab`.
3. Confirm offering `default` still references this paywall (`paywall_id: pwa4f358491d9044ab`).

### 6. App code — minimal constants sync (if Terms URL added)

Only if step 2 adds a Terms URL:

1. Add `termsOfUseUrl` to `lib/constants/subscription_constants.dart` (mirror `privacyPolicyUrl` pattern).
2. Optionally reference in `more_screen.dart` footer if product wants Terms link on More screen too — **optional, out of scope unless trivial**.

**Do not change** `subscription_gate.dart` gate behavior unless user explicitly overrides PRD:
- Keep `displayCloseButton: false` (full-app gate, no dismiss without purchase/restore)
- Do not add custom `purchasePackage` calls alongside `PaywallView`

### 7. Update `ai-docs/revenuecat.md` (brief)

Add a "Paywall copy (v1)" subsection documenting:
- Paywall name/ID
- Headline, bullets, CTA, trial dependency
- Footer legal URLs
- Note that layout changes are remote (no app redeploy needed after publish)

### 8. Manual QA on iOS simulator

1. Run app in debug (Test Store key) or with StoreKit config file attached in Xcode scheme.
2. Confirm paywall renders updated template (not RC fallback default).
3. Verify annual is pre-selected, monthly/lifetime selectable, prices display.
4. If trial configured: CTA reflects 3-day trial for annual selection.
5. Tap Restore Purchases — no crash; existing pro users bypass gate.
6. Confirm Privacy Policy and Terms links open correct URLs.

## Validation Commands

Run all commands after implementation. All must pass.

- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter build ios --no-codesign` (only if `subscription_constants.dart` or StoreKit file changed)

**Manual (required for this chore — dashboard changes are not covered by unit tests):**

- RevenueCat `render-paywall-screenshot` matches approved blueprint
- iOS Simulator: paywall loads with new copy, correct package layout, working Restore
- Footer legal links resolve to Sent It URLs

## Notes

### Close button vs blueprint

The user's ASCII blueprint shows `[X] Close`, but the shipped PRD and `subscription_gate.dart` enforce a **full-app gate with no dismiss** (`displayCloseButton: false`). **Keep no close button** unless the product owner explicitly changes the gate policy. Restore remains required and visible.

### Savings math (58%)

Monthly × 12 = $23.88 vs annual $9.99 → savings ≈ 58%. RC template `{{ product.relative_discount }}` may compute this dynamically; hardcode "SAVE 58%" only if the template cannot express it on the annual badge.

### Trial copy honesty

Do not publish "Start 3-Day Free Trial" until ASC introductory offer is live on `sent_it_annual`. StoreKit config alone is sufficient for local simulator QA; TestFlight/production need ASC.

### Terms of Use blocker

Privacy Policy exists; Terms/EULA does not. Use Apple's standard EULA as interim footer link if TermsFeed doc is not ready, but create a proper TermsFeed EULA before App Review submission.

### No app redeploy for paywall copy

After `publish-paywall`, existing app builds pick up the new paywall remotely via `PaywallView`. App rebuild is only needed for StoreKit trial config or new `termsOfUseUrl` constant.

### RC MCP task IDs

Record the `edit-paywall-ai` task ID and final revision number in the implement PR/commit message for traceability.
