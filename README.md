# Duo Angle

An App for iPhone Duo

Duo Angle is a minimalist hinge-angle measuring app for compatible iPhone Duo devices. It reads the system hinge measurement and presents the current angle in an adaptive SwiftUI interface.

## Features

- Live hinge-angle readout and adaptive Duo display placement.
- Multiple locally stored target angles, with enable, edit, and delete controls.
- Haptic feedback when a target angle is reached.
- Optional voluntary developer support through a StoreKit consumable; all app features remain free.
- Automatic system Light and Dark appearance.
- Simplified Chinese, Traditional Chinese, English, Japanese, and Korean UI.
- On-device target storage, with no first-party measurement upload or analytics SDK.

## Technology and requirements

- SwiftUI and StoreKit 2.
- Xcode project: `DuoAngle/DuoAngle.xcodeproj`.
- Deployment target: iOS 27.1, using the system hinge APIs available on supported hardware.
- The iPhone Duo / iOS 27.1 Simulator supports build and UI checks; hinge measurement and haptics require physical supported hardware for validation.

## Build

Open `DuoAngle/DuoAngle.xcodeproj` in Xcode, select the `DuoAngle` scheme, and build for a supported iOS simulator or device. A physical device requires a valid Apple Developer team and provisioning for the existing bundle identifier.

## Privacy

See [Privacy Policy](PRIVACY_POLICY.md) and [English Privacy Policy](PRIVACY_POLICY_EN.md). Target angles are stored locally. Apple processes App Store purchase information through StoreKit. The App Store privacy questionnaire and public contact email still require release-time review.

## Limitations and status

This repository contains release-preparation work in progress. Simulator build and UI checks do not validate real hinge sensors or haptics. No physical Duo validation or App Store submission is claimed. The App Store Connect product localization and signing setup remain subject to account and team readiness.

## License

No open-source license is granted by this repository; source rights remain reserved unless a license is added by the owner.
