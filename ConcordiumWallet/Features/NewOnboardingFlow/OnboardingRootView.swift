//
//  OnboardingRootView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 21.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct OnboardingRootView: View {
    let keychain: KeychainWrapper
    let identitiesService: SeedIdentitiesService
    let defaultProvider: ServicesProvider
    
    var onIdentityCreated: () -> Void
    var onAccountInported: () -> Void
    var onLogout: () -> Void
    
    @EnvironmentObject var sanityChecker: SanityChecker
    @AppStorage("isAcceptedPrivacy") private var isAcceptedPrivacy = false

    var body: some View {
        ZStack {
            if isAcceptedPrivacy {
                MainPromoView(defaultProvider: defaultProvider, onIdentityCreated: onIdentityCreated, onAccountInported: onAccountInported, onLogout: onLogout)
                    .environmentObject(sanityChecker)
                    .onAppear { Tracker.track(view: ["Home screen"]) }
            } else {
                WelcomeView { isAcceptedPrivacy = true }
                .onAppear { Tracker.track(view: ["Welcome screen"]) }
            }
        }
        .animation(.easeInOut, value: isAcceptedPrivacy)
        .transition(.fade)
    }
}
