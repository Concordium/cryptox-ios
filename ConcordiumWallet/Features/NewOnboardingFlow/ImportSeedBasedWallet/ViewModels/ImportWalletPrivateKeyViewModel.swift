//
//  ImportWalletPrivateKeyViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

final class ImportWalletPrivateKeyViewModel: ObservableObject {
    let onValidPrivateKey: (String) -> Void

    @Published var isValidPhrase: Bool = false
    @Published var currentInput: String = ""
    
    private let recoveryService: RecoveryPhraseServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(recoveryService: RecoveryPhraseServiceProtocol, onValidPrivateKey: @escaping (String) -> Void) {
        self.recoveryService = recoveryService
        self.onValidPrivateKey = onValidPrivateKey
    }
    
    func clearAll() {
        currentInput = ""
        isValidPhrase = false
    }
}
