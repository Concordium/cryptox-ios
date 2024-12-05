//
//  TransferTokenConfirmView.swift
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

final class TransferTokenConfirmViewModel: ObservableObject {
    @Published var amountDisplay: String
    @Published var ticker: String
    @Published var recipient: String
    @Published var sender: String
    @Published var transferDataType: TransferEntity?
    
    @Published var error: Error?
    
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
        self.amountDisplay =  TokenFormatter().string(from: tokenTransferModel.amountTokenSend)
        self.storageManager = storageManager
        self.transactionsService = transactionsService
        self.sender = tokenTransferModel.account.address
        self.ticker = tokenTransferModel.tokenType.ticker
    }
    
    @MainActor
    func callTransaction() async {
        self.error = nil
        try? await tokenTransferModel.executeTransaction()
            .sink(receiveError: { error in
            self.error = error
        }, receiveValue: { transferDataType in
            self.transferDataType = transferDataType
        }).store(in: &cancellables)
    }
    
    func dismiss() {
        if tokenTransferModel.notifyDestination == .legacyQrConnect {
            tokenTransferModel.sendTxRejectQRConnectMessage()
        }
    }
}

struct TransferTokenConfirmView: View {
    @StateObject var viewModel: TransferTokenConfirmViewModel
    @EnvironmentObject var router: TransferTokenRouter
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    let isPresented: Bool

    var body: some View {
        VStack {
            List {
                Text("sendFund.confirmation.transfer".localized)
                    .foregroundColor(.white)
                    .font(.satoshi(size: 19, weight: .medium))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                transferDetails()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(20)
                .cornerRadius(24, corners: .allCorners)
            }
            .listStyle(.plain)
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.callTransaction()
                }
            } label: {
                Text("sendFund.confirmation.buttonTitle".localized)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .font(.satoshi(size: 17, weight: .semibold))
                    .padding(.vertical, 11)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding()
        }
        .background {
            LinearGradient(
                colors: [Color(hex: 0x242427), Color(hex: 0x09090B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        }
        .onChange(of: viewModel.transferDataType) { transferDataType in
            guard let transferDataType = transferDataType else { return }
            self.router.transactionSuccessFlow(transferDataType, tokenTransferModel: viewModel.tokenTransferModel)
        }
        .toolbar {
            isPresented
            ? ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.viewModel.dismiss()
                    self.router.dismissFlow()
                }
                    label: { Image("ico_close") }
            }
            : nil
        }
    }
    
    @ViewBuilder
    func transferDetails() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(viewModel.amountDisplay)
                    .foregroundColor(.white)
                    .font(.satoshi(size: 19, weight: .medium))
                    .listRowBackground(Color.clear)
                Text(viewModel.ticker)
                    .foregroundColor(.white)
                    .font(.satoshi(size: 19, weight: .medium))
                    .listRowBackground(Color.clear)
            }
            Text("sendFund.confirmation.line2.to".localized)
                .foregroundColor(Color.greyMain)
                .font(.satoshi(size: 15, weight: .medium))
                
            Text(viewModel.recipient.prefix(4) + "..." + viewModel.recipient.suffix(4))
                .foregroundColor(.white)
                .font(.satoshi(size: 19, weight: .medium))
                
            
            Rectangle()
                .fill(Color.blackAditional)
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            
            Text("sendFund.feeMessageTitle".localized)
                .foregroundColor(Color.blackAditional)
                .font(.satoshi(size: 15, weight: .medium))

            Text(GTU(intValue: Int(BigInt(stringLiteral: viewModel.tokenTransferModel.transaferCost?.cost ?? "0"))).displayValueWithCCDStroke())
                .foregroundColor(.white)
                .font(.satoshi(size: 15, weight: .medium))
            
            Spacer()
            
            Text("sendFund.memo.textTitle".localized)
                .foregroundColor(Color.blackAditional)
                .font(.satoshi(size: 15, weight: .medium))

            Text(viewModel.tokenTransferModel.memo?.displayValue ?? "")
                .foregroundColor(.white)
                .font(.satoshi(size: 15, weight: .medium))
            
            HStack {
                Text("sendFund.confirmation.line3.fromAccount".localized)
                    .foregroundColor(Color.blackAditional)
                    .font(.satoshi(size: 15, weight: .medium))
                Spacer()
                Text(viewModel.sender.prefix(4) + "..." + viewModel.sender.suffix(4))
                    .foregroundColor(Color.white)
                    .font(.satoshi(size: 15, weight: .medium))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .overlay(
                Capsule(style: .circular)
                    .stroke(Color.blackAditional, lineWidth: 1)
            )
            .padding(.top, 24)
        }
    }
    
    @ViewBuilder
    func cell() -> some View {
        
    }
}
