//
//  ValidatorMetadataViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 20.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Combine
import Foundation
import SwiftUICore

class ValidatorMetadataViewModel: ObservableObject {
    @Published var currentMetadataUrl: String
    @Published var isNoChanges: Bool = false
    let dataHandler: BakerDataHandler
    private let navigationManager: NavigationManager
    
    init(dataHandler: BakerDataHandler, navigationManager: NavigationManager) {
        self.dataHandler = dataHandler
        self.navigationManager = navigationManager
        let currentValue: BakerMetadataURLData? = dataHandler.getCurrentEntry()
        currentMetadataUrl = currentValue?.metadataURL ?? ""
    }
    
    func pressedContinue() {
        self.dataHandler.add(entry: BakerMetadataURLData(metadataURL: currentMetadataUrl))
        
        if dataHandler.containsChanges() || dataHandler.transferType == .registerBaker {
            if case .updateBakerPool = dataHandler.transferType {
                self.navigationManager.navigate(to: .validatorRequestConfirmation(
                    ValidatorSubmissionViewModel(dataHandler: dataHandler,
                                                 dependencyProvider: ServicesProvider.defaultProvider())))
            } else {
                self.navigationManager.navigate(to: .generateKey(
                    ValidatorGenerateKeysViewModel(dataHandler: dataHandler,
                                                   account: dataHandler.account,
                                                   dependencyProvider: ServicesProvider.defaultProvider())))
            }

        } else {
            isNoChanges = true
        }
    }
    
    func noChangesAlertOptions() -> SwiftUIAlertOptions {
        let okAction = SwiftUIAlertAction(
            name: "baking.nochanges.ok".localized,
            completion: nil,
            style: .styled
        )
        return SwiftUIAlertOptions(
            title: "baking.nochanges.title".localized,
            message: "baking.nochanges.message".localized,
            actions: [okAction]
        )
    }
}

extension ValidatorMetadataViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorMetadataViewModel, rhs: ValidatorMetadataViewModel) -> Bool {
        lhs.currentMetadataUrl == rhs.currentMetadataUrl &&
        lhs.isNoChanges == rhs.isNoChanges
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(currentMetadataUrl)
        hasher.combine(isNoChanges)
    }
}
