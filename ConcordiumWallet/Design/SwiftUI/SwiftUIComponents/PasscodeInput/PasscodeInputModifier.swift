//
//  PasscodeInputModifier.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 16.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

extension View {
    func passcodeInput(
        isPresented: Binding<Bool>,
        keychainWrapper: KeychainWrapperProtocol = ServicesProvider.defaultProvider().keychainWrapper(),
        sanityChecker: SanityChecker = SanityChecker(mobileWallet: ServicesProvider.defaultProvider().mobileWallet(), storageManager: ServicesProvider.defaultProvider().storageManager()),
        onSuccess: @escaping (String) -> Void
    ) -> some View {
        return modifier(PasscodeInput(isPresented: isPresented, keychainWrapper: keychainWrapper, sanityChecker: sanityChecker, onSuccess: onSuccess))
    }
}

struct PasscodeInput: ViewModifier {
    @Binding var isPresented: Bool
    let keychainWrapper: KeychainWrapperProtocol
    var sanityChecker: SanityChecker
    let onSuccess: (String) -> Void
    
    @State var isFullScreenViewVisible = false

    init(isPresented: Binding<Bool>, keychainWrapper: KeychainWrapperProtocol, sanityChecker: SanityChecker, onSuccess: @escaping (String) -> Void) {
        _isPresented = isPresented
        self.keychainWrapper = keychainWrapper
        self.sanityChecker = sanityChecker
        self.onSuccess = onSuccess
    }
    
    func body(content: Content) -> some View {
        if isPresented {
            ZStack {
                content
                PasscodeView(keychain: keychainWrapper, sanityChecker: sanityChecker, onSuccess: {
                    onSuccess($0)
                    isPresented.toggle()
                })
                .overlay(alignment: .topTrailing) {
                    Button(action: { isPresented.toggle() }, label: {
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
            }
        } else {
            content
        }
    }
}
