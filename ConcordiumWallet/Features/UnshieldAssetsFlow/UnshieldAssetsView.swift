//
//  UnshieldAssetsView.swift
//  CryptoX
//
//  Created by Max on 21.05.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

final class UnshieldAssetsViewModel: ObservableObject {
    @Published var account: AccountEntity?
    @Published var displayName: String
    @Published var unshieldAmount: BigDecimal = .zero
    @Published var transaferCost: TransferCost = .zero
    
    @Published var fee: String = ""
    
    private let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    
    init(account: AccountEntity?, dependencyProvider: AccountsFlowCoordinatorDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.account = account
        self.displayName = account?.displayName ?? ""
        
        if let account = account,
           let selfAmount = account.encryptedBalance?.selfAmount,
           let decryptedSelfAmount = dependencyProvider.storageManager().getShieldedAmount(
            encryptedValue: selfAmount,
            account: account)?.decryptedValue
        {
            self.unshieldAmount = BigDecimal(BigInt(stringLiteral: decryptedSelfAmount), 6)
        }
        
        Task {
            try? await updateTransferCost()
        }
    }
    
    @MainActor
    private func updateTransferCost() async throws {
        self.transaferCost = try await dependencyProvider
            .transactionsService()
            .getTransferCost(transferType: .transferToPublic, costParameters: [])
            .async()
        self.fee = GTU(intValue: Int(BigInt(stringLiteral: transaferCost.cost))).displayValueWithCCDStroke()
    }
}

struct UnshieldAssetsView: View {
    @StateObject var viewModel: UnshieldAssetsViewModel
    
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.14, green: 0.14, blue: 0.15), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.03, green: 0.03, blue: 0.04), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .ignoresSafeArea(.all)
            VStack(alignment: .center, spacing: 32) {
                VStack(spacing: 24) {
                    Text("Shielded amount:")
                        .font(.satoshi(size: 11, weight: .medium))
                        .foregroundStyle(Color.blackAditional)
                    Text(TokenFormatter().plainString(from: viewModel.unshieldAmount))
                        .font(.satoshi(size: 40, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                .padding(.top, 64)
                
                VStack(spacing: 8) {
                    Text("Estimated transaction fee:")
                        .font(.satoshi(size: 11, weight: .medium))
                        .foregroundStyle(Color.blackAditional)
                    Text(viewModel.fee)
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .offset(y: 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("backButtonIcon")
                        .foregroundColor(Color.Neutral.tint1)
                        .frame(width: 35, height: 35)
                        .contentShape(.circle)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(viewModel.displayName)
                        .font(.satoshi(size: 17, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
        }

    }
}
