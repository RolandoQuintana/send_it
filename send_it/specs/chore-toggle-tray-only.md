# Chore: Toggle action tray only (+/− does not control keyboard)

## Description

Revise the `+`/`−` button on `GroupMessageScreen` so it toggles the accessory tray only — not the keyboard. This supersedes the PRD's original Q5 toggle semantics (keyboard ↔ tray swap via `+`).

**New behavior:**

| Control | Action |
|---------|--------|
| `+` (tray closed) | Open action tray; dismiss keyboard if visible |
| `−` (tray open) | Close action tray **and** variables tray |
| Text field tap | Focus keyboard; tray **stays** open (variables mid-edit workflow) |
| Contact list tap | Dismiss keyboard + close trays (unchanged) |
| Gallery / Blast | Close tray on action (unchanged) |
| Variables back chevron | Return to action tray (unchanged) |

**Why:** The previous `_toggleActionButtons` treated `+` as a keyboard/tray swap (including `requestFocus()` when the tray was open). That conflated two concerns. Tray visibility and keyboard focus should be independent; users open the tray with `+`, close it with `−`, and use the text field to bring up the keyboard without collapsing the tray.

## Relevant Files

- `lib/screens/group_message_screen.dart` — `_toggleActionButtons`, `+`/`−` icon logic in `_buildUnifiedBottomPanel`

## New Files

None.

## Step-by-Step Tasks

1. **Rewrite `_toggleActionButtons()`** (lines ~320–345) to tray-only semantics:
   - Compute `trayOpen = _showActionButtons || _showVariablesList`.
   - If `trayOpen`: set `_showActionButtons = false` and `_showVariablesList = false`. Do **not** call `requestFocus()` or otherwise open the keyboard.
   - If `!trayOpen`: set `_showActionButtons = true`, `_showVariablesList = false`, and call `_dismissKeyboard()` if `MediaQuery.of(context).viewInsets.bottom > 0`.
   - Remove the variables-list branch that navigates back to action tray on toggle (back chevron handles that).
   - Remove `WidgetsBinding.instance.addPostFrameCallback` + `_textFieldFocusNode.requestFocus()`.

2. **Update `+`/`−` icon and color logic** in `_buildUnifiedBottomPanel` (lines ~547–548):
   - Replace the compound condition `(_showActionButtons || _showVariablesList) && viewInsets.bottom == 0` with tray visibility only: `_showActionButtons || _showVariablesList`.
   - `−` (teal) when tray is open; `+` (grey) when tray is closed — regardless of keyboard state.

3. **Leave unchanged** (verify only, no edits unless accidentally broken):
   - `_dismissEverything()` — contact list background tap
   - Gallery / Blast `onTap` handlers that set `_showActionButtons = false`
   - Variables back chevron that sets `_showVariablesList = false; _showActionButtons = true`
   - `CupertinoTextField` `onTap` comment/behavior (do not collapse menus)

## Validation Commands

Run all commands after implementation. All must pass.

- `cd send_it && fvm flutter analyze`
- `cd send_it && fvm flutter test`

## Notes

- **Supersedes PRD Q5 toggle semantics** for the `+` button only. Q5's "tray stays open when user taps text field" is preserved; the `+` button no longer opens the keyboard.
- **Manual test checklist** (no automated widget tests exist for this flow):
  1. Tap text field → keyboard opens; `+` still shown (tray closed).
  2. Tap `+` with keyboard open → keyboard dismisses, action tray opens, `−` shown.
  3. Tap `−` → tray closes, `+` shown; keyboard stays dismissed.
  4. Open tray, tap Variables → variables tray; tap `−` → both trays close.
  5. Open variables tray, tap back chevron → action tray (not closed).
  6. Open tray, tap text field → keyboard opens, tray stays visible, `−` still shown.
  7. Tap contact list background → keyboard + trays dismiss.
  8. Gallery / Blast from action tray → tray closes, action proceeds.
- Scope is **only** `group_message_screen.dart`; do not update PRD/feature spec docs in this chore unless asked separately.
