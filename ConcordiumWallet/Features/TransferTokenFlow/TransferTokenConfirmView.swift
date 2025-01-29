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

final class TransferTokenConfirmViewModel: ObservableObject, Equatable, Hashable {
    @Published var amountDisplay: String
    @Published var ticker: String
    @Published var recipient: String
    @Published var sender: String
    @Published var transferDataType: TransferEntity?
    
    @Published var error: Error?
    @Published var isLoading: Bool = true
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
        .modifier(AppBackgroundModifier())
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
