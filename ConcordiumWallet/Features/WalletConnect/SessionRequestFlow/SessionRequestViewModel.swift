//
//  SessionRequestViewModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Web3Wallet
import WalletConnectVerify
import Combine

enum SessionRequstError: Error {
    case environmentMismatch(chain: String), accountNotFound, accountMissmatch, noValidWCSession(topic: String)
    
    var errorMessage: String {
        switch self {
            case .environmentMismatch(let chain):
                "The session proposal did not contain a valid namespace. Allowed namespaces are: \(chain)"
            case .accountNotFound:
                "Can't find apropriate acount to sign"
            case .accountMissmatch:
                ""
            case .noValidWCSession(let topic):
                "No session found for the received topic: \(topic)"
        }
    }
}

final class SessionRequestViewModel: ObservableObject {
    let sessionRequest: Request
    
    @Published var account: AccountEntity?
    @Published var isSignButtonEnabled: Bool = false
    @Published var errorText: String?
    @Published var shouldRejectOnDismiss =  true
    @Published var error: SessionRequstError?
    @Published var requestTransactionParameters: WCRequestTransaction?
    
    var message: String {
        return String(describing: sessionRequest.params.value)
    }
    
    var currentChain: String {
#if MAINNET
        "ccd:mainnet"
#else
        "ccd:testnet"
#endif
    }
    
    private let transactionsService: TransactionsServiceProtocol
    private let storageManager: StorageManagerProtocol
    private var cancellables = [AnyCancellable]()
    private let passwordDelegate: RequestPasswordDelegate
    private let mobileWallet: MobileWalletProtocol
    
    init(
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        storageManager: StorageManagerProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate()
    ) {
        self.passwordDelegate = passwordDelegate
        self.transactionsService = transactionsService
        self.sessionRequest = sessionRequest
        self.storageManager = storageManager
        self.mobileWallet = mobileWallet
        
        self.requestTransactionParameters = try? sessionRequest.params.get(WCRequestTransaction.self)

        // Find the session that the request matches. The session will allow us to extract
        // the account that the request is for.
        // A WalletConnect session should always be for exactly one account. If there are more, then
        // we cannot uniquely determine the correct account address.
        guard
            let session = Web3Wallet.instance.getSessions().first(where: { $0.topic == sessionRequest.topic }),
            session.accounts.count == 1,
            let walletConnectAccount = session.accounts.first
        else {
            error = .noValidWCSession(topic: sessionRequest.topic)
            return
        }
        
        // Ensure that app chain and requested chain is same
        guard sessionRequest.chainId.absoluteString == currentChain else {
            error = .environmentMismatch(chain: sessionRequest.chainId.absoluteString)
            return
        }
        
//        guard let params = requestTransactionParameters else { return }

        // Get `Account` with specified in WC request address
        guard let account = storageManager.getAccounts().first(where: { $0.address == walletConnectAccount.address }) as? AccountEntity else {
            error = .accountNotFound
            return
        }
        
        self.account = account
        
        Task {
            switch sessionRequest.method {
                case "sign_message":
                    self.isSignButtonEnabled = true
                case "sign_and_send_transaction":
                    guard let params = requestTransactionParameters else { return }
                    try await updateSignButtonState(account: account, params: params)
                default: break
            }
        }
    }
    
    @MainActor
    private func updateSignButtonState(account: AccountEntity, params: WCRequestTransaction) async throws {
        let isBalanceValid = try await checkBalance(account: account, params: params)
        
        self.isSignButtonEnabled = isBalanceValid
        
        if !isBalanceValid {
            self.errorText = String("Not enough CCDs on your account")
        }
    }
    
    @MainActor
    func checkBalance(account: AccountEntity, params: WCRequestTransaction) async throws -> Bool {
        let txCost = try await transactionsService.getTransferCost(transferType: .simpleTransfer, costParameters: []).async()
        let nrgCCDAmount = self.getNrgCCDAmount(
            nrgLimit: params.payload.maxContractExecutionEnergy,
            cost: txCost.cost.floatValue,
            energy: txCost.energy.string.floatValue
        )
        
        let amount = Int(params.payload.amount) ?? 0
        let ccdAmount =  GTU(intValue: amount)
        let ccdNetworkComission = GTU(displayValue: nrgCCDAmount.toString())
        let ccdTotalAmount = GTU(intValue: ccdAmount.intValue + ccdNetworkComission.intValue)
        let ccdTotalBalance = GTU(intValue: account.forecastBalance)
        
        return ccdTotalBalance.intValue > ccdTotalAmount.intValue
    }
    
    
    @MainActor
    func approveRequest(_ completion: () -> Void) async {
        self.shouldRejectOnDismiss = false
        self.errorText = nil
        guard let account = account else { return }
                
        do {
            switch sessionRequest.method {
                case "sign_message":
                    try await signMessageRequest(account: account, request: sessionRequest)
                case "sign_and_send_transaction":
                    try await signTransactionRequest(sessionRequest)
                default: break
            }

            completion()
        } catch {
            self.errorText = "Can't find apropriate acount to sign"
        }
    }
    
    @MainActor
    func rejectRequest(_ completion: () -> Void) async {
        do {
            try await Web3Wallet.instance.respond(
                topic: sessionRequest.topic,
                requestId: sessionRequest.id,
                response: .error(.init(code: 0, message: ""))
            )
            completion()
        } catch {
            self.errorText = "Cant reject this tx. Try again later"
        }
    }
    
    private func getNrgCCDAmount(nrgLimit: Int, cost: Float, energy: Float) -> Int {
        let _nrgLimit = Float(nrgLimit)
        let nrgCCDAmount = Float(_nrgLimit * (cost / energy) / 1000000.0)
        return Int(ceil(nrgCCDAmount))
    }
}

// Sign and Send simple transaction logic
extension SessionRequestViewModel {
    private func signTransactionRequest(_ sessionRequest: Request) async throws {
        let result = try await createAndPerform(request: sessionRequest).singleOutput()
        try await Web3Wallet.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(["hash": result]))
        )
    }
    
    @MainActor
    private func createAndPerform(request: Request) async throws -> AnyPublisher<String?, Error> {
        guard let params = try? request.params.get(WCRequestTransaction.self) else {
            return .fail(MobileWalletError.invalidArgument)
        }
        
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = .transferUpdate
        transfer.amount = params.payload.amount
        transfer.fromAddress = params.sender
        transfer.from = params.sender
        transfer.toAddress = params.sender
        transfer.expiry = Date().addingTimeInterval(10 * 60)
        transfer.energy = params.payload.maxContractExecutionEnergy
        transfer.receiveName = params.payload.receiveName
        transfer.params = params.payload.message
        transfer.contractAddressObject = ContractAddressObject()
        transfer.contractAddressObject.index = params.payload.address.index?.toString() ?? ""
        transfer.contractAddressObject.subindex = params.payload.address.subindex?.toString() ?? ""
        
        guard let fromAccount = account else {
            return .fail(MobileWalletError.invalidArgument)
        }
        
        return transactionsService
            .performTransferUpdate(transfer, from: fromAccount, contractAddress: params.payload.address, requestPasswordDelegate: passwordDelegate)
            .tryMap { transferDataType -> String? in
                _ = try self.storageManager.storeTransfer(transferDataType)
                return transferDataType.submissionId
            }
            .eraseToAnyPublisher()
    }
}

extension SessionRequestViewModel {
    private func signMessageRequest(account: AccountDataType, request: Request) async throws {
        let jsonData = try JSONSerialization.data(withJSONObject: request.params.value, options: [])
        let payload: SignMessagePayload = try JSONDecoder().decode(SignMessagePayload.self, from: jsonData)
        let result =  try await mobileWallet
            .signMessage(for: account, message: payload.message, requestPasswordDelegate: passwordDelegate).async()
        try await Sign.instance.respond(
            topic: request.topic,
            requestId: request.id,
            response: .response(AnyCodable(result))
        )
    }
}
