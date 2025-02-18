//
//  ValidatorMainView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 17.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ValidatorMainView: View {
    @ObservedObject var viewModel: ValidatorViewModel
    
    var body: some View {
        VStack {
        }
        .onAppear {
            viewModel.checkStatus()
        }
    }
}

final class ValidatorViewModel: ObservableObject {
    let account: AccountEntity
    let dependencyProvider: ServicesProvider
    var navigationManager: NavigationManager
    
    init(account: AccountEntity, dependencyProvider: ServicesProvider, navigationManager: NavigationManager) {
        self.account = account
        self.dependencyProvider = dependencyProvider
        self.navigationManager = navigationManager
    }
    
    func checkStatus() {
        if dependencyProvider.storageManager().hasPendingBakerRegistration(for: account.address) {
            navigationManager.navigate(to: .validator(.status(.pendingTransfer), account: account))
        } else if let currentSettings = account.baker {
            navigationManager.navigate(to: .validator(.status(.registered(currentSettings: currentSettings)), account: account))
        }
    }
}
