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
    
    var showCostAsEstimate = false
    var isFailed: Bool = false
    
    init(_ tx: TransactionViewModel) {
        self.title = tx.title
        self.total = tx.total?.displayValueWithCCDStroke() ?? "0.0 CCD"
        self.timestamp = GeneralFormatter.formatTime(for: tx.date)
        if let cost = tx.total?.intValue {
            self.totalColor =  cost < 0 ? Color.blackAditional.opacity(0.12) : Color.init(hex: 0x09CFA0, alpha: 0.12)
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
            self.cost = " - " + cost + " Fee"
            
            // Prepend with ~ if cost is estimated.
            if showCostAsEstimate {
                self.cost = self.cost.replacingOccurrences(of: "- ", with: "- ~", options: NSString.CompareOptions.literal, range: nil)
            }
        }
        
        if tx.status == .committed && tx.outcome == .reject {
            isFailed = true
        } else if tx.status == .finalized && tx.outcome == .reject {
            isFailed = true
        }
    }
}

struct TransactionListView: View {
    @StateObject var viewModel: TransactionListViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            if viewModel.isFailed {
                HStack {
                    Image("ico_tx_failed")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("accountDetails.failed".localized)
                        .foregroundColor(Color.white)
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.init(hex: 0xFF7511, alpha: 0.12))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity)
            }
            
            
            HStack {
                Text(viewModel.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.white)
                Spacer()
                Text(viewModel.total)
                    .foregroundColor(Color.white)
                    .font(.system(size: 15, weight: .medium))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(viewModel.totalColor)
                    .clipShape(Capsule())
            }
            HStack {
                Text(viewModel.timestamp)
                    .foregroundColor(Color.blackAditional)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(viewModel.amount)
                    .foregroundColor(Color.blackAditional)
                    .font(.system(size: 11, weight: .medium))
                Text(viewModel.cost)
                    .foregroundColor(Color.blackAditional)
                    .font(.system(size: 11, weight: .medium))
            }
            
            Rectangle().fill(Color.greyMain.opacity(0.2)).frame(maxWidth: .infinity).frame(height: 1).padding(.top, 18)
            
        }
        .opacity(viewModel.isFailed ? 0.5 : 1.0)
        .listRowBackground(Color.clear)
    }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView(viewModel: .init(.init()))
    }
}
