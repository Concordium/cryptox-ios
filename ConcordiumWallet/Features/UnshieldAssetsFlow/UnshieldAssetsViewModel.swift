//
//  UnshieldAssetsViewModel.swift
//  CryptoX
//
//  Created by Max on 24.05.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import BigInt
import Combine
import Concordium

final class UnshieldAssetsViewModel: ObservableObject {
    @Published var account: AccountEntity?
    @Published var displayName: String
    @Published var unshieldAmount: BigDecimal = .zero
    @Published var transaferCost: TransferCost = .zero
    
    @Published var fee: String = ""
    
    @Published var isUnshielding: Bool = false
    @Published var isLoadingTxCost: Bool = false
    @Published var isUnshieldButtonDisabled: Bool = true
    
    @Published var error: String?
    
    private let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    private let passwordDelegate: RequestPasswordDelegate
    private var cancellables = [AnyCancellable]()
    private var onSuccess: (AccountEntity) -> Void
    
    private let concordiumClient: ConcordiumClient

    init(
        account: AccountEntity?,
        dependencyProvider: AccountsFlowCoordinatorDependencyProvider,
        onSuccess: @escaping (AccountEntity) -> Void,
        passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate()
    ) {
        self.concordiumClient = try! ConcordiumClient(networkManager: dependencyProvider.networkManager(), storageManager: dependencyProvider.storageManager())
        self.onSuccess = onSuccess
        self.dependencyProvider = dependencyProvider
        self.passwordDelegate = passwordDelegate
        self.account = account
        self.displayName = account?.displayName ?? ""
        self.unshieldAmount = BigDecimal(BigInt(integerLiteral: Int64(account?.finalizedEncryptedBalance ?? 0)), 6)

        Task {
            try? await updateTransferCost()
        }
    }
    
    @MainActor
    private func updateTransferCost() async throws {
        self.isLoadingTxCost = true
        self.transaferCost = try await dependencyProvider
            .transactionsService()
            .getTransferCost(transferType: .transferToPublic, costParameters: [])
            .async()
        self.fee = GTU(intValue: Int(BigInt(stringLiteral: transaferCost.cost))).displayValueWithCCDStroke()
        self.isLoadingTxCost = false
        let isInsufficientFunds = BigDecimal.init(BigInt(account?.forecastAtDisposalBalance ?? 0) - BigInt(stringLiteral: transaferCost.cost), 6).value <= 0
        self.isUnshieldButtonDisabled = self.unshieldAmount == .zero || isInsufficientFunds
        
        error = isInsufficientFunds ? "sendFund.insufficientFunds".localized : nil
    }
    
    @MainActor
    func unshieldAssets(dismiss: @escaping () -> Void) {
        guard let account = account else { return }
        
        
        isUnshielding = true
        error = nil
        Task {
            do {
                let pwHash = try await self.passwordDelegate.requestUserPassword(keychain: dependencyProvider.keychainWrapper())
                guard
                    let encryptedAccountDataKey = account.encryptedAccountData,
                    let accountKeys = try? dependencyProvider.storageManager().getPrivateAccountKeys(key: encryptedAccountDataKey, pwHash: pwHash).get()
                else { throw WalletError.invalidInput }

                let transferToPublic = try await concordiumClient.transferToPublic(
                    account: account,
                    amount: CCD.init(microCCD: MicroCCDAmount(Double(unshieldAmount.value))),
                    receiver: try AccountAddress.init(base58Check: account.address),
                    keys: accountKeys,
                    pwHash: pwHash
                )
                
                print(transferToPublic)
                let txStatus = try await concordiumClient.getTransactionStatus(transferToPublic.hash)
                print(txStatus)
                await MainActor.run {
                    LegacyLogger.debug(self)
                    self.isUnshielding = false
                    self.onSuccess(account)
                    dismiss()
                }
            } catch {
                self.isUnshielding = false
            }
        }
    }
}
