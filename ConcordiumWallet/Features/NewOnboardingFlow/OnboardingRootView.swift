//
//  OnboardingRootView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 21.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct OnboardingRootView: View {
    let identitiesService: SeedIdentitiesService
    let defaultProvider: ServicesProvider
    
    var onIdentityCreated: () -> Void
    var onAccountInported: () -> Void
    var onLogout: () -> Void
    
    @EnvironmentObject var sanityChecker: SanityChecker
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            ZStack {
                CarouselWelcomeView()
                    .environmentObject(navigationManager)
            }
            .navigationDestination(for: NavigationPaths.self) { destination in
                switch destination {
                case .welcomeScreen:
                    NewWelcomeView()
                        .environmentObject(navigationManager)
                case .restoreExistingWallet:
                    ImportWalletView(defaultProvider: defaultProvider, onAccountInported: onAccountInported)
                case .createNewWallet:
                    PasscodeView(keychain: defaultProvider.keychainWrapper(), sanityChecker: sanityChecker, identitiesService: identitiesService) { pwHash in
                        onIdentityCreated()
                    }
                default:
                    EmptyView()
                }
            }
        }
        .accentColor(.white)
    }
}
