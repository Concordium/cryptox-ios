//
//  EarnPresenter.swift
//  Mock
//
//  Created by Lars Christensen on 21/12/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import Combine

protocol EarnPresenterDelegate: AnyObject {
    func baker()
    func delegation()
}

protocol StakeStatusViewProtocol: Loadable, ShowAlert {
    func bind(viewModel: LegacyStakeStatusViewModel)
}

class EarnPresenter: SwiftUIPresenter<EarnViewModel> {
    private let account: AccountDataType
    private var delegate: EarnPresenterDelegate?
    weak var view: StakeStatusViewProtocol?
    
    init(
        account: AccountDataType,
        delegate: EarnPresenterDelegate?
    ) {
        self.account = account
        self.delegate = delegate
        super.init(viewModel: .init(account: account))
        
        viewModel.navigationTitle = "earn.title".localized
    }
    
    override func receive(event: EarnEvent) {
        Task {
            switch event {
                case .bakerTapped:
                    delegate?.baker()
                case .delegationTapped:
                    delegate?.delegation()
            }
        }
    }
    
    deinit {
        self.delegate = nil
    }
}
