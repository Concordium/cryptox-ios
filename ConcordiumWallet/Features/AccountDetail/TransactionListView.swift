//
//  TransactionListView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 30.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

final class TransactionListViewModel: ObservableObject {
    let title: String
    let total: String
    var totalColor: Color = .clear
    let timestamp: String
    var amount: String = ""
    var cost: String = ""
    var memo: Memo?
    var sender: String?
    
    var showCostAsEstimate = false
    var isFailed: Bool = false
    
    init(_ tx: TransactionViewModel) {
        self.title = tx.title
        self.total = tx.total?.displayValueWithCCDStroke() ?? "0.0 CCD"
        self.timestamp = GeneralFormatter.formatTime(for: tx.date)
        if let cost = tx.total?.intValue {
            self.totalColor =  cost < 0 ? .white : .success
        }
        
        switch tx.status {
        case .received?:
            showCostAsEstimate = true
        case .absent?:
            showCostAsEstimate = true
        case .committed?:
            break
        case .finalized?:
            break
        case .none:
            break
        }
        
        if let cost = tx.cost?.displayValueWithCCDStroke(),
           let amount = tx.amount?.displayValueWithCCDStroke() {
            self.amount = amount
            self.cost = "with fee " + cost
        }
        
        if tx.status == .committed && tx.outcome == .reject {
            isFailed = true
        } else if tx.status == .finalized && tx.outcome == .reject {
            isFailed = true
        }
        
        self.memo = tx.memo
        self.sender = tx.details.fromAddressName
    }
}

struct TransactionListView: View {
    @StateObject var viewModel: TransactionListViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.isFailed {
                HStack {
                    Image("ico_tx_failed")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("accountDetails.failed".localized)
                        .foregroundColor(Color.white)
                        .font(.satoshi(size: 15, weight: .medium))
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.init(hex: 0xFF7511, alpha: 0.12))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
            }
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .font(.satoshi(size: 15, weight: .medium))
                        .foregroundColor(Color.white)
                    Text(viewModel.timestamp)
                        .foregroundColor(Color.MineralBlue.blueish3.opacity(0.5))
                        .font(.satoshi(size: 14, weight: .medium))
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.total)
                        .foregroundStyle(viewModel.totalColor)
                        .font(.satoshi(size: 15, weight: .medium))
                    if !viewModel.cost.isEmpty {
                        Text(viewModel.cost)
                            .foregroundColor(Color.MineralBlue.blueish3.opacity(0.5))
                            .font(.satoshi(size: 12, weight: .medium))
                    }
                }
                
                Image("button_slider_forward")
                    .renderingMode(.template)
                    .foregroundStyle(.grey4)
                    .frame(width: 24, height: 24)
            }
            
            if let memo = viewModel.memo {
                Divider()
                    .foregroundStyle(.white.opacity(0.1))
                
                HStack(spacing: 6) {
                    Image("note")
                    
                    Text(memo.displayValue)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish2)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 15)
        .background(Color(red: 0.17, green: 0.19, blue: 0.2).opacity(0.3))

        .cornerRadius(12)
        .opacity(viewModel.isFailed ? 0.5 : 1.0)
        .listRowBackground(Color.clear)
    }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView(viewModel: .init(.init()))
    }
}
