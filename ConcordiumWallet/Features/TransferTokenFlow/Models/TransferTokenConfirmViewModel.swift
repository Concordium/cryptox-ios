//
//  TransferTokenConfirmViewModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 12.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt
import Combine

struct TokenTransferParameters: Codable {
    let tokenId: String
    let amount: String
    let from: String
    let to: String
}

final class TransferTokenConfirmViewModel: ObservableObject, Equatable, Hashable {
    @Published var amountDisplay: String
    @Published var ticker: String
    @Published var recipient: String
    @Published var sender: String
    @Published var transferDataType: TransferEntity?
    
    @Published var error: Error?
    @Published var isLoading: Bool = true
    private var dependencyProvider = ServicesProvider.defaultProvider()
    var transactionStatusLabel: String {
        withAnimation(.easeInOut(duration: 1)) {
            if isLoading {
                return "transaction.in.progress.status".localized
            } else if !isLoading {
                return "transaction.status.success".localized
            }
            if error != nil {
                return "transaction.status.failed".localized
            }
            return ""
        }
    }
    
    let tokenTransferModel: CIS2TokenTransferModel
    private let transactionsService: TransactionsServiceProtocol
    private let storageManager: StorageManagerProtocol
    private var cancellables = [AnyCancellable]()

    init(
        tokenTransferModel: CIS2TokenTransferModel,
        transactionsService: TransactionsServiceProtocol,
        storageManager: StorageManagerProtocol
    ) {
        self.tokenTransferModel = tokenTransferModel
        self.recipient = tokenTransferModel.recipient ?? ""
        self.amountDisplay =  TokenFormatter().string(from: tokenTransferModel.amountTokenSend, decimalSeparator: ".", thousandSeparator: ",")
        self.storageManager = storageManager
        self.transactionsService = transactionsService
        self.sender = tokenTransferModel.account.address
        self.ticker = tokenTransferModel.tokenType.ticker
    }
    
    @MainActor
    func callTransaction() async {
        self.isLoading = true
        self.error = nil
        
        do {
            try await tokenTransferModel.executeTransaction()
                .sink(receiveError: { error in
                    self.error = error
                }, receiveValue: { transferDataType in
                    self.transferDataType = transferDataType
                    self.isLoading = false
                }).store(in: &cancellables)
        } catch {
            self.error = error
            self.isLoading = false
        }
    }
    
    func getTransactionViewModel() -> TransactionViewModel? {
        guard let transferDataType else { return nil }
        let viewModel = TransactionViewModel(localTransferData: transferDataType, submissionStatus: nil, account: tokenTransferModel.account, balanceType: .balance) { _ in
            return nil
        } recipientListLookup: { _ in
            return nil
        }
        return viewModel
    }
    
    func dismiss() {
        if tokenTransferModel.notifyDestination == .legacyQrConnect {
            tokenTransferModel.sendTxRejectQRConnectMessage()
        }
    }
    
    static func ==(lhs: TransferTokenConfirmViewModel, rhs: TransferTokenConfirmViewModel) -> Bool {
        return lhs.amountDisplay == rhs.amountDisplay &&
               lhs.ticker == rhs.ticker &&
               lhs.recipient == rhs.recipient &&
               lhs.sender == rhs.sender &&
               lhs.transferDataType == rhs.transferDataType &&
               lhs.error?.localizedDescription == rhs.error?.localizedDescription &&
               lhs.isLoading == rhs.isLoading
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(amountDisplay)
        hasher.combine(ticker)
        hasher.combine(recipient)
        hasher.combine(sender)
        hasher.combine(transferDataType)
        hasher.combine(error?.localizedDescription)
        hasher.combine(isLoading)
    }
}
