//
//  AccountSettingsPresenter.swift
//  Mock
//
//  Created by Lars Christensen on 29/12/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

protocol AccountSettingsPresenterDelegate: AnyObject {
    func transferFiltersTapped()
    func releaseScheduleTapped()
    func exportPrivateKeyTapped()
    func exportTransactionLogTapped()
    func renameAccountTapped()
}

class AccountSettingsPresenter: SwiftUIPresenter<AccountSettingsViewModel> {
    private let account: AccountDataType
    private var delegate: AccountSettingsPresenterDelegate?
    
    init(
        account: AccountDataType,
        delegate: AccountSettingsPresenterDelegate
    ) {
        self.account = account
        self.delegate = delegate
        super.init(viewModel: .init(account: account))
        
        viewModel.navigationTitle = "accountsettings.navigationtitle".localized
    }
    
    override func receive(event: AccountSettingsLogEvent) {
        Task {
            switch event {
            case .transferFilters:
                delegate?.transferFiltersTapped()
            case .releaseSchedule:
                delegate?.releaseScheduleTapped()
            case .exportPrivateKey:
                delegate?.exportPrivateKeyTapped()
            case .exportTransactionLog:
                delegate?.exportTransactionLogTapped()
            case .renameAccount:
                delegate?.renameAccountTapped()
            }
        }
    }
    
    deinit {
        delegate = nil
    }
}
