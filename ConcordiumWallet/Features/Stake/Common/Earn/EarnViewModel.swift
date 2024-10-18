//
//  EarnViewModel.swift
//  Mock
//
//  Created by Lars Christensen on 21/12/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import Combine

enum EarnEvent {
    case bakerTapped
    case delegationTapped
}

class EarnViewModel: PageViewModel<EarnEvent> {
    @Published var account: AccountDataType
    @Published var cooldowns: [AccountCooldown]
    @Published var bakingText = ""
    private var cancellables = Set<AnyCancellable>()
    private weak var view: StakeStatusViewProtocol?

    init(account: AccountDataType) {
        self.account = account
        self.cooldowns = account.cooldowns.map({AccountCooldown(timestamp: $0.timestamp, amount: $0.amount, status: $0.status.rawValue)})
    }
    
    func loadMinStake() {
        ServicesProvider.defaultProvider().stakeService().getChainParameters()
            .showLoadingIndicator(in: nil)
            .sink { [weak self] error in
                self?.view?.showErrorAlert(ErrorMapper.toViewError(error: error))
            } receiveValue: { [weak self] chainParameters in
                let minimumEquityCapital = GTU(intValue: Int(chainParameters.minimumEquityCapital) ?? 0)
                self?.bakingText = String(format: "earn.desc.baking.text".localized, minimumEquityCapital.displayValueWithGStroke())
            }
           .store(in: &cancellables)
    }
}
