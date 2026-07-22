# Feature: Unified Composer & Keyboard

## Description

Refactor `GroupMessageScreen` so the text input bar, action tray, and variables tray behave as a single unified bottom chrome — similar to iMessage — instead of three independently positioned layers. Enable scaffold-driven keyboard avoidance (`resizeToAvoidBottomInset: true`), use content-driven tray heights, animate tray transitions at 250ms `Curves.easeOut`, and remove all `KeyboardHeightStorage` plumbing.

## User Story

As a group message sender, I want the text field to stay glued above the keyboard and accessory trays so that typing and inserting variables feels natural and uninterrupted.

## Problem / Solution

**Problem:** The composer bar is lifted manually via `Padding(bottom: viewInsets.bottom)` while action/variables trays sit below at fixed heights derived from cached keyboard measurements. `resizeToAvoidBottomInset: false` disables Flutter's built-in keyboard avoidance, causing the input bar to jump while the iOS keyboard animates. A root `GestureDetector` dismisses keyboard on any tap.

**Solution:** Consolidate composer + accessory trays into one `_buildUnifiedBottomPanel()` widget at the bottom of the `Column`. Set `resizeToAvoidBottomInset: true` so the entire panel rides up with the keyboard. Use content-sized trays with `AnimatedContainer` (250ms `Curves.easeOut`). Scope tap-to-dismiss to the contact list only. Delete `KeyboardHeightStorage` and all related capture/threading code.

## Relevant Files

- `lib/screens/group_message_screen.dart` — primary refactor: unified bottom panel, scaffold inset, tray animation, scoped dismiss
- `lib/main.dart` — remove `keyboardHeight` threading, debug UI, `MessageComposer` dead code, `KeyboardHeightStorage` import
- `lib/screens/create_group_screen.dart` — remove keyboard height capture logic and `KeyboardHeightStorage` import
- `lib/services/keyboard_height_storage.dart` — **delete** (entire file)

## New Files

None — all changes are in-place refactors and deletions.

## Implementation Plan

### Foundation
1. Delete `lib/services/keyboard_height_storage.dart`
2. Remove `KeyboardHeightStorage` import and all capture/display helpers from `main.dart`, `create_group_screen.dart`, and `group_message_screen.dart`
3. Remove `keyboardHeight` constructor parameter from `GroupMessageScreen` and stop passing it from `HomePage._openGroup()`

### Core
4. In `group_message_screen.dart` `build()`: set `resizeToAvoidBottomInset: true` on `CupertinoPageScaffold`
5. Extract `_buildUnifiedBottomPanel()` that wraps composer bar + accessory slot in a single widget tree with `SafeArea(bottom: false)`
6. Move composer bar content (media preview row, +/text field/send row) into the top of the unified panel — remove the standalone `Padding(bottom: viewInsets...)` wrapper
7. Refactor `_buildActionButtons()` to be content-driven: remove fixed `height: menuHeight` and `400.0` fallback; let the `Row` of action buttons + `Padding(16)` define intrinsic height
8. Refactor `_buildVariablesList()` to use a modest max height (e.g. `ConstrainedBox(maxHeight: 220)`) instead of keyboard-matched height and `300.0` fallback; keep header + scrollable variable list inside
9. Render action tray and variables tray in a single accessory slot below the composer row inside `_buildUnifiedBottomPanel()`, wrapped in `AnimatedSize` or `AnimatedContainer` with `duration: Duration(milliseconds: 250)` and `curve: Curves.easeOut`
10. Preserve `_toggleActionButtons()` state machine exactly — do not change toggle semantics (keyboard ↔ tray swap, variables sub-navigation, `addPostFrameCallback` + `requestFocus()`)

### Integration
11. Remove root `GestureDetector(onTap: _dismissEverything)` wrapping the scaffold; instead wrap only the `Expanded` contact `ListView` in `GestureDetector(onTap: _dismissEverything)` so composer/tray taps do not dismiss
12. Restructure `build()` `Column` to: `Expanded(contact list with dismiss gesture)` → `_buildUnifiedBottomPanel()` — trays are no longer siblings outside the panel
13. Remove `_captureKeyboardHeight()` method and its call in `build()`; remove debug `print()` statements in `initState()`

### Polish
14. Remove home-screen debug keyboard height text (`if (hasKeyboardHeight())` block in `main.dart` empty state, lines ~252–261)
15. Remove unused `getKeyboardHeight()`, `hasKeyboardHeight()`, `getKeyboardHeightString()` helpers from `HomePage` in `main.dart`
16. Remove unused `MessageComposer` class from `main.dart` (lines ~333+)
17. In `create_group_screen.dart`: remove `keyboardHeight` state field, `_captureKeyboardHeight()`, `_storeKeyboardHeightGlobally()`, and the `_captureKeyboardHeight()` call in `build()`

## Step-by-Step Tasks

Ordered tasks for `/implement` — do not execute during planning.

1. **Delete keyboard height service**
   - Delete `lib/services/keyboard_height_storage.dart`
   - Grep for `keyboard_height_storage` and `KeyboardHeightStorage` — confirm zero remaining references after later steps

2. **Clean up `main.dart`**
   - Remove `import 'services/keyboard_height_storage.dart'`
   - Remove `getKeyboardHeight()`, `hasKeyboardHeight()`, `getKeyboardHeightString()` methods from `_HomePageState`
   - In `_openGroup()`, remove `keyboardHeight: getKeyboardHeight()` from `GroupMessageScreen` constructor
   - Remove the `if (hasKeyboardHeight())` debug text block from empty-state UI (~lines 252–261)
   - Delete the entire `MessageComposer` class (~lines 333–387)

3. **Clean up `create_group_screen.dart`**
   - Remove `import '../services/keyboard_height_storage.dart'`
   - Remove `double? keyboardHeight` field
   - Remove `_captureKeyboardHeight()`, `_storeKeyboardHeightGlobally()` methods
   - Remove `_captureKeyboardHeight()` call from `build()`

4. **Update `GroupMessageScreen` constructor**
   - Remove `final double? keyboardHeight` field and constructor parameter
   - Remove `import '../services/keyboard_height_storage.dart'`
   - Remove debug `print()` block in `initState()` (~lines 52–59)
   - Remove `_captureKeyboardHeight()` method and its call in `build()`

5. **Enable scaffold keyboard avoidance**
   - Change `resizeToAvoidBottomInset: false` → `resizeToAvoidBottomInset: true` on `CupertinoPageScaffold`

6. **Scope tap-to-dismiss to contact list**
   - Remove outer `GestureDetector(onTap: _dismissEverything)` wrapping scaffold
   - Wrap the `Expanded` `ListView.builder` (contact list) in `GestureDetector(onTap: _dismissEverything, behavior: HitTestBehavior.opaque)`

7. **Create `_buildUnifiedBottomPanel()` method**
   - Return a `SafeArea(bottom: false, child: Column(mainAxisSize: MainAxisSize.min, children: [...]))`
   - Top child: composer container (existing decoration, media preview, +/text field/send row) — **no** manual `viewInsets` padding
   - Bottom child: `_buildAccessorySlot()` (new helper, see step 8)
   - Replace the current three sibling widgets (composer `Padding`, `_buildActionButtons()`, `_buildVariablesList()`) with a single `_buildUnifiedBottomPanel()` call at the bottom of the `Column`

8. **Create `_buildAccessorySlot()` with animation**
   - Wrap tray content in `AnimatedSize(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, child: ...)`
   - When `_showVariablesList`: show variables tray
   - Else when `_showActionButtons`: show action tray
   - Else: `SizedBox.shrink()`
   - Only one tray visible at a time (existing state machine already enforces this)

9. **Refactor `_buildActionButtons()` for content-driven height**
   - Remove `menuHeight` calculation (`widget.keyboardHeight`, `KeyboardHeightStorage`, `400.0` fallback)
   - Remove `height: menuHeight` from outer `Container`
   - Keep existing decoration, `Padding(16)`, and `Row` of action buttons unchanged

10. **Refactor `_buildVariablesList()` for modest fixed max height**
    - Remove `menuHeight` calculation and `height: menuHeight`
    - Wrap in `ConstrainedBox(constraints: const BoxConstraints(maxHeight: 220))`
    - Replace inner `Expanded` with a `Flexible` or fixed-height scroll area so the widget works inside `AnimatedSize` without unbounded height errors
    - Keep header, back button, variable items, and `_insertVariable` behavior unchanged

11. **Verify `_toggleActionButtons()` unchanged**
    - Confirm all four branches still work: variables-back, keyboard-dismiss-to-tray, tray-open-to-keyboard, nothing-open-to-tray
    - Confirm + icon logic (`CupertinoIcons.minus` vs `add`) still uses `_showActionButtons || _showVariablesList` with `viewInsets.bottom == 0` check

12. **Run validation**
    - `fvm flutter analyze` — no new issues
    - `fvm flutter test` — all pass

## Testing

- Unit tests for: none required (no existing composer/keyboard widget tests; PRD defers automated tests)
- E2E test (manual on iOS simulator/device):
  1. Open a group → tap text field → verify input bar rises flush above keyboard with no gap
  2. With keyboard open, tap `+` → keyboard dismisses, action tray appears below input bar without composer jump
  3. With action tray open, tap `+` → keyboard opens; tray may remain visible (variables workflow)
  4. Tap Variables → variables tray replaces action tray; tap back → action tray returns
  5. With variables tray open, tap text field → tray stays open; type and insert `{firstname}` variable
  6. Tap a contact row/switch → keyboard stays open; tap contact list empty area → keyboard and trays dismiss
  7. Attach media via Gallery → preview shows; send button enables/disables correctly
  8. Blast shortcut still launches
  9. Home screen empty state shows no "Max keyboard height" debug text

## Validation Commands

Run all commands after implementation. All must pass.

- `fvm flutter analyze`
- `fvm flutter test`

## Acceptance Criteria

- [ ] Tapping the text field raises the unified bottom panel with the keyboard; input bar stays flush above the keyboard
- [ ] Tapping `+` while keyboard is open dismisses keyboard and shows action tray without the composer jumping
- [ ] Tapping `+` while action tray is open focuses text field and shows keyboard (tray may remain open per Q5)
- [ ] Variables tray opens from action tray; back navigation returns to action tray; user can tap text field and keep variables tray open while typing
- [ ] Tapping a contact row does not dismiss keyboard; tapping contact list background dismisses keyboard and closes trays
- [ ] Media preview row, send button enable/disable, variable insertion, Gallery pick, and Blast shortcut all work as before
- [ ] No `KeyboardHeightStorage`, `keyboardHeight` prop, or hardcoded 400/300 tray fallbacks remain
- [ ] Home screen no longer shows debug keyboard height text
- [ ] `fvm flutter analyze` reports no new issues
- [ ] `fvm flutter test` passes

## Notes

**Dependencies:** No new packages. Uses Flutter built-in `MediaQuery.viewInsets`, `resizeToAvoidBottomInset`, `AnimatedSize`, `SafeArea`.

**Risks:**
- `SafeArea` + `viewInsets` may double-count bottom padding — mitigated by `SafeArea(bottom: false)` on unified panel
- `AnimatedSize` inside `Column` with variables list may need `Flexible` instead of `Expanded` to avoid layout errors — test both tray states
- Tray + keyboard simultaneously may feel crowded — content-driven heights keep trays compact; Q5 decision preserves variables workflow

**Out of scope:**
- Native iOS `inputAccessoryView` / platform channels (Path 2)
- Composer visual redesign
- `CreateGroupScreen` / `EditGroupScreen` keyboard UX changes
- Third-party keyboard packages
- Automated widget tests for composer behavior (optional future work)

**Unified bottom panel target structure:**

```
Column(
  Expanded(
    GestureDetector(onTap: _dismissEverything) → ListView (contacts)
  ),
  SafeArea(bottom: false,
    Column(mainAxisSize: min,
      Composer bar (media preview + input row),
      AnimatedSize(250ms easeOut) → accessory slot (action OR variables OR empty)
    )
  )
)
```
