# PRD: Unified Composer & Keyboard

> Status: ready for planning
> Author: Research Agent
> Date: 2026-07-22
> Source: User request — text input and keyboard feel disconnected vs iMessage; pursue Flutter-native Path 1

## Executive Summary

Refactor the group message composer so the text input bar, action tray, and keyboard behave as a single bottom chrome — similar to iMessage — instead of three independently positioned layers. This improves the core messaging flow for send_it users who compose and send group texts daily on iOS.

## Problem Statement

### Current State

On `GroupMessageScreen`, the composer bar, action buttons tray, and variables tray are **sibling widgets** in a `Column`. The composer is lifted manually via `Padding(bottom: viewInsets.bottom)` while trays sit below it at a **fixed height** derived from cached keyboard measurements (`KeyboardHeightStorage`, `widget.keyboardHeight`, or hardcoded fallbacks of 400px / 300px).

`resizeToAvoidBottomInset: false` disables Flutter's built-in keyboard avoidance. Inset changes apply instantly with no animation, so the text field jumps while the iOS keyboard animates in. When action menus are open, composer padding is set to zero and the keyboard is allowed to overlay the UI. A root `GestureDetector` dismisses keyboard and menus on any background tap.

The result feels klunky: the keyboard and textbox do not move as one unit.

### Desired State

Users experience a cohesive bottom panel where:

- The text input bar sits directly above the keyboard or accessory tray at all times
- Opening/closing the keyboard and swapping to the action/variables tray feel like one smooth transition
- The contact list resizes naturally above the unified bottom chrome
- Behavior is consistent with familiar iOS messaging apps (iMessage as reference)

### Why Now

The composer is the primary interaction surface for send_it's core value — blasting group messages. Keyboard friction directly impacts every send flow and was flagged by the product owner during hands-on use.

## Users & Personas

| Persona | Need | Pain Point |
|---------|------|------------|
| Group message sender | Compose and send quickly to many contacts | Input bar and keyboard feel disconnected; jarring layout shifts |
| Power user (variables/media) | Insert variables, attach media, use Blast shortcut | Keyboard ↔ tray swap is disjointed; variables workflow interrupted by layout jumps |
| New user | Intuitive iOS-native feel | Unfamiliar layout behavior vs system Messages app |

## Goals & Non-Goals

### Goals

- Set `resizeToAvoidBottomInset: true` so scaffold resizes with keyboard; unified bottom panel rides up naturally
- Animate tray open/close transitions at 250ms `Curves.easeOut`
- Use content-driven tray heights (not keyboard-matched); remove `KeyboardHeightStorage` and related plumbing
- Preserve existing composer features: text input, media preview, send button, + toggle, action buttons (Gallery, Variables, Blast), variables list
- Preserve existing toggle semantics: + button swaps keyboard ↔ action tray; Variables sub-tray navigates back to action tray
- Preserve variables workflow: tray may remain open when user taps text field to type after inserting a variable
- Pass `fvm flutter analyze` and `fvm flutter test` after implementation

### Non-Goals

- Native iOS `inputAccessoryView` / platform-channel keyboard attachment (Path 2 — defer unless Path 1 is insufficient)
- Redesigning composer visual styling (colors, icons, typography)
- Changing send flow, SMS/shortcut integration, or contact selection behavior
- Applying unified keyboard UX to `CreateGroupScreen` / `EditGroupScreen` (out of scope unless trivial side-effect)
- Adding third-party keyboard packages unless planner determines they are necessary

## User Stories

1. As a group message sender, I want the text field to stay glued above the keyboard so that typing feels natural and uninterrupted.
2. As a group message sender, I want the keyboard to slide in smoothly with the input bar so that the transition doesn't feel jarring.
3. As a power user, I want tapping + to swap the keyboard for the action tray in the same screen region so that attachments and variables feel like keyboard accessories.
4. As a power user, I want to open the variables tray and keep typing so that I can insert variables without the tray closing.
5. As a group message sender, I want tapping the contact list to dismiss the keyboard without accidentally dismissing while interacting with the composer.

## Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-1 | Composer bar and accessory tray(s) are rendered inside a single unified bottom panel widget | must | Replaces current sibling `Padding` + `_buildActionButtons` + `_buildVariablesList` layout |
| FR-2 | `resizeToAvoidBottomInset: true` on `CupertinoPageScaffold`; unified bottom panel moves with scaffold resize | must | Replaces manual composer-only `viewInsets` padding |
| FR-3 | Action buttons tray and variables tray share one accessory slot below the input bar; keyboard may coexist with tray open (variables workflow) | must | Tray ↔ keyboard not always mutually exclusive per Q5 |
| FR-4 | Accessory tray heights are content-driven — action tray sizes to its buttons; variables list uses modest fixed/max height | must | Remove `KeyboardHeightStorage`, hardcoded 400/300 fallbacks, and `keyboardHeight` prop |
| FR-5 | Tray open/close transitions animate at 250ms `Curves.easeOut` | must | Keyboard motion handled by scaffold resize |
| FR-6 | `+` button toggle behavior preserved: keyboard ↔ action tray swap; variables sub-navigation preserved | must | See `_toggleActionButtons` current logic |
| FR-7 | Media preview, send button, contact count badge, and variable insertion continue to work unchanged | must | Regression-sensitive |
| FR-8 | Tapping contact list dismisses keyboard/menus; tapping composer area does not | must | Narrow dismiss target — remove or scope root `GestureDetector` |
| FR-9 | Contact list (`Expanded` list) shrinks when bottom chrome grows | must | Via inset strategy or unified panel pushing content up |
| FR-10 | Remove dev-only keyboard height debug UI from home empty state | must | `main.dart` lines ~252–260; decided in Q6 |
| FR-11 | Remove debug `print()` statements for keyboard height in `GroupMessageScreen` | should | Lines ~52–58 |
| FR-12 | Remove unused `MessageComposer` widget in `main.dart` | should | Dead code |
| FR-13 | Delete `keyboard_height_storage.dart` and remove all imports/capture logic | must | `CreateGroupScreen`, `GroupMessageScreen`, `main.dart` |

## Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-1 | Keyboard open/close animation feels smooth on iOS | No visible gap or overlap between input bar and keyboard during transition |
| NFR-2 | Layout stable across iPhone sizes | Safe Area + home indicator handled correctly |
| NFR-3 | No regression in analyze/test | `fvm flutter analyze` and `fvm flutter test` pass |
| NFR-4 | Minimal diff scope | Changes concentrated in `group_message_screen.dart`; ancillary cleanup in `main.dart` only if needed |

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

## Technical Context

### Existing Patterns

| Pattern | Location | Notes |
|---------|----------|-------|
| Manual `viewInsets` padding on composer only | `group_message_screen.dart:857–865` | Lifts composer independently of trays |
| `resizeToAvoidBottomInset: false` | `group_message_screen.dart:787` | Opts out of scaffold auto-resize |
| Fixed-height trays from cached keyboard height | `_buildActionButtons`, `_buildVariablesList` | Fallbacks: 400.0 / 300.0 |
| Global keyboard height cache | `keyboard_height_storage.dart` | Set from `CreateGroupScreen` and `GroupMessageScreen` |
| `keyboardHeight` prop threaded from `HomePage` | `main.dart:200` | Passed into `GroupMessageScreen` |
| Root tap-to-dismiss | `GestureDetector(onTap: _dismissEverything)` wrapping scaffold | Dismisses keyboard + menus on any tap |
| Unused legacy composer | `MessageComposer` in `main.dart:333+` | Not referenced |

### Relevant Files (Initial)

- `lib/screens/group_message_screen.dart` — primary composer UI, keyboard/tray layout, toggle logic
- `lib/main.dart` — remove `keyboardHeight` threading, debug UI, unused `MessageComposer`
- `lib/screens/create_group_screen.dart` — remove keyboard height capture logic
- `lib/services/keyboard_height_storage.dart` — **delete**

### Dependencies

- Flutter `MediaQuery.viewInsets` + `resizeToAvoidBottomInset: true` — no new packages required
- No third-party SDK changes; no `ai-docs/` files needed

### Constraints

- iOS-focused Cupertino UI (`CupertinoPageScaffold`, `CupertinoTextField`)
- Must use FVM (`fvm flutter`) per project conventions
- Tray animations: **250ms `Curves.easeOut`** (decided Q4)
- Scaffold: **`resizeToAvoidBottomInset: true`** (decided Q1)
- `SafeArea` wrapping the full `Column` may cause double bottom inset — planner should apply `SafeArea(bottom: false)` on keyboard-attached panel or restructure insets

## UX / Design Notes

### Target layout (unified bottom chrome)

```
┌─────────────────────────────┐
│  Navigation bar             │
├─────────────────────────────┤
│                             │
│  Contact list (Expanded)    │
│                             │
├─────────────────────────────┤
│  Unified Bottom Panel       │  ← single widget, moves together
│  ┌─────────────────────────┐│
│  │ Media preview (if any)  ││
│  │ [+] [Text field] [Send] ││
│  ├─────────────────────────┤│
│  │ Keyboard  and/or  Tray    ││  ← tray may stay open with keyboard (Q5)
│  └─────────────────────────┘│
└─────────────────────────────┘
```

### Interaction flows to preserve

1. **Focus text field** → keyboard slot shows iOS keyboard; panel rises with inset
2. **Tap + (keyboard visible)** → keyboard dismisses; content-sized action tray appears below input bar
3. **Tap + (tray visible, no keyboard)** → request focus; keyboard opens; tray may stay open (variables workflow)
4. **Tap Variables** → variables tray replaces action tray (same slot)
5. **Tap back on variables** → action tray returns
6. **Tap contact list background** → dismiss keyboard and close trays
7. **Select Gallery** → close tray, open picker (existing behavior)

### Animation guidance

- `resizeToAvoidBottomInset: true` — keyboard motion via scaffold resize (Q1)
- Tray open/close: `AnimatedContainer` or equivalent at **250ms `Curves.easeOut`** (Q4)
- Tray ↔ keyboard focus swap: preserve `addPostFrameCallback` + `requestFocus()` pattern

## Decisions Log

| # | Decision |
|---|----------|
| Q1 | `resizeToAvoidBottomInset: true` |
| Q2 | Remove `keyboardHeight` prop and `HomePage` threading |
| Q3 | Content-driven tray heights; delete `KeyboardHeightStorage` |
| Q4 | 250ms `Curves.easeOut` for tray animations |
| Q5 | Keep tray open when user taps text field (variables workflow) |
| Q6 | Remove home-screen debug keyboard height text |

## Research Notes

- iMessage attaches input bar to keyboard via UIKit `inputAccessoryView`; Flutter Path 1 approximates with `resizeToAvoidBottomInset: true` and unified layout
- Tray + keyboard coexistence is intentional for variables insertion — not iMessage-identical but better for send_it workflow
- Content-driven tray heights eliminate need for keyboard height caching entirely
- No existing tests cover composer/keyboard behavior — planner should include manual test plan; automated widget tests optional
- `GestureDetector` wrapping entire scaffold is likely causing accidental dismissals and should be scoped to the contact list only

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Animated inset doesn't match iOS keyboard timing | low | Scaffold resize + 250ms easeOut; accept minor mismatch |
| Tray + keyboard open simultaneously feels crowded | med | Content-driven tray height keeps tray compact; revisit Q5 if UX suffers |
| `SafeArea` + `viewInsets` double-count bottom padding | med | Apply `SafeArea(bottom: false)` on bottom panel; test on devices with home indicator |
| `resizeToAvoidBottomInset: true` conflicts with tray swap logic | med | Unified bottom panel design; test all toggle paths |
| Regression in + toggle / variables navigation | high | Preserve `_toggleActionButtons` state machine; test all toggle paths |
| Focus loss during tray ↔ keyboard swap | med | Keep `addPostFrameCallback` + `requestFocus()` pattern |

## Open Questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | Use `resizeToAvoidBottomInset: true` or keep `false` with manual `AnimatedPadding`? | engineer | **resolved: `true`** — scaffold resizes; unified bottom panel rides up naturally |
| 2 | Should `keyboardHeight` prop on `GroupMessageScreen` and threading from `HomePage` be removed entirely once live insets drive layout? | engineer | **resolved: remove** — drop prop and `HomePage` wiring; live insets + storage fallback only |
| 3 | Should `KeyboardHeightStorage` and capture logic in `CreateGroupScreen` be kept, simplified, or removed? | engineer | **resolved: D — content-driven tray height** — action tray sizes to content; variables list uses modest fixed/max height; remove `KeyboardHeightStorage` and all capture logic |
| 4 | What animation duration/curve should we target — fixed 250ms easeOut or attempt to read platform keyboard animation? | engineer | **resolved: 250ms `Curves.easeOut`** — fixed approximation; no platform channel |
| 5 | When action tray is open and user taps text field, should tray stay open behind keyboard (current) or close tray (iMessage closes accessory)? | human | **resolved: keep tray open (current)** — preserves easier variable insertion workflow; revisit if confusing with unified layout |
| 6 | Is removal of home-screen debug keyboard height text in scope for this change? | human | **resolved: yes, remove** — part of `KeyboardHeightStorage` cleanup |

## Handoff to Planner

### Suggested Problem Class

`feature`

### Suggested Planner Prompt

```
/feature Unified composer and keyboard (Flutter Path 1)

Read specs/prd-unified-composer-keyboard.md — all open questions resolved (see Decisions Log).

Goal: Refactor GroupMessageScreen so the text input bar and keyboard/accessory trays behave as one unified bottom chrome.

Decisions to honor:
- resizeToAvoidBottomInset: true
- Remove keyboardHeight prop, KeyboardHeightStorage, and home debug UI
- Content-driven tray heights (not keyboard-matched)
- 250ms Curves.easeOut for tray animations
- Tray may stay open when user taps text field (variables workflow)

Key constraints:
- Preserve all existing composer features and + toggle semantics
- Scope changes to group_message_screen.dart, main.dart, create_group_screen.dart; delete keyboard_height_storage.dart
- Pass fvm flutter analyze and fvm flutter test
```

### Conditional Docs to Load

- `conditional-docs.md`
- `CLAUDE.md`
- `lib/screens/group_message_screen.dart`
- `lib/main.dart`
- `lib/screens/create_group_screen.dart`
