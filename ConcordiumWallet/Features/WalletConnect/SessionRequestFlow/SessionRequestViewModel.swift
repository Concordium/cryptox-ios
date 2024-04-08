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
    @Published var requestTransactionParameters: ContractUpdateParams?
    
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
        
        self.requestTransactionParameters = try? sessionRequest.params.get(ContractUpdateParams.self)

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
    private func updateSignButtonState(account: AccountEntity, params: ContractUpdateParams) async throws {
        if try await checkBalance(account: account, params: params) {
            self.isSignButtonEnabled = true
        } else {
            self.errorText = String("Not enough CCDs on your account")
        }
    }
    
    @MainActor
    func checkBalance(account: AccountEntity, params: ContractUpdateParams) async throws -> Bool {
        let transfer = self.getTransfer(for: params)
        let txCost = try await transactionsService.getTransferCost(
            transferType: transfer.transferType.toWalletProxyTransferType(),
            costParameters: [
                .amount(params.payload.amount),
                .sender(params.sender),
                .contractIndex(params.payload.address.index ?? 0),
                .contractSubindex(params.payload.address.subindex ?? 0),
                .receiveName(params.payload.receiveName),
                .parameter(params.payload.message),
            ]
        ).async()
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
        guard let account = account else { return }

        self.shouldRejectOnDismiss = false
        self.errorText = nil
                
        do {
            switch sessionRequest.method {
                case "sign_message":
                    try await signMessageRequest(account: account, request: sessionRequest)
                case "sign_and_send_transaction":
                    try await signTransactionRequest(sessionRequest, account: account)
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
    private func getTransfer(for params: ContractUpdateParams) -> any TransferDataType {
        var transfer = TransferDataTypeFactory.create()
        transfer.transferType = params.type
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
        return transfer
    }
    
    private func signTransactionRequest(_ sessionRequest: Request, account: AccountEntity) async throws {
        let params = try sessionRequest.params.get(ContractUpdateParams.self)
        let transfer = getTransfer(for: params)
        let result = try await createAndPerform(params: params, account: account, transfer: transfer).singleOutput()
        try await Web3Wallet.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(["hash": result]))
        )
    }
    
    @MainActor
    private func createAndPerform(params: ContractUpdateParams, account: AccountEntity, transfer: any TransferDataType) async throws -> AnyPublisher<String?, Error> {
        transactionsService
            .performTransferUpdate(transfer, from: account, contractAddress: params.payload.address, requestPasswordDelegate: passwordDelegate)
            .tryMap { transferDataType -> String? in
                _ = try self.storageManager.storeTransfer(transferDataType)
                return transferDataType.submissionId
            }
            .eraseToAnyPublisher()
    }
}

// Message Sign
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
