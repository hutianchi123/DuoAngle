# App Store privacy disclosure checklist

Based on the current source audit; re-check before submission.

- [ ] Complete the public contact email in both privacy policies.
- [ ] Host `PRIVACY_POLICY.md` at a stable public URL and enter it in App Store Connect.
- [ ] Review App Privacy answers against Apple's current questionnaire. The app itself stores target angles on device and receives StoreKit product/transaction verification results; Apple handles App Store account and payment processing. Do not report unverified categories or claim that no information is processed.
- [ ] Confirm StoreKit product metadata and its translations in App Store Connect.
- [ ] Confirm the privacy manifest is included in the built app and its required-reason API declaration matches actual API use.
- [ ] Re-audit if network APIs, analytics/advertising SDKs, account features, or data sharing are added.

## Code audit snapshot

No first-party network request API, third-party SDK, analytics/tracking code, camera/microphone permission, device identifier access, or data-sharing feature was found in the app source. Target angles are stored in `UserDefaults`; hinge measurements are processed in memory. StoreKit 2 handles the optional support purchase. OSLog records hinge status changes and StoreKit error types without recording angle values.
