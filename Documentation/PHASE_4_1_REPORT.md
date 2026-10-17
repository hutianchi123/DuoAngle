# Phase 4.1 — Current Angle Reliability & UI Cleanup

## Original issues and root cause

The **使用当前角度** shortcut became unavailable after ten seconds without a hinge callback, even if the device remained open at the same angle. `CurrentAngleSelection` compared the last callback timestamp with the current time, and `AddAngleView` polled that rule once per second. The system need not repeat callbacks for a stationary hinge, so elapsed time alone did not establish invalidity. The empty target-management screen also exposed both the navigation-bar plus and a redundant centered add button.

## State-based validity and lifecycle

The shortcut now uses the existing `HingeMeasurementManager.snapshot` and is eligible only when the snapshot is available, the status is `partiallyOpen` or `fullyOpen`, and the converted angle is finite and within `0...180°`. The angle is rounded to the nearest integer for the existing wheel and preview. A valid stationary snapshot remains eligible without a timer. Closed, unknown, unavailable, missing, non-finite, and out-of-range snapshots are rejected; the existing neutral **当前角度不可用** explanation remains.

`MainView` already clears the shared manager when `scenePhase` leaves `.active` and when the view disappears. This invalidates the prior observation session, including background transitions. Foreground restoration starts with an unavailable snapshot; the shortcut stays disabled until the existing public hinge callback provides a new valid measurement. Neither a timestamp nor an old snapshot is used to infer a refresh. The editor reads the same manager instance passed through `AngleSettingView`; it does not install another hinge observer. In Simulator, opening the add sheet did not clear the measurement, and posture changes while the sheet was open updated the shortcut.

## Empty-state UI

The centered **添加角度** action was removed. The existing icon and **暂无目标角度** heading remain, with the explanatory text **点击右上角 + 添加目标角度**. The top-right plus remains the sole add action in this screen. Non-empty target rows, editing, toggles, deletion, sorting, and wheel behavior were not redesigned.

## Files changed

- `DuoAngle/DuoAngle/Targets/CurrentAngleSelection.swift`: state-based eligibility, no age limit.
- `DuoAngle/DuoAngle/Features/AddAngleView.swift`: consume the shared snapshot directly without periodic polling; recheck it when applying the shortcut.
- `DuoAngle/DuoAngle/Features/AngleSettingView.swift`: informational empty state and one add entry point.
- `DuoAngle/DuoAngleTests/AngleTargetTests.swift`: stationary, fully open, invalid-state/angle, and session-invalidation regressions.
- `DuoAngle/DuoAngleUITests/DuoAngleUITests.swift`: exact empty-state copy and one add button while retaining target-management flow coverage.
- `Documentation/ARCHITECTURE.md`: record the new validity policy.

## Verification and Simulator observations

XcodeBuildMCP built Debug and Release for iPhone Duo / iOS 27.1. The full suite passed: **22 tests, 0 failures, 0 skipped**. Focused unit tests cover a 30-second-old valid snapshot, `fullyOpen`, closed/unknown/missing/unavailable/NaN/infinite/out-of-range values, clearing the manager, acceptance of a fresh measurement afterward, and duplicate rejection for a selected current angle. Existing store and UI tests cover wheel editing, save/cancel, toggles, deletion, and isolated test storage. The target-management UI test confirms that the top-right plus opens the editor and is the only add button.

In the running Simulator, the shortcut remained enabled after the hinge was held at a partially open 128°; applying it updated both wheel and numeric preview to 128°. Fully open posture applied 180°. Closing the device disabled the shortcut and showed the unavailable explanation. The add sheet remained open and reflected posture changes. The informational empty state and its sole top-right plus were visually checked in Dark Mode, with system colors adapting; the same content was checked in Light Mode. XcodeBuildMCP's test command shut down the Simulator after each run; it was rebooted after each test and left booted at handoff.

## Limitations and Phase 5 readiness

The public Simulator/Device Hub does not reproduce every physical folding or app lifecycle condition. In particular, foreground restoration without hinge motion may not produce an immediate fresh callback; in that case the shortcut correctly remains disabled until one arrives. Real-device stationary and background/foreground behavior remain to be confirmed on hardware. This maintenance change does not address the known fold-region relocation delay or implement Phase 5 monitoring/alerts. The target model and measurement pipeline remain ready for Phase 5 work.
