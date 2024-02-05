//
//  AccountDetailProxy.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 25.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import Foundation

final class AccountDetailProxy: ObservableObject {
    private weak var coordinator: AccountDetailsCoordinator?
    
    init(coordinator: AccountDetailsCoordinator) {
        self.coordinator = coordinator
    }
}

extension AccountDetailProxy {
    @MainActor func showSettings() { self.coordinator?.showAccountSettings() }
    @MainActor func showSendFunds() { self.coordinator }
}
