//
//  StakeAmountInputPresenterProtocol.swift
//  ConcordiumWallet
//
//  Created by Ruxandra Nistor on 03/03/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import Combine
import BigInt

enum StakeError: Error, Equatable {
    case minimumAmount(GTU)
    case maximumAmount(GTU)
    case notEnoughFund(GTU)
    case poolLimitReached(GTU, GTU, Bool)
    case feeError
    case internalError
    
    var localizedDescription: String {
        switch self {
        case .minimumAmount(let min):
            return String(format: "stake.inputAmount.error.minAmount".localized, min.displayValueWithGStroke())
        case .maximumAmount(let max):
            return String(format: "stake.inputAmount.error.maxAmount".localized, max.displayValueWithGStroke())
        case .notEnoughFund:
            return "stake.inputAmount.error.funds".localized
        case let .poolLimitReached(_, _, isInCooldown):
            if isInCooldown {
                return "stake.inputAmount.error.amountTooLarge".localized
            } else {
                return "stake.inputAmount.error.poolLimit".localized
            }
        case .internalError:
            return ""
        case .feeError:
            return "stake.inputAmount.error.funds".localized
        }
    }
}

struct BalanceViewModel {
    var label: String
    var value: String
    var highlighted: Bool
}

class StakeAmountInputViewModel: ObservableObject, Equatable, Hashable {
    @Published var title: String = ""
    @Published var fraction: Int = 6
    @Published var transferCost: ValidatorTransferCostOption = .cost(.zero)

    @Published var amountMessage: String = ""
    @Published var amount: Decimal = .zero
    @Published var amountString: String = ""
    @Published var amountDecimal: BigDecimal = .zero
    @Published var hasStartedInput: Bool = false
    @Published var isAmountLocked: Bool = false
    @Published var amountErrorMessage: String?
    @Published var transactionFee: String? = ""
    
    @Published var showsPoolLimits: Bool = false
    @Published var currentPoolLimit: BalanceViewModel?
    @Published var poolLimit: BalanceViewModel?
    
    @Published var isRestakeSelected: Bool = true
    
    @Published var bottomMessage: String = ""
    @Published var isContinueEnabled: Bool = false
    @Published var euroEquivalentForCCD: String = ""

    var account: AccountDataType
    private var cancellables = [AnyCancellable]()

    init(account: AccountDataType) {
        self.account = account
        self.$amount.map {
            TokenFormatter().number(from: $0.toString(), precision: self.fraction) ?? .zero
        }
        .assign(to: \.amountDecimal, on: self)
        .store(in: &cancellables)
        $amountDecimal
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.getEuroValueForCCD()
            }
            .store(in: &cancellables)
    }
    
    func gtuAmount(currentAmount: GTU?, isOnCooldown: Bool) -> Publishers.Map<Published<BigDecimal>.Publisher, GTU> {
        return $amountDecimal.map { amountString in
            if let currentAmount = currentAmount, isOnCooldown {
                return currentAmount
            } else {
                return GTU(intValue: Int(self.amountDecimal.value.description) ?? 0)
            }
        }
    }
    
    func sendAll() {
        self.amountDecimal = .init(BigInt(account.forecastAtDisposalBalance) - BigInt(transferCost.maxCost.intValue), 6)
    }
    
    private func getEuroValueForCCD() {
        let value = Decimal(string: amountDecimal.value.description) ?? 0
        ServicesProvider.defaultProvider().stakeService().getChainParameters()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] chainParameters in
                guard let self = self else { return }
                let microGTUPerEuro = chainParameters.microGTUPerEuro
                var euroEquivalent = value * (Decimal(microGTUPerEuro.denominator) / Decimal(microGTUPerEuro.numerator))
                
                // Round the value to 2 decimal places.
                var roundedValue = Decimal()
                NSDecimalRound(&roundedValue, &euroEquivalent, 2, .plain)
                
                DispatchQueue.main.async {
                    self.euroEquivalentForCCD = NSDecimalNumber(decimal: roundedValue).stringValue
                }
            })
            .store(in: &cancellables)
    }
}

extension StakeAmountInputViewModel {
    // MARK: - Equatable
    static func == (lhs: StakeAmountInputViewModel, rhs: StakeAmountInputViewModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.fraction == rhs.fraction &&
        lhs.transferCost.formattedTransactionFee == rhs.transferCost.formattedTransactionFee &&
        lhs.amountMessage == rhs.amountMessage &&
        lhs.amount == rhs.amount &&
        lhs.amountDecimal == rhs.amountDecimal &&
        lhs.hasStartedInput == rhs.hasStartedInput &&
        lhs.isAmountLocked == rhs.isAmountLocked &&
        lhs.amountErrorMessage == rhs.amountErrorMessage &&
        lhs.transactionFee == rhs.transactionFee &&
        lhs.showsPoolLimits == rhs.showsPoolLimits &&
        lhs.currentPoolLimit?.value == rhs.currentPoolLimit?.value &&
        lhs.poolLimit?.value == rhs.poolLimit?.value &&
        lhs.isRestakeSelected == rhs.isRestakeSelected &&
        lhs.bottomMessage == rhs.bottomMessage &&
        lhs.isContinueEnabled == rhs.isContinueEnabled &&
        lhs.euroEquivalentForCCD == rhs.euroEquivalentForCCD
    }

        // MARK: - Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(fraction)
            hasher.combine(transferCost.formattedTransactionFee)
            hasher.combine(amountMessage)
            hasher.combine(amount)
            hasher.combine(amountDecimal)
            hasher.combine(hasStartedInput)
            hasher.combine(isAmountLocked)
            hasher.combine(amountErrorMessage)
            hasher.combine(transactionFee)
            hasher.combine(showsPoolLimits)
            hasher.combine(currentPoolLimit?.value)
            hasher.combine(poolLimit?.value)
            hasher.combine(isRestakeSelected)
            hasher.combine(bottomMessage)
            hasher.combine(isContinueEnabled)
            hasher.combine(euroEquivalentForCCD)
        }
}

// MARK: -
// MARK: Presenter
protocol StakeAmountInputPresenterProtocol: AnyObject {
	var view: StakeAmountInputViewProtocol? { get set }
    func viewDidLoad()
    func pressedContinue()
    func closeButtonTapped()
}
