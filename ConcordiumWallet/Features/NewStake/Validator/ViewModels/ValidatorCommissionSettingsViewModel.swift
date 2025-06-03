//
//  BakerCommissionSettingsViewModel.swift
//  ConcordiumWallet
//
//  Created by Milan Sawicki on 06/11/2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Combine
import Foundation
import SwiftUICore

extension NumberFormatter {
    static var commissionFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.multiplier = 100
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 3
        formatter.decimalSeparator = "."
        return formatter
    }
}

enum BakerCommissionSettingError: LocalizedError {
    case transactionFeeOutOfRange
    case bakingRewardOutOfRange
    case networkError(Error)

    var errorMessage: String {
        switch self {
        case .bakingRewardOutOfRange:
            return "Baking reward is out of specified range"
        case .transactionFeeOutOfRange:
            return "Transaction fee is out of specified range"
        case let .networkError(error):
            return error.localizedDescription
        }
    }
}

class ValidatorCommissionSettingsViewModel: ObservableObject {
    @Published var transactionFeeCommission: Double = 0
    @Published var finalizationRewardCommission: Double = 0
    @Published var bakingRewardCommission: Double = 0
    @Published var commissionRanges: (
        bakingCommissionRange: CommissionRange,
        transactionCommissionRange: CommissionRange,
        finalizationCommissionRange: CommissionRange
    )?
    @Published var error: BakerCommissionSettingError?
    private var cancellables = Set<AnyCancellable>()
    private var service: StakeServiceProtocol
    var handler: BakerDataHandler
    
    init(
        service: StakeServiceProtocol,
        handler: BakerDataHandler
    ) {
        self.service = service
        self.handler = handler
        fetchData()
    }

    func fetchData() {
        service.getChainParameters().asResult().sink { result in
            switch result {
            case let .success(response):

                self.commissionRanges = (
                    bakingCommissionRange: response.bakingCommissionRange,
                    transactionCommissionRange: response.transactionCommissionRange,
                    finalizationCommissionRange: response.finalizationCommissionRange
                )

                // This will only trigger when new baker is registered.
                // In that case there are no current values, all data is considered 'new'.
                // That field is first set in `BakerAmountInputPresenter.loadPoolParameters()`.
                if let data = self.handler.getNewEntry(BakerCommissionData.self) {
                    self.updateCommissionValues(
                        baking: data.bakingRewardComission,
                        transaction: data.transactionComission,
                        finalization: data.finalizationRewardComission
                    )
                    return
                }
                // This covers a scenario when updating pool settings.
                // In order to update UI we set slider values to current values.
                // When slider is moved, the updated is returned by `handler.getNewEntry`.
                if let data = self.handler.getCurrentEntry(BakerCommissionData.self) {
                    self.updateCommissionValues(
                        baking: data.bakingRewardComission,
                        transaction: data.transactionComission,
                        finalization: data.finalizationRewardComission
                    )
                    return
                }
                self.updateCommissionValues(
                    baking: response.bakingCommissionRange.max,
                    transaction: response.transactionCommissionRange.max,
                    finalization: response.finalizationCommissionRange.max
                )

            case let .failure(error):
                self.error = .networkError(error)
            }
        }
        .store(in: &cancellables)
    }

    func continueButtonTapped(completion: @escaping () -> Void) {
        if let error = validate() {
            self.error = error
        } else {
            handler.add(
                entry: BakerCommissionData(
                    bakingRewardComission: bakingRewardCommission,
                    finalizationRewardComission: finalizationRewardCommission,
                    transactionComission: transactionFeeCommission
                )
            )
            completion()
        }
    }

    func validate() -> BakerCommissionSettingError? {
        guard let ranges = commissionRanges else {
            return BakerCommissionSettingError.bakingRewardOutOfRange
        }

        guard ranges.bakingCommissionRange.min ... ranges.bakingCommissionRange.max ~= bakingRewardCommission else {
            return BakerCommissionSettingError.bakingRewardOutOfRange
        }

        guard ranges.transactionCommissionRange.min ... ranges.transactionCommissionRange.max ~= transactionFeeCommission else {
            return BakerCommissionSettingError.transactionFeeOutOfRange
        }
        return nil
    }

    private func updateCommissionValues(baking: Double, transaction: Double, finalization: Double) {
        transactionFeeCommission = transaction
        bakingRewardCommission = baking
        finalizationRewardCommission = finalization
    }
}

extension ValidatorCommissionSettingsViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorCommissionSettingsViewModel, rhs: ValidatorCommissionSettingsViewModel) -> Bool {
        lhs.transactionFeeCommission == rhs.transactionFeeCommission &&
        lhs.finalizationRewardCommission == rhs.finalizationRewardCommission &&
        lhs.bakingRewardCommission == rhs.bakingRewardCommission &&
        lhs.commissionRanges?.0.max == rhs.commissionRanges?.0.max &&
        lhs.commissionRanges?.1.max == rhs.commissionRanges?.1.max &&
        lhs.commissionRanges?.2.max == rhs.commissionRanges?.2.max &&
        lhs.commissionRanges?.0.min == rhs.commissionRanges?.0.min &&
        lhs.commissionRanges?.1.min == rhs.commissionRanges?.1.min &&
        lhs.commissionRanges?.2.min == rhs.commissionRanges?.2.min
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(transactionFeeCommission)
        hasher.combine(finalizationRewardCommission)
        hasher.combine(bakingRewardCommission)
        hasher.combine(commissionRanges?.0.max)
        hasher.combine(commissionRanges?.0.min)
        hasher.combine(commissionRanges?.1.max)
        hasher.combine(commissionRanges?.1.min)
        hasher.combine(commissionRanges?.2.max)
        hasher.combine(commissionRanges?.2.min)
    }
}
