# Duo Angle — Phase 7A Implementation Report

## 1. Initial UI audit findings

The audit covered MainView, AngleSettingView, AddAngleView, and SupportDevelopmentView on the booted iPhone Duo / iOS 27.1 Simulator in fully open, partially open, and closed postures, with Light and Dark appearances. XcodeBuildMCP semantic snapshots were available throughout. Its raw screenshot can capture the inactive Duo display as black, so visual inspection also used the rendered device window in Device Hub.

The main measurement screen already preserved the correct single-readout hierarchy, restrained numeric transition, adaptive system arrangement, and fixed bottom actions. The 180° and three-digit readings fit at the default text size. Meaningful issues were:

- The folded/unavailable instruction used a fixed point size and did not participate in Dynamic Type.
- The two bottom actions carried redundant icons despite the text already carrying their meaning.
- The two main Liquid Glass buttons were not grouped in a `GlassEffectContainer`.
- The target list rendered the enabled-count footer as a separate card-like row.
- AddAngleView had no scrollable content region for large accessibility sizes.
- The AddAngleView Save action only drew as an intrinsically sized capsule despite its outer flexible frame, with a visually separate material band.
- At accessibility text sizes, the duplicate-angle validation message could sit below the fixed Save bar and be invisible.

SupportDevelopmentView already had the approved copy, generous spacing, native navigation, a scrollable body, localized StoreKit price, and restrained monochrome purchase treatment. It was left functionally and structurally unchanged.

## 2. Changes actually implemented

### MainView

- Split the available and unavailable readouts into explicit presentation branches.
- Kept the available reading at the established 96-point light monospaced-digit style with minimum scaling and a single line.
- Changed the unavailable/folded instruction to a Dynamic Type-aware title style that wraps without clipping.
- Kept numeric transitions scoped to the available angle text.
- Kept Reduce Motion behavior as identity transitions and no numeric animation.
- Kept the checkmark overlay layout-neutral and unchanged.

### Bottom actions

- Removed the redundant SF Symbols from `设定角度` and `支持开发`.
- Preserved text-only Liquid Glass buttons, 44-point minimum touch targets, and the fixed safe-area bar.
- Wrapped the horizontal and vertical fallback arrangements in native `GlassEffectContainer`s.
- Preserved automatic horizontal-to-vertical adaptation for narrow layouts and large text.

### AngleSettingView

- Kept the native SwiftUI List and empty state.
- Added a native `目标角度` Section header.
- Moved `已启用 N 个目标角度` into the Section footer instead of a card-like content row.
- Preserved angle editing, independent toggles, context-menu deletion, swipe deletion, and sorting.
- Gave the editable angle a 44-point minimum row target.

### AddAngleView

- Kept the native 0°–180° wheel picker, 90° default, numeric preview, current-angle shortcut, duplicate validation, Save, and Cancel behavior.
- Put the content in a vertical ScrollView so accessibility text sizes and short presentation regions can scroll.
- Made Save a full-width native `.glassProminent` primary action using the system accent color.
- Removed the custom material strip behind the Save area.
- Moved validation text into the fixed bottom inset above Save so it remains visible at large text sizes.
- Cleared a prior save failure when the selected angle changes.

## 3. Views and files modified

- `DuoAngle/DuoAngle/Features/MainView.swift`
- `DuoAngle/DuoAngle/Components/BottomActionBar.swift`
- `DuoAngle/DuoAngle/Features/AngleSettingView.swift`
- `DuoAngle/DuoAngle/Features/AddAngleView.swift`
- `DuoAngle/DuoAngleUITests/DuoAngleUITests.swift`
- `Documentation/PHASE_7A_REPORT.md`

No measurement, display-arrangement, target-monitor, haptic, persistence, or StoreKit production logic was changed.

## 4. Typography and spacing improvements

- The main available readout retains its large system font, light weight, monospaced digits, degree symbol, centered layout, and minimum scaling behavior.
- The unavailable instruction now scales with the user's text-size preference and can wrap to two lines.
- Bottom actions retain 44-point minimum heights and adapt from a row to a column when horizontal space is insufficient.
- Target-list rows have a stable 44-point editing target and native inset-grouped rhythm.
- The enabled-target summary now reads as supporting footer copy rather than a second action row.
- AddAngleView retains the large numeric preview and centered native wheel while allowing content to scroll instead of clipping.
- Save has a 50-point minimum label height and consistent 20-point horizontal margins.

## 5. Numeric animation behavior

The main readout continues to use `.contentTransition(.numericText())` with a short 0.1-second linear animation scoped directly to the angle Text. The animation does not include ArrangementView, the action bar, or the wider view hierarchy. When Reduce Motion is enabled, both the content transition and explicit animation become identity/nil.

The AddAngleView preview similarly keeps its 0.12-second numeric-only transition and Reduce Motion fallback.

No concrete animation backlog was observed in the Simulator during discrete posture changes. Continuous high-frequency fold input cannot be represented by Device Hub's discrete posture controls and remains a hardware-test item.

## 6. Liquid Glass consistency

- MainView uses neutral native `.glass` button styles for both actions.
- The two main glass buttons are grouped in `GlassEffectContainer`, matching the iOS 27.1 deployment target.
- AddAngleView uses native `.glassProminent` for its primary Save action and the system accent color.
- SupportDevelopmentView keeps its restrained native `.glass` purchase button tinted with the primary content color.
- Functional-page navigation and validation colors use native semantic/system colors.
- No blur overlay or hand-built Liquid Glass imitation remains in the touched UI.

## 7. Sheet behavior

The native sheet presentation remains unchanged:

- Angle settings opened and dismissed successfully with empty and populated targets.
- AddAngleView opened and dismissed successfully.
- SupportDevelopmentView opened and dismissed successfully.
- The fully open Simulator presented sheets as a centered narrow panel.
- The partially open Simulator placed the sheet in the left visible region.
- The closed posture presented the sheet in the single-screen region.
- No duplicate or overlapping sheets were observed.

In the closed single-screen sheet, iOS 27 placed the target list's trailing `+` control in a floating toolbar region below the navigation title. It remained native and accessible. The app does not override this system placement.

## 8. Accessibility findings

The accessibility tree exposed:

- The current angle as a meaningful current-angle label rather than raw degree notation.
- The target-reached state in the readout's accessibility label while feedback is visible.
- Named bottom actions and sheet dismissal controls.
- Named angle-editing and enabled-state controls for each target.
- A native accessible target-angle wheel.
- The current-angle shortcut with a state-specific hint.
- The localized support price, voluntary-support hint, and state-specific purchase labels.
- The validation message with its full error text and a stable identifier.

The new accessibility regression test launches at `UICTContentSizeCategoryAccessibilityExtraExtraLarge` and verifies:

- Main and sheet primary actions remain hittable.
- The full-width Save action is reachable.
- A duplicate-angle error has non-zero height and remains inside the app window.
- The support purchase control exists and can be made hittable by scrolling.

Reduce Motion paths were inspected in code. Light and Dark appearances were inspected for contrast and legibility. A spoken VoiceOver session and physical haptic perception were not available in this Simulator pass.

## 9. Performance observations

- No additional hinge observer, target observer, StoreKit listener, or sheet presenter was introduced.
- The high-frequency hinge path and TargetMonitor input are unchanged.
- Numeric animation remains attached only to the readout Text.
- The target-list footer is still derived from the small in-memory target array.
- AddAngleView validation remains a constant-time duplicate check.
- No expensive geometry or formatting work was added to MainView body evaluation.
- No visible lag or animation backlog was observed during the discrete posture changes available in Simulator.
- Continuous sampling rate, rapid real fold movement, and battery impact require hardware verification.

## 10. Build and test results

- Debug build and launch through XcodeBuildMCP: succeeded.
- Full regression suite through XcodeBuildMCP: 53 passed, 0 failed, 0 skipped.
- New accessibility UI regression: passed.
- Release simulator build through XcodeBuildMCP: succeeded with no reported warnings.
- The Simulator was left booted after every build and test pass.

## 11. Simulator screenshots and observations

- Fully open, Light Mode: one centered readout; 180° fit without clipping; fixed text-only glass actions remained visually subordinate.
- Partially open, Light and Dark Mode: the readout remained legible and the action bar stayed fixed; the existing horizontal relocation offset remained visible.
- Closed, Light and Dark Mode: the folded instruction wrapped correctly at accessibility text sizes.
- AngleSettingView empty state: remained centered with the top-right `+` as the only add action.
- AngleSettingView populated state: header, row, toggle, and footer read as one native section.
- AddAngleView: the wheel remained centered, Save became a full-width system-blue glass action, and the large-text duplicate error stayed above Save.
- SupportDevelopmentView: approved copy and `¥5.00` localized local StoreKit price were visible; large text remained scrollable and the purchase control remained reachable.
- Target-reached checkmark: not visually reproduced because DeviceHub exposes only discrete large posture jumps and the conservative TargetMonitor rejects those as uncertain crossings. The unchanged feedback state/overlay logic and its unit tests still pass.

## 12. Remaining known limitations

- The existing `fullyOpen -> partiallyOpen` ArrangementView relocation delay is unresolved and intentionally unchanged.
- Simulator posture changes are discrete and do not represent continuous folding or realistic hinge update cadence.
- Physical haptic strength, timing, and real-device VoiceOver behavior were not verified.
- The target-reached checkmark was not captured in a real Simulator target crossing.
- The floating `+` placement in the closed single-screen sheet was observed but not overridden because it is system-managed.
- Real iPhone Duo display visibility, system blur behavior, and scene migration remain hardware-dependent.
- StoreKit purchase execution in this pass used the existing deterministic UI-test service only; no real-money transaction was performed.
- App Store Connect, Sandbox, TestFlight, and production StoreKit paths remain external verification work.

## 13. Phase 7B hardware verification checklist

- Inspect 9°, 45°, 90°, 120°, and 180° at default and accessibility text sizes with the checkmark present.
- Confirm the checkmark never shifts the readout or overlaps the degree symbol in either fold arrangement.
- Exercise slow and fast continuous fold movement and confirm the latest angle remains responsive without animation backlog.
- Enable Reduce Motion and repeat numeric, target-feedback, and sheet transitions.
- Run VoiceOver through MainView, targets, the wheel, Save/Cancel, and every purchase state.
- Verify the fixed bottom actions remain hittable when the system applies dual-display blur.
- Reproduce the `fullyOpen -> partiallyOpen` relocation delay and record timing plus reserved-region state.
- Verify target haptic strength and single-fire hysteresis around ±1° and re-arm near ±3°.
- Test TargetMonitor crossing behavior with realistic timestamps and fast continuous samples.
- Validate sheets and the floating toolbar plus control in each supported physical posture.
- Verify real storefront price length, purchase cancellation/pending/success, and large text on hardware.
- Confirm the app remains responsive while target monitoring and StoreKit transaction updates are active.
