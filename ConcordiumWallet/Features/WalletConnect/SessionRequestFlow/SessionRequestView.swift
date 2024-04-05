//
//  SessionRequestView.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 19.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI
import Web3Wallet
import WalletConnectVerify
import Combine

enum SessionRequstError: Error {
    case environmentMismatch, accountNotFound
}

final class SessionRequestViewModel: ObservableObject {
    let sessionRequest: Request
    
    @Published var verified: Bool? = true
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
    
    init(
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        storageManager: StorageManagerProtocol,
        passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate()
    ) {
        self.passwordDelegate = passwordDelegate
        self.transactionsService = transactionsService
        self.sessionRequest = sessionRequest
        self.storageManager = storageManager
        
        self.requestTransactionParameters = try? sessionRequest.params.get(WCRequestTransaction.self)
        self.account = storageManager.getAccounts().first(where: { $0.address ==
            requestTransactionParameters?.sender }) as? AccountEntity
        
        guard sessionRequest.chainId.absoluteString == currentChain else {
            error = .environmentMismatch
            return
        }
        
        guard let account = account else {
            error = .accountNotFound
            return
        }
        
        guard let params = requestTransactionParameters else { return }
        
        Task {
            try await updateSignButtonState(account: account, params: params)
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
        
        let ccdAmount = GTU(displayValue: params.payload.amount)
        let ccdNetworkComission = GTU(displayValue: nrgCCDAmount.toString())
        let ccdTotalAmount = GTU(intValue: ccdAmount.intValue + ccdNetworkComission.intValue)
        let ccdTotalBalance = GTU(intValue: account.forecastBalance)
        
        return ccdTotalBalance.intValue > ccdTotalAmount.intValue
    }
    
    
    @MainActor
    func approveRequest(_ completion: () -> Void) async {
        self.shouldRejectOnDismiss = false
        self.errorText = nil
        
        do {
            let result = try await createAndPerform(request: sessionRequest).singleOutput()
            try await Web3Wallet.instance.respond(
                topic: sessionRequest.topic,
                requestId: sessionRequest.id,
                response: .response(AnyCodable(["hash": result]))
            )
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
    
    private func getNrgCCDAmount(nrgLimit: Int, cost: Float, energy: Float) -> Int {
        let _nrgLimit = Float(nrgLimit)
        let nrgCCDAmount = Float(_nrgLimit * (cost / energy) / 1000000.0)
        return Int(ceil(nrgCCDAmount))
    }
}


struct SessionRequestView: View {
    @StateObject var viewModel: SessionRequestViewModel
    
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack(spacing: 8) {
                Spacer()
                
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Sign transaction")
                                .foregroundColor(.white)
                                .font(.system(size: 28, weight: .semibold))
                            Text(viewModel.sessionRequest.method)
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: 13, weight: .regular))
                        }
                        .padding(.top, 10)
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        if let account = viewModel.account {
                            Divider()
                                .padding(.top, 12)
                                .padding(.bottom, 12)
                                .padding(.horizontal, -18)
                            
                            WCAccountCell(account: account)
                                .padding(.bottom, 16)
                        }
                        
                        if viewModel.message != "[:]" {
                            authRequestView()
                        }
                    }
                    .frame(minHeight: 100)
                    .overlay {
                        if let error = viewModel.error {
                            ZStack {
                                switch error {
                                    case .environmentMismatch:
                                        Text("The session proposal did not contain a valid namespace. Allowed namespaces are: \(viewModel.currentChain)")
                                            .multilineTextAlignment(.center)
                                    case .accountNotFound:
                                        Text("Can't find apropriate acount to sign")
                                            .multilineTextAlignment(.center)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.thinMaterial)
                            .cornerRadius(24)
                        }
                    }
                    
                    if let errorText = viewModel.errorText {
                        VStack {
                            Text("qrtransactiondata.error.title".localized)
                                .foregroundColor(Pallette.error)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Text(errorText)
                                .foregroundColor(Pallette.errorText)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .padding(.top, 12)
                    }
                    
                    HStack(spacing: 20) {
                        Button {
                            Task(priority: .userInitiated) { await
                                viewModel.rejectRequest { dismiss() }
                            }
                        } label: {
                            Text("Decline")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .semibold))
                                .padding(.vertical, 11)
                                .background(Color.clear)
                                .overlay(
                                    Capsule(style: .circular)
                                        .stroke(.white, lineWidth: 2)
                                )
                        }
                        
                        Button {
                            Task(priority: .userInitiated) { await
                                viewModel.approveRequest { dismiss() }
                            }
                        } label: {
                            Text("Sign")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black)
                                .font(.system(size: 17, weight: .semibold))
                                .padding(.vertical, 11)
                                .background(viewModel.account == nil ? .white.opacity(0.7) : .white)
                                .clipShape(Capsule())
                        }
                        .disabled(viewModel.account == nil || !viewModel.isSignButtonEnabled)
                    }
                    .padding(.top, 25)
                    .padding(.bottom, 24)
                }
                .padding(20)
                .background(Color.blackSecondary)
                .cornerRadius(34)
                .padding(.horizontal, 10)
            }
            .background(.clear)
        }
        .edgesIgnoringSafeArea(.all)
        .onDisappear {
            Task(priority: .userInitiated) {
                if viewModel.shouldRejectOnDismiss {
                    await viewModel.rejectRequest {}
                }
            }
        }
    }
    
    private func authRequestView() -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Message")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.greySecondary)
                
                VStack(spacing: 0) {
                    ScrollView {
                        Text(viewModel.message)
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(height: 250)
                }
                .background(Color.clear)
            }
            .background(.clear)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .overlay(
            RoundedCorner(radius: 24, corners: .allCorners)
                .stroke(.white.opacity(0.3), lineWidth: 2)
        )
    }
}
