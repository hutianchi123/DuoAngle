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

## Target model

Conceptual model:

```swift
struct AngleTarget: Identifiable, Codable, Hashable {
    let id: UUID
    var angle: Double
    var isEnabled: Bool
}
```

The exact implementation may use SwiftData, UserDefaults/AppStorage, or another lightweight persistence mechanism. Choose based on the target OS and project needs; do not add a database framework merely for complexity.

## Target monitor

The monitor receives live measurements and checks enabled targets.

Responsibilities:

1. Read current angle.
2. Determine whether a target tolerance has been entered.
3. Trigger HapticManager once.
4. Track per-target armed/fired state.
5. Re-arm after leaving the tolerance zone.

Pseudo-flow:

```text
angle stream
    ↓
target monitor
    ↓
within tolerance?
    ├── no → re-arm when appropriate
    └── yes
          ↓
      already fired?
       ├── yes → do nothing
       └── no → haptic + mark fired
```

## Haptics

Use the appropriate public Apple haptic framework available to the target OS.

The HapticManager should be independent of SwiftUI.

The app must remain useful when haptic output is unavailable.

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
