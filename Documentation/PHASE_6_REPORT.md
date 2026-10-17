# Duo Angle — Phase 6 Implementation Report

## 1. Implementation summary

Phase 6 adds one voluntary developer-support purchase through StoreKit 2. All measurement, target, and haptic functionality remains free and independent of product loading or purchase state. No subscription, advertisement, external payment method, or permanent entitlement was introduced.

## 2. StoreKit architecture

- `StoreKit/SupportProductConfiguration.swift` centralizes the product identifier.
- `StoreKit/SupportPurchaseService.swift` is the sole StoreKit adapter and maps Apple framework values into small SDK-independent models.
- `StoreKit/SupportProductManager.swift` is a main-actor observable state machine used by the UI.
- `DuoAngleApp` owns one manager. `MainView` starts its unfinished/update processing and injects it into the support sheet.
- StoreKit never participates in hinge measurement, display arrangement, target monitoring, or target haptics.

The service protocol supports deterministic tests for product loading, purchase outcomes, unfinished transactions, update listening, and transaction finishing. The Debug-only UI-test service is selected solely by the existing `-ui-testing-targets` launch argument and is not compiled into Release behavior.

## 3. Product type and identifier

- Identifier: `com.TNTstudio.DuoAngle.support.coffee`
- Intended App Store Connect type: Consumable In-App Purchase
- Local reference/display name: Support Development / 支持开发
- Intended China storefront price: approximately CNY 5, subject to the price points available in App Store Connect

A consumable is the appropriate type because support may be purchased repeatedly and grants no durable entitlement. Apple describes a consumable as depleted after use and purchasable again. App Review Guideline 3.1.1 currently states that apps may use In-App Purchase to let customers tip developers or digital content providers.

## 4. Verified Apple APIs

The installed iOS 27.1 SDK documentation and compiler verified these StoreKit 2 surfaces:

- `Product.products(for:)` asynchronously requests products by identifier.
- `Product.purchase()` returns success, pending, or user-cancelled purchase results and may throw.
- `VerificationResult` distinguishes `.verified` and `.unverified` signed transactions.
- `Transaction.updates` is the long-lived transaction update sequence.
- `Transaction.unfinished` supplies unfinished transactions for launch recovery.
- `Transaction.finish()` asynchronously finishes an eligible verified transaction.
- `Product.displayPrice` supplies Apple-localized storefront pricing.
- `Product.ProductType.consumable` identifies the intended product type.

Primary references:

- https://developer.apple.com/documentation/storekit/in-app-purchase
- https://developer.apple.com/documentation/storekit/product
- https://developer.apple.com/documentation/storekit/transaction
- https://developer.apple.com/documentation/storekit/verificationresult
- https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox

## 5. App Review guideline considerations

The current App Review Guidelines, section 3.1.1, explicitly allow In-App Purchase currencies to enable customers to tip a developer. The app uses Apple IAP only, clearly says that support is voluntary, shows the storefront-localized price, and provides no feature unlock. The product and support flow must be fully configured, functional, and explained in review notes under guideline 2.1 before submission.

Reference: https://developer.apple.com/app-store/review/guidelines/#in-app-purchase

## 6. Localized pricing behavior

The customer-facing button uses `Product.displayPrice`. It never fabricates `¥5`; when no product is available, the button has no price and remains disabled. The CNY 5 value exists only in the local StoreKit test configuration and must be selected separately in App Store Connect.

## 7. Transaction verification

Success is published only for a `.verified` transaction whose product identifier matches the configured support product. Only verified transactions are retained for and passed to `finish()`. Unverified transactions produce a neutral verification failure and are never treated as success or finished by this support subsystem.

The manager stores processed transaction IDs. If `purchase()` and `Transaction.updates` deliver the same transaction, it is finished and presented at most once.

## 8. Purchase state handling

The explicit states are idle, loading product, product available, purchasing, pending, succeeded, failed, and unavailable.

- Loading and purchasing disable repeat taps and show native progress.
- Pending displays `购买正在等待确认` and waits for `Transaction.updates`.
- Cancellation returns silently to the available state.
- Recoverable failures show concise Chinese text without raw StoreKit errors.
- Unavailable product metadata keeps the page accessible, disables purchase, and offers Retry.
- Verified success displays `♥ 感谢支持！` for approximately two seconds, then permits another support purchase.
- No restore button is shown because the only product is consumable and creates no restorable entitlement.

Technical failures are logged by category without product receipts, signed payloads, account data, or other sensitive transaction details.

## 9. Support page UI and copy

The sheet preserves its native navigation title and Done dismissal control. Its centered, scrollable composition uses system typography, semantic colors, an SF Symbols heart, generous whitespace, and a Liquid Glass purchase button. It includes the approved Chinese headline, three body paragraphs, localized-price button, and footer without urgency or sales pressure.

Dynamic Type can expand vertically inside the scroll view. VoiceOver receives a price-bearing purchase label and state-specific loading, pending, success, failure, and unavailable labels. System Light/Dark Mode remains automatic, and Reduce Motion removes state-transition animation.

## 10. StoreKit Configuration setup

`DuoAngle/DuoAngle.storekit` contains one local consumable with the production-intended identifier and a local CNY 5 test price. The shared `DuoAngle` development scheme references it for Run and Test actions. The file sits outside the synchronized app source directory and was verified absent from the built Release app bundle.

Local StoreKit configuration is offline Xcode test data. It does not create an App Store Connect product and its transactions are signed by Xcode, not the App Store. Sandbox and TestFlight use App Store Connect product data and App Store-signed test transactions; production uses live storefront data and real charges.

## 11. Automated test results

XcodeBuildMCP on iPhone Duo / iOS 27.1 Simulator ran 52 tests: 52 passed, 0 failed, 0 skipped.

The 12 new manager tests cover localized product loading, unavailable/retry, verified success and finishing, rejected verification, pending, cancellation, safe purchase errors, duplicate taps, repeat purchases, duplicate transaction delivery, unfinished transactions, listener startup/cancellation, and a product-load/verified-update interleaving. The updated UI test verifies opening/dismissing the sheet, approved Chinese copy, localized price presentation, and a visible synthetic verified-success UI state through a Debug-only deterministic service.

## 12. Simulator observations

- Debug build, install, and launch succeeded through XcodeBuildMCP on iPhone Duo / iOS 27.1.
- The semantic UI snapshot exposed the native sheet dismissal control and the localized accessibility label `支持开发，价格 ¥5.00` in the deterministic Debug UI-test environment.
- The support sheet remained scrollable and the measurement bottom actions remained present.
- The simulator stayed booted between all test passes as requested.
- Xcode's interactive local StoreKit purchase sheet was not exercised because the Xcode MCP workspace-open request required separate user approval. XcodeBuildMCP builds and `simctl` launches do not inject the scheme's StoreKit test session. The configuration is present for a later approved Xcode Run session.
- The automated tests validate the manager and UI against faithful synthetic StoreKit boundary results; they do not execute the production adapter's `Product`, `VerificationResult`, or `Transaction` sequences.
- Simulator testing is not production App Store purchase verification.

## 13. App Store Connect setup instructions

1. Ensure the Paid Apps Agreement is active and required tax and banking information is complete.
2. Open the Duo Angle app record, then Monetization > In-App Purchases.
3. Create one Consumable product with ID `com.TNTstudio.DuoAngle.support.coffee`; the ID cannot be changed after creation.
4. Add at least one localization, using the approved voluntary-support wording and no feature-unlock claim.
5. Select the closest intended CNY 5 price point and review automatically generated storefront prices.
6. Select the appropriate tax category and complete all required product metadata.
7. Attach the required review screenshot and explain in Review Notes that the product is a repeatable voluntary tip with no entitlement or locked functionality.
8. Submit the IAP with the app version as required and keep it visible and functional for App Review.

Apple references:

- https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/
- https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/
- https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-workflow/

## 14. Sandbox testing requirements

After the App Store Connect product and agreements are ready, disable the local StoreKit configuration for the sandbox run, use a Sandbox Apple Account, and verify product metadata, purchase success, cancellation, Ask to Buy/pending completion, interrupted/unfinished delivery, repeat consumable purchases, and localized storefront prices. No sandbox or TestFlight purchase charges the tester. Production testing must not be attempted without explicit authorization.

## 15. Known limitations

- App Store Connect has not been configured or changed by this phase.
- Sandbox, TestFlight, and production transaction paths remain unverified until the product exists externally.
- The interactive local StoreKit payment sheet still needs an approved Xcode MCP/Xcode Run session.
- The production StoreKit adapter still needs a `StoreKitTest.SKTestSession` or approved interactive local StoreKit integration pass covering purchase, interruption/pending completion, unfinished recovery, duplicate delivery, and finish.
- Real iPhone Duo purchase presentation, physical hinge behavior, and target haptics require device testing.
- The existing fully-open to partially-open `ArrangementView` relocation limitation remains unchanged.
- Simulator screenshots may capture the inactive/blurred Duo region as black; semantic UI inspection and UI automation remain usable.

## 16. Readiness for final UI polish

Phase 6 is functionally and architecturally ready for a final device-based UI polish pass after App Store Connect sandbox metadata exists. That later pass should validate actual storefront price length, very large Dynamic Type, VoiceOver announcements, Reduce Motion, both appearances, the StoreKit purchase sheet on each Duo region, and real-device transaction interruption behavior.
