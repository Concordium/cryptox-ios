//
//  TransferTokenSubmittedView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 14.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

final class TransferTokenSubmittedViewModel: ObservableObject {
    @Published var amountText: String
    @Published var fee: String
    @Published var to: String
    
    init(transferDataType: TransferEntity, tokenTransferModel: CIS2TokenTransferModel) {
        self.amountText = TokenFormatter().string(from: tokenTransferModel.amountTokenSend) + " " + tokenTransferModel.tokenType.ticker
        self.fee = GTU(intValue: Int(BigInt(stringLiteral: tokenTransferModel.transaferCost?.cost ?? "0"))).displayValueWithCCDStroke()
        self.to = transferDataType.toAddress.prefix(4) + "..." + transferDataType.toAddress.suffix(4)
    }
}

struct TransferTokenSubmittedView: View {
    @EnvironmentObject var viewModel: TransferTokenSubmittedViewModel
    @EnvironmentObject var router: TransferTokenRouter
    @SwiftUI.Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image("ico_tx_submitted")
                    Text("transactionConfirmed.submitted".localized)
                        .foregroundColor(.white)
                        .font(.satoshi(size: 19, weight: .medium))
                    Spacer()
                }
                
                Text("amount".localized)
                    .foregroundColor(Color.blackAditional)
                    .font(.satoshi(size: 15, weight: .medium))
                    .padding(.top, 32)
                Text(viewModel.amountText)
                    .foregroundColor(Color.white)
                .font(.satoshi(size: 16, weight: .semibold))
                
                Rectangle()
                    .fill(Color.blackAditional)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                
                Text("sendFund.feeMessageTitle".localized)
                    .foregroundColor(Color.blackAditional)
                    .font(.satoshi(size: 15, weight: .medium))
                Text(viewModel.fee)
                    .foregroundColor(Color.white)
                    .font(.satoshi(size: 16, weight: .semibold))
                
                Rectangle()
                    .fill(Color.blackAditional)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                
                Text("to".localized)
                    .foregroundColor(Color.blackAditional)
                    .font(.satoshi(size: 15, weight: .medium))
                Text(viewModel.to)
                    .foregroundColor(Color.white)
                    .font(.satoshi(size: 16, weight: .semibold))
            }
            .padding(20)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.4), lineWidth: 1)
            )
            
            Spacer()
            Button {
                self.dismiss()
                self.router.dismissFlow()
                
            } label: {
                Text("identitySubmitted.finish".localized)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .font(.satoshi(size: 17, weight: .semibold))
                    .padding(.vertical, 11)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .padding()
        }
        .padding(.top, 32)
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .background {
            LinearGradient(
                colors: [Color(hex: 0x242427), Color(hex: 0x09090B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        }
    }
}

struct TransferTokenSubmittedView_Previews: PreviewProvider {
    static var previews: some View {
        TransferTokenSubmittedView()
    }
}
