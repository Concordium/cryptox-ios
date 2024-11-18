//
//  CreateNewIdentityFlow.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI


struct CreateIdentityRootView: View {
    enum ViewState {
        case setupPasscode
        case createSeedPhrase(String)
        case selectIdentityProvider
        case pendingIdentity(IdentityDataType)
    }
    
    let keychain: KeychainWrapperProtocol
    let identitiesService: SeedIdentitiesService
    
    @State var viewState: ViewState = .setupPasscode
    @State var phrase: [String]?
    
    var onIdentityCreated: () -> Void
    
    @EnvironmentObject var sanityChecker: SanityChecker
    @SwiftUI.Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            switch viewState {
                case .setupPasscode:
                    PasscodeView(keychain: keychain, sanityChecker: sanityChecker) { pwHash in
                        self.viewState = .createSeedPhrase(pwHash)
                    }
                    .onAppear { Tracker.track(view: ["Create passcode"]) }
                case .createSeedPhrase(let pwHash):
                    CreateSeedPhraseView(
                        viewModel: .init(pwHash: pwHash, identitiesService: identitiesService),
                        onConfirmed: { phrase in
                            self.phrase = phrase
                            self.viewState = .selectIdentityProvider
                        })
                case .selectIdentityProvider:
                    IdentityVerificationView(viewModel: .init(identitiesService: identitiesService, onIdentityCreated: { newIdentity in
                        self.viewState = .pendingIdentity(newIdentity)
                    }))
                case .pendingIdentity(let identity):
                NewIdentityStatusView(viewModel: .init(identity: identity, identitiesService: identitiesService), onIdentityCreated: onIdentityCreated, onIdentityCreationFailed: { self.viewState = .selectIdentityProvider })
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
                    .font(.callout)
                    .frame(width: 35, height: 35)
                    .foregroundStyle(Color.primary)
                    .background(.ultraThinMaterial, in: .circle)
                    .contentShape(.circle)
            })
            .padding(.top, 12)
            .padding(.trailing, 15)
        }
        .onChange(of: viewState, perform: { newState in
            withAnimation {
                switch newState {
                case .setupPasscode: break
                case .createSeedPhrase:
                    if identitiesService.mobileWallet.hasSetupRecoveryPhrase  {
                        self.viewState = .selectIdentityProvider
                    }
                case .selectIdentityProvider:
                    guard let pendingIdentity = identitiesService.pendingIdentity, pendingIdentity.identityCreationError.isEmpty else { return }
                    self.viewState = .pendingIdentity(pendingIdentity)
                case .pendingIdentity(let identity):
                    if !identity.identityCreationError.isEmpty {
                        self.viewState = .selectIdentityProvider
                    }
                }
            }
        })
    }
}

extension CreateIdentityRootView.ViewState: Equatable {
    static func ==(lhs: CreateIdentityRootView.ViewState, rhs: CreateIdentityRootView.ViewState) -> Bool {
        switch (lhs, rhs) {
            case (.setupPasscode, .setupPasscode): return true
            case (.selectIdentityProvider, .selectIdentityProvider): return true
            case (let .createSeedPhrase(p1), let .createSeedPhrase(p2)): return p1 == p2
            case (let .pendingIdentity(p1), let .pendingIdentity(p2)): return p1.id == p2.id
            default: return false
        }
    }
}
