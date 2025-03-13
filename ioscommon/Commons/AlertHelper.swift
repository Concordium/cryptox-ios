//
//  AlertHelper.swift
//  CryptoX
//
//  Created by Zhanna Komar on 06.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

class AlertHelper {
    static func stopValidationAlertOptions(account: AccountDataType, navigationManager: NavigationManager) -> SwiftUIAlertOptions {
        let goBackAction = SwiftUIAlertAction(
            name: "go.back".localized,
            completion: nil,
            style: .styled
        )
        
        let continueAction = SwiftUIAlertAction(
            name: "continue_btn_title".localized,
            completion: { [weak navigationManager] in
                guard let navigationManager else { return }
                let viewModel = ValidatorSubmissionViewModel(dataHandler: BakerDataHandler(
                    account: account,
                    action: .stopBaking
                ),
                                                             dependencyProvider: ServicesProvider.defaultProvider())
                navigationManager.navigate(to: .validatorRequestConfirmation(viewModel))
            },
            style: .plain)
        
        return SwiftUIAlertOptions(
            title: "validation.stop.title".localized,
            message: "validation.stop.desc".localized,
            actions: [goBackAction, continueAction]
        )
    }
    
    static func suspendAlertOptions(dataHandler: BakerDataHandler, navigationManager: NavigationManager) -> SwiftUIAlertOptions {
        let goBackAction = SwiftUIAlertAction(
            name: "go.back".localized,
            completion: nil,
            style: .styled
        )
        
        let continueAction = SwiftUIAlertAction(
            name: "continue_btn_title".localized,
            completion: { [weak navigationManager] in
                guard let navigationManager else { return }
                let viewModel = ValidatorSubmissionViewModel(dataHandler: dataHandler,
                                                             dependencyProvider: ServicesProvider.defaultProvider())
                navigationManager.navigate(to: .validatorRequestConfirmation(viewModel))
            },
            style: .plain)
        
        return SwiftUIAlertOptions(
            title: "important".localized,
            message: "validation.alert.suspend.desc".localized,
            actions: [goBackAction, continueAction]
        )
    }
    
    static func genericErrorAlertOptions(message: String) -> SwiftUIAlertOptions {
        return SwiftUIAlertOptions(
            title: "errorAlert.title".localized,
            message: message,
            actions: [
                SwiftUIAlertAction(
                    name: "errorAlert.okButton".localized,
                    completion: nil,
                    style: .styled
                )
            ])
    }
}
