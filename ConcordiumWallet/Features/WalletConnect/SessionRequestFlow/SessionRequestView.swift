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

final class SessionRequestViewModel: ObservableObject {
    let sessionRequest: Request
    @Published var verified: Bool? = true
    @Published var account: AccountEntity?
    let params: WalletConnectParams?
    
    @Published var canSendTx: Bool = false
    @Published var errorText: String?
    @Published var shouldRejectOnDismiss =  true
    
    var message: String {
        return String(describing: sessionRequest.params.value)
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
        let _params = try? sessionRequest.params.get(WalletConnectParams.self)
        
        self.passwordDelegate = passwordDelegate
        self.transactionsService = transactionsService
        self.sessionRequest = sessionRequest
        self.storageManager = storageManager
        self.params = _params
        
        self.account = storageManager.getAccounts().first(where: { $0.address == _params?.sender }) as? AccountEntity
        
        guard let account = account else { return }
        guard let params = params else { return }
        
        Task {
            let txCost = try? await transactionsService.getTransferCost(transferType: .simpleTransfer, costParameters: []).async()
            DispatchQueue.main.async {
                let totalBalance = account.forecastBalance
                let amount = Int(params.payload.amount) ?? 0
                let nrgCCDAmount = self.getNrgCCDAmount(
                    nrgLimit: params.payload.maxContractExecutionEnergy,
                    cost: txCost?.cost.floatValue ?? 0,
                    energy: txCost?.energy.string.floatValue ?? 0
                )
                
                let ccdAmount =  GTU(intValue: amount)
                let ccdNetworkComission = GTU(displayValue: nrgCCDAmount.toString())
                let ccdTotalAmount = GTU(intValue: ccdAmount.intValue + ccdNetworkComission.intValue)
                let ccdTotalBalance = GTU(intValue: totalBalance)
                
                self.canSendTx = ccdTotalBalance.intValue > ccdTotalAmount.intValue
                
                if !self.canSendTx {
                    self.errorText = String(format: "qrtransactiondata.error.subtitle".localized, ccdTotalAmount.displayValue())
                } else {
                    self.errorText = nil
                }
            }
        }
    }
    
    @MainActor
    func onApprove(_ completion: () -> Void) async {
        self.shouldRejectOnDismiss = false
        self.errorText = nil
        
        do {
            let result = try await sign(request: sessionRequest).singleOutput()
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
    func onReject(_ completion: () -> Void) async {
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
    private func sign(request: Request) async throws -> AnyPublisher<String?, Error> {
        guard let params = try? request.params.get(WalletConnectParams.self) else {
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
                                viewModel.onReject { dismiss() }
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
                                viewModel.onApprove { dismiss() }
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
                        .disabled(viewModel.account == nil || !viewModel.canSendTx)
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
                    await viewModel.onReject {}
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

struct WalletConnectParams: Codable {
    struct Schema: Codable {
        let type: String
        let value: String
    }
    
    let sender: String
    let payload: UpdateTxPayload
//    var schema: Schema?
    
    enum CodingKeys: String, CodingKey {
        case sender, payload//, schema
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let payloadString = try container.decode(String.self, forKey: .payload)

        sender = try container.decode(String.self, forKey: .sender)
        payload = try JSONDecoder().decode(UpdateTxPayload.self, from: payloadString.data(using: .utf8) ?? Data())
//        schema = try container.decodeIfPresent(Schema.self, forKey: .schema)
    }
}

extension Publishers {
    struct MissingOutputError: Error {}
}

extension Publisher {
    func singleOutput() async throws -> Output {
        for try await output in values {
            // Since we're immediately returning upon receiving
            // the first output value, that'll cancel our
            // subscription to the current publisher:
            return output
        }

        throw Publishers.MissingOutputError()
    }
}

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
        }
    }
}


struct WRequestParams: Codable {
    struct Payload: Codable {
        struct Address: Codable {
            let index: Int
            let subindex: Int
        }
        
        let amount: String
        let address: Address
        let receiveName: String
        let maxContractExecutionEnergy: String
        let message: String
    }
    
    struct Schema: Codable {
        let type: String
        let value: String
    }
    
    let payload: Payload
    let sender: String
    let type: String
}
