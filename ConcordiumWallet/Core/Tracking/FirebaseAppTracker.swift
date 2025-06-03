//
//  FirebaseAppTracker.swift
//  CryptoX
//
//  Created by Zhanna Komar on 23.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import FirebaseAnalytics

enum FirebaseAppTracker {

    static func installation() {
        // Firebase logs 'first_open' automatically
    }

    static func welcomeScreen() { screenVisit(.welcome) }
    static func welcomeTermAndConditionsCheckBoxChecked() { contentSelection("Terms and Conditions check box", .checkbox) }
    static func welcomeActivityTrackingCheckBoxChecked() { contentSelection("Activity Tracking check box", .checkbox) }
    static func welcomeGetStartedClicked() { contentSelection("Get started", .button) }
    static func welcomeSetUpWalletDialog() { screenVisit(.setUpWalletDialog) }
    static func welcomeSetUpWalletDialogCreateClicked() { contentSelection("Create wallet", .button) }
    static func welcomeSetUpWalletDialogImportClicked() { contentSelection("Import wallet", .button) }
    static func passcodeScreen() { screenVisit(.passcodeSetup) }
    static func passcodeSetupEntered() { input("6-digit passcode") }
    static func passcodeSetupConfirmationEntered() { input("6-digit passcode confirmation") }
    static func passcodeSetupBiometricsDialog() { screenVisit(.passcodeBiometricsDialog) }
    static func passcodeSetupBiometricsAccepted() { contentSelection("Biometrics enable", .button) }
    static func passcodeBiometricsRejected() { contentSelection("Biometrics later", .button) }
    static func seedPhraseScreen() { screenVisit(.seedPhraseSetup) }
    static func seedPhraseCopyClicked() { contentSelection("Phrase copy to clipboard", .button) }
    static func seedPhraseCheckboxBoxChecked() { contentSelection("I backed up my seed phrase", .checkbox) }
    static func seedPhraseContinueClicked() { contentSelection("Phrase continue", .button) }
    static func identityVerificationProvidersListScreen() { screenVisit(.idProviders) }
    
    static func identityVerificationScreen(provider: String) {
        screenVisit(.idVerification, params: ["provider": provider])
    }

    static func identityVerificationResultScreen() { screenVisit(.idVerificationResult) }
    static func identityVerificationResultApprovedDialog() { screenVisit(.idVerificationApproved) }
    static func identityVerificationResultCreateAccountClicked() { contentSelection("Identity verification create account", .button) }
    static func homeScreen() { screenVisit(.home) }
    static func homeSaveSeedPhraseClicked() { contentSelection("Home save seed phrase", .button) }
    static func homeIdentityVerificationClicked() { contentSelection("Home verify identity", .button) }

    static func homeIdentityVerificationStateChanged(state: String) {
        Analytics.logEvent("home_id_verification_state_change", parameters: ["state": state])
    }

    static func homeCreateAccountClicked() { contentSelection("Home create account", .button) }
    static func homeOnrampScreen() { screenVisit(.onramp) }
    static func homeOnrampSiteClicked(siteName: String) { contentSelection("Onramp \(siteName)", .button) }
    static func homeOnrampBannerClicked() { contentSelection("Onramp banner", .banner) }
    static func homeUnlockFeatureDialog() { screenVisit(.unlockFeatureDialog) }
    static func homeTotalBalanceClicked() { contentSelection("Wallet total balance", .label) }
    static func aboutScreen() { screenVisit(.about) }
    static func aboutScreenLinkClicked(url: String) { contentSelection("About: \(url)", .link) }
    static func discoverScreen() { screenVisit(.discover) }

    // MARK: - Helpers

    private static func screenVisit(_ screen: Screen, params: [String: Any]? = nil) {
        var parameters: [String: Any] = [
            AnalyticsParameterScreenName: screen.title,
            AnalyticsParameterScreenClass: screen.slug
        ]
        if let params = params {
            parameters.merge(params) { $1 }
        }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: parameters)
    }

    private static func contentSelection(_ contentName: String, _ contentType: ContentType) {
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemName: contentName,
            AnalyticsParameterContentType: contentType.rawValue
        ])
    }

    private static func input(_ contentName: String) {
        Analytics.logEvent("enter_input", parameters: [
            AnalyticsParameterItemName: contentName
        ])
    }

    private struct Screen {
        let title: String
        let slug: String

        static let welcome = Screen(title: "Welcome", slug: "welcome")
        static let passcodeSetup = Screen(title: "Passcode setup", slug: "passcode_setup")
        static let seedPhraseSetup = Screen(title: "Seed phrase setup", slug: "phrase_setup")
        static let idProviders = Screen(title: "ID Providers", slug: "id_providers")
        static let idVerification = Screen(title: "ID Verification", slug: "id_verification")
        static let idVerificationResult = Screen(title: "ID Verification result", slug: "id_verification_result")
        static let home = Screen(title: "Home", slug: "home")
        static let onramp = Screen(title: "Onramp", slug: "onramp")
        static let about = Screen(title: "About", slug: "about")
        static let discover = Screen(title: "Discover", slug: "discover")
        static let setUpWalletDialog = Screen(title: "Set up wallet dialog", slug: "set_up_wallet_dialog")
        static let passcodeBiometricsDialog = Screen(title: "Welcome: Passcode: Biometrics dialog", slug: "passcode_setup_biometrics_dialog")
        static let idVerificationApproved = Screen(title: "ID Verification approved", slug: "id_verification_approved_dialog")
        static let unlockFeatureDialog = Screen(title: "Home: Unlock feature dialog", slug: "unlock_feature_dialog")
    }

    private enum ContentType: String {
        case checkbox
        case button
        case banner
        case label
        case link
    }
}
