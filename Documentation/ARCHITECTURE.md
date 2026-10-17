# Duo Angle — Architecture

## Goals

Keep the codebase small, testable, and easy for Codex to modify.

The app should avoid a giant ContentView/MainView implementation.

## Suggested layers

```text
DuoAngleApp
    │
    ├── AppState
    │
    ├── Measurement
    │      ├── HingeMeasurementProviding
    │      ├── HingeMeasurementManager
    │      └── HingeMeasurementSnapshot
    │
    ├── Display
    │      ├── DuoDisplayManager
    │      └── ActiveRegion/Scene coordination
    │
    ├── Targets
    │      ├── AngleTarget
    │      ├── AngleTargetStore
    │      └── TargetMonitor
    │
    ├── Haptics
    │      └── HapticManager
    │
    ├── StoreKit
    │      ├── SupportProductManager
    │      └── Transaction handling
    │
    └── UI
           ├── MainView
           ├── AngleSettingView
           ├── AddAngleView
           └── SupportDevelopmentView
```

## Measurement abstraction

Phase 0.5 implementation uses this small provider boundary:

```swift
@MainActor
protocol HingeMeasurementProviding: AnyObject {
    var sourceName: String { get }
    var currentMeasurement: HingeMeasurementSnapshot { get }
    var onUpdate: ((HingeMeasurementSnapshot) -> Void)? { get set }
    func start()
    func stop()
}
```

`HingeMeasurementSnapshot` stores the source angle in radians and exposes degrees through Core-owned conversion logic. UIKit types do not cross into Core or UI.

Create a protocol around Apple's real hinge API, as implemented above.

Conceptual interface:

```swift
protocol HingeMeasurementProviding {
    var currentMeasurement: HingeMeasurementSnapshot { get }
    func start()
    func stop()
}
```

This is intentionally conceptual. Codex must adapt it to the actual SDK API.

Snapshot should contain only the information the app needs, such as:

- angle
- hinge state
- availability
- timestamp if required

Do not leak Apple SDK-specific types throughout the UI; the real provider is the only layer that imports and reads `UIHinge`.

`MockHingeMeasurementProvider` remains a Phase 0.5 test utility, but the Phase 1 app entry no longer injects it. `MainView` observes the public SwiftUI `onHingeChange` modifier and forwards SDK-independent radians/status values through `SwiftUIHingeAdapter` into an observable `HingeMeasurementManager`. The active app never presents mock measurements.

## Angle math

`AngleMath` is the single conversion boundary for radians/degrees, normalization, and physical-range clamping. Raw measurement precision is retained; formatting belongs to presentation only.

## Display abstraction

Phase 2 uses `DuoDisplayManager` as a small SwiftUI presentation boundary. It hosts the single measurement view as the primary content of an `ArrangementView` with the public `.overlay` style and an empty secondary view. SwiftUI responds to the available scene geometry and fold division; the app does not derive a display side from hinge degrees or maintain a second layout state machine. `MainView` still owns measurement and Debug diagnostics independently of this boundary.

The public SDK exposes division and occlusion reserved regions but no system blur or physical-display visibility state. Placement on a real Duo remains subject to hardware verification. Do not attempt to defeat system blur with private APIs.

## Target model and persistence (Phase 4)

The implemented model uses integer degrees and a centralized `0...180` valid range:

```swift
struct AngleTarget: Identifiable, Codable, Hashable {
    let id: UUID
    var angle: Int
    var isEnabled: Bool
}
```

`DuoAngleApp` owns one observable `AngleTargetStore` and passes it through `MainView` to the target-management sheet. The store serializes `[AngleTarget]` with `Codable` into UserDefaults, validates loaded data, and exposes sorted `targets` plus `enabledTargets` for Phase 5. A corrupt payload is preserved and blocks writes until the user explicitly confirms recovery.

`CurrentAngleSelection` consumes the existing measurement snapshot. It converts with `AngleMath`, rounds to an integer, and accepts only available, finite `0...180°` readings in a partially or fully open state. A stationary reading does not expire by age. `MainView` clears the shared `HingeMeasurementManager` when its scene becomes inactive or its view disappears, so a new observation context needs a new valid callback before the shortcut is available. The wheel editor owns a separate selection state and never changes the measurement pipeline.

## Target monitor (Phase 5)

`TargetMonitor` is a UIKit- and SwiftUI-independent value-type state machine. `MainView` passes it the same precision-preserving `HingeMeasurementSnapshot` received by the existing `onHingeChange` pipeline plus the store's enabled targets and an observation-session UUID. It never observes the hinge itself.

Each target UUID owns an independent awaiting-baseline/armed/fired state. The centralized defaults are an inclusive ±1° hit tolerance, an inclusive ±3° re-arm distance, a provisional 0.35-second maximum crossing interval, and a provisional 12° maximum crossing displacement. The first valid sample of a session or changed target establishes state without emitting an event. Invalid, closed, unknown, inactive, and ended observations discard crossing continuity.

`TargetMonitor` emits logical `TargetReachedEvent` values only. `TargetAlertCoordinator` deterministically chooses at most one event per update by nearest measured angle and UUID tie-break, then applies a 0.5-second output cooldown without changing monitor state. `HapticManager` implements the injected `TargetHapticProviding` boundary with UIKit's public `UINotificationFeedbackGenerator` success feedback. The selected event also drives a cancellable, 0.5-second layout-neutral checkmark overlay in `MainView`.

## Haptics

`HapticManager` uses UIKit's public `UINotificationFeedbackGenerator.notificationOccurred(.success)` API behind a testable protocol. It is independent of SwiftUI and logical target state, and unsupported hardware simply produces no physical feedback while event processing and visual confirmation continue.

## StoreKit 2

StoreKit code should be isolated from the measurement system.

The measurement feature must never await StoreKit before becoming usable.

Purchase manager responsibilities:

- load product
- expose localized display price from StoreKit
- initiate purchase
- verify transaction
- finish transaction
- handle cancellation/pending/failure
- observe transaction updates

Never hard-code a localized currency display if StoreKit can provide the actual product price.

The desired business price is ¥5, but App Store Connect price availability must be verified.

## State management

Prefer modern Swift Observation / SwiftUI state mechanisms supported by the target OS.

Avoid global singletons unless technically necessary.

Keep UI state separate from hardware state.

## Testing

### Unit tests

Test:

- target matching
- tolerance
- hysteresis
- duplicate target behavior
- re-arming
- folded/unavailable presentation state
- persistence serialization

### Integration/device tests

Must verify on actual Duo hardware:

- live angle updates
- folding transitions
- screen/region migration
- system blur behavior
- haptic timing
- fully open angle
- nearly closed angle
- rapid angle changes

### StoreKit testing

Use StoreKit Configuration for local purchase testing before App Store Connect production testing.

## API safety rule

Any code involving Duo-specific APIs must include a short comment identifying the verified Apple API and SDK availability.

If Codex cannot verify an API in the installed SDK/documentation, it must stop and report the uncertainty rather than creating a guessed implementation.
