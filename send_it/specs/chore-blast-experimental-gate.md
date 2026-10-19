# Chore: Gate Blast behind Experimental toggle in More

## Description

Move **Sent It Blast** behind an opt-in **Experimental** section on the More screen. Users must enable Blast with a toggle before they see the shortcut install UI or the **Blast** action in the composer’s `+` tray.

**Why:** Blast is unreliable at scale (Shortcuts timeouts, Messages throughput limits — see `specs/prd-blast-scale-testing.md`). Surfacing it as experimental sets expectations and keeps the default composer tray simpler until the user opts in.

**Behavior:**

| State | More screen | Composer `+` tray |
|-------|-------------|-------------------|
| Toggle **off** (default) | Experimental section: toggle + disclaimer only — **no** shortcut install card | Gallery + Variables only — **no** Blast |
| Toggle **on** | Same as today: shortcut install card (`_ShortcutSection` or `_DiagnosticShortcutSection` when `BLAST_DIAGNOSTICS`) + existing how-it-works / install copy | Gallery + Variables + **Blast** |

**Copy requirements:**

- New section header: **Experimental** (replaces current **Shortcuts** header).
- Toggle row title: **Sent It Blast** (or **Enable Blast** — implementer may use either; prefer **Sent It Blast** to match product name).
- Persistent disclaimer in the Experimental section (visible whether toggle is on or off):

  > This feature is experimental. It may not work reliably for large groups or with certain types of media.

- When toggle is **on**, show the **existing** shortcut description / how-it-works / install button unchanged (plus disclaimer above or integrated — do not remove install flow copy).

**Out of scope:** Changing Blast send logic, shortcut assets, chunking fix, or diagnostic TestFlight build flag behavior beyond applying the same experimental gate.

## Relevant Files

- `lib/screens/more_screen.dart` — Experimental section, toggle, conditional shortcut card, disclaimer copy; rename section from Shortcuts → Experimental
- `lib/screens/group_message_screen.dart` — Conditionally render Blast button in `_buildActionButtons()` (~line 532)
- `lib/services/shortcut_service.dart` — Existing `SharedPreferences` pattern for blast install keys; optional home for prefs key constant
- `lib/main.dart` — Initialize new service at startup if using a `ChangeNotifier` singleton (mirror `SubscriptionService`)
- `test/shortcut_service_test.dart` or new test file — Preference / gate unit tests
- `conditional-docs.md` — Persistence + shortcuts references apply
- `specs/prd-blast-scale-testing.md` — Context for experimental disclaimer wording (reference only)

## New Files

- `lib/services/blast_feature_service.dart` — Persisted `isBlastEnabled` toggle + `ChangeNotifier` so More and composer stay in sync

## Step-by-Step Tasks

### 1. Add `BlastFeatureService` (persisted toggle)

1. Create `lib/services/blast_feature_service.dart`:
   - Singleton `BlastFeatureService.instance`
   - `static const _prefsKey = 'blast_experimental_enabled'`
   - `bool _enabled = false` (default **off**)
   - `bool get isEnabled => _enabled`
   - `Future<void> initialize()` — load from `SharedPreferences` (call from `main.dart` before `runApp`, same pattern as other services)
   - `Future<void> setEnabled(bool value)` — persist + `notifyListeners()`
   - Extend `ChangeNotifier`

2. Do **not** store install state here — keep `ShortcutService.isBlastInstalled` / `markBlastInstalled` as-is.

### 2. More screen — Experimental section

1. In `MoreScreen`, convert to listen to `BlastFeatureService` (add listener in `initState` / remove in `dispose`, `setState` on change) — mirror `_MoreScreenState` + `SubscriptionService` pattern.

2. Replace `const _SectionHeader(label: 'Shortcuts')` with `const _SectionHeader(label: 'Experimental')`.

3. Add `_ExperimentalBlastSection` widget (or inline) containing:
   - **Disclaimer** text (grey, 14pt, matches existing body style):
     *"This feature is experimental. It may not work reliably for large groups or with certain types of media."*
   - **CupertinoListTile** or row with title **Sent It Blast** + **CupertinoSwitch** bound to `BlastFeatureService.isEnabled` / `setEnabled`
   - **If `isEnabled`:** render existing shortcut UI below the toggle:
     - `ShortcutService.isBlastDiagnosticsEnabled` → `_DiagnosticShortcutSection`
     - else → `_ShortcutSection`
   - **If not enabled:** omit shortcut install card entirely

4. Keep `_ShortcutSection` and `_DiagnosticShortcutSection` internals unchanged except optionally adding one line to their description referencing experimental status (not required if section-level disclaimer is sufficient).

### 3. Composer — hide Blast in action tray

1. In `group_message_screen.dart`, add `BlastFeatureService` listener in `initState` / `dispose` (same as More screen).

2. In `_buildActionButtons()`, only include the Blast `_buildActionButton` when `BlastFeatureService.instance.isEnabled` is true.

3. If user disables Blast while tray is open with Blast visible, next `setState` from listener hides it; if tray is open, optionally close tray on disable (nice-to-have, not required).

4. No change to `_sendViaShortcut` guard logic beyond tray visibility — direct navigation edge cases are out of scope.

### 4. App startup

1. In `main.dart`, `await BlastFeatureService.instance.initialize()` before `runApp` (alongside other async init if present).

### 5. Unit tests

1. Add `test/blast_feature_service_test.dart` (or extend existing test file):
   - Default `isEnabled` is `false` after init with empty prefs
   - `setEnabled(true)` persists and updates getter
   - `setEnabled(false)` persists

   Use `SharedPreferences.setMockInitialValues({})` in `setUp`.

2. Optional: widget test that action tray excludes Blast when disabled — only if straightforward; not required for chore completion.

### 6. Diagnostic TestFlight builds

Apply the **same experimental gate** to diagnostic and production builds. Testers enable Blast in More like any user. Do not auto-enable for `BLAST_DIAGNOSTICS`.

## Validation Commands

Run all commands after implementation. All must pass.

- `fvm flutter analyze`
- `fvm flutter test`
- `fvm flutter build ios --no-codesign`

**Manual QA:**

- [ ] Fresh install / toggle off: More shows Experimental + disclaimer + switch only; no Install Shortcut card
- [ ] Toggle off: composer `+` tray has Gallery + Variables only
- [ ] Toggle on: More shows Install Shortcut (or Diagnostic) card with existing copy
- [ ] Toggle on: Blast appears in `+` tray; send flow unchanged
- [ ] Toggle off after enabling: Blast disappears from tray; install card hidden
- [ ] Kill and relaunch app: toggle state persists
- [ ] TestFlight diagnostic build (`BLAST_DIAGNOSTICS=true`): same gate applies

## Notes

### UX details

- Default **off** for new and existing users (existing users must opt in once — acceptable for experimental gate).
- Section header **Experimental** leaves room for future experimental features under the same header later; for v1 only Blast lives here.
- Use `CupertinoSwitch` (not Material `Switch`) for iOS consistency with the rest of the app.

### Tray layout

With Blast hidden, `_buildActionButtons` Row has two buttons (Gallery, Variables). No spacer changes required unless layout looks unbalanced — keep minimal diff.

### Relationship to scale-testing / diagnostics work

- Experimental disclaimer aligns with known large-group and media limitations from blast scale testing.
- Diagnostic logging chore (`specs/chore-blast-testflight-diagnostics.md`) remains valid; this chore adds a product-level gate for all builds.

### No new constants file required

Prefs key can live on `BlastFeatureService`; no `dart-define` flag needed.

## Handoff to Implement

```
/implement specs/chore-blast-experimental-gate.md
```
