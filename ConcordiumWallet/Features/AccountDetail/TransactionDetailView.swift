//
//  TransactionDetailView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 17.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import JDStatusBarNotification

struct TransactionDetailView: View {
    
    @StateObject var viewModel: TransactionDetailViewModel
    @State private var showToast = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 2) {
                Spacer()
                HStack(alignment: .center, spacing: 8) {
                    Image("Copy")
                }
                .onTapGesture {
                    CopyPasterHelper.copy(string: viewModel.transaction.details.transactionHash ?? "")
                    withAnimation {
                        showToast = true
                    }
                }
                .padding(8)
                .background(.white.opacity(0.07))
                .cornerRadius(4)
                
                if let transactionHash = viewModel.transaction.details.transactionHash {
                    HStack(alignment: .center, spacing: 8) {
                        Image("ArrowSquareOut")
                    }
                    .onTapGesture {
                        let urlString = AppConstants.Transaction.ccdExplorer + (transactionHash)
                        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding(8)
                    .background(.white.opacity(0.07))
                    .cornerRadius(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.cells, id: \.self) { cell in
                    switch cell {
                    case .info(let transaction):
                        transactionInfoSection(transaction)
                    case .origin(let vm),
                            .to(let vm),
                            .from(let vm),
                            .blockHash(let vm),
                            .transactionHash(let vm),
                            .details(let vm),
                            .memo(let vm):
                        detailItemCell(vm: vm)
                    case .error(let errorText):
                        errorCell(errorText: errorText)
                    }
                    Divider()
                }
            }
            .padding(15)
            .background(.grey3.opacity(0.3))
            .cornerRadius(12)
            
            Spacer()
        }
        .toast(isPresented: $showToast, position: .bottom) {
            ToastGradientView(title: "Transaction hash copied", imageName: "ico_successfully")
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
    
    private func transactionInfoSection(_ tx: TransactionCellViewModel) -> some View {
        VStack(spacing: 8) {
            
            HStack {
                Text(tx.title)
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(tx.amount) CCD")
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundStyle(tx.totalColor)
            }
            
            HStack {
                Text(tx.fullDate)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish2.opacity(0.5))
                
                Spacer()
                Text(tx.cost)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
            }
        }
    }
    
    private func detailItemCell(vm: TransactionDetailItemViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vm.title)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
            
            Text(vm.displayValue)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(.white)
        }
    }
    
    private func errorCell(errorText: String) -> some View {
        Text(errorText)
            .font(.satoshi(size: 12, weight: .medium))
            .foregroundStyle(.attentionRed)
    }
}

final class TransactionDetailViewModel: ObservableObject, Hashable, Equatable {
    @Published var cells: [TransactionDetailCell] = []
    
    var transaction: TransactionViewModel
    
    init(transaction: TransactionViewModel) {
        self.transaction = transaction
        setupCells()
    }
    
    private func setupCells() {
        var cells: [TransactionDetailCell] = []
        
        cells.append(.info(TransactionCellViewModel(transactionVM: transaction)))
        cells.append(contentsOf: getRejectReasonCell())
        cells.append(contentsOf: getMemoCell())
        cells.append(contentsOf: getOriginCell())
        cells.append(contentsOf: getFromAddressCell())
        cells.append(contentsOf: createToAddressCell())
        cells.append(contentsOf: getTransactionHashCell())
        cells.append(contentsOf: createBlockHashCell())
        cells.append(contentsOf: createDetailsCell())
        
        self.cells = cells
    }
    
    private func getRejectReasonCell() -> [TransactionDetailCell] {
        if let rejectReason = transaction.details.rejectReason {
            return [.error(rejectReason)]
        }
        return []
    }
    
    private func getMemoCell() -> [TransactionDetailCell] {
        if let memo = transaction.memo {
            let title = "accountDetails.memo".localized
            let displayVM = TransactionDetailItemViewModel(title: title, displayValue: memo.displayValue)
            return [.origin(displayVM)]
        }
        return []
    }
    
    private func getOriginCell() -> [TransactionDetailCell] {
        if let origin = transaction.details.origin {
            let title = "accountDetails.origin".localized
            let displayVM = TransactionDetailItemViewModel(title: title, displayValue: origin)
            return [.origin(displayVM)]
        }
        return []
    }
    
    private func getFromAddressCell() -> [TransactionDetailCell] {
        if let fromAddressValue = transaction.details.fromAddressValue {
            let title = "accountDetails.fromAddress".localized
            let displayVM = TransactionDetailItemViewModel(title: title, displayValue: fromAddressValue)
            return [.from(displayVM)]
        }
        return []
    }
    
    private func createToAddressCell() -> [TransactionDetailCell] {
        if let toAddressValue = transaction.details.toAddressValue {
            let title = "accountDetails.toAddress".localized
            let displayVM = TransactionDetailItemViewModel(title: title, displayValue: toAddressValue)
            return [.to(displayVM)]
        }
        return []
    }
    
    private func getTransactionHashCell() -> [TransactionDetailCell] {
        if let transactionHash = transaction.details.transactionHash {
            let title = "accountDetails.transactionHash".localized
            let value = transactionHash
            let displayVM = TransactionDetailItemViewModel(title: title, displayValue: value)
            return [.transactionHash(displayVM)]
        }
        return []
    }
    
    private func createBlockHashCell() -> [TransactionDetailCell] {
        var blockHashValue = ""
        if transaction.status == .received {
            blockHashValue = "accountDetails.submitted".localized
        } else if transaction.status == .absent {
            blockHashValue = "accountDetails.failed".localized
        }
        if let blockHashes = transaction.details.blockHashes, blockHashes.count > 0 {
            blockHashValue = blockHashes.joined(separator: "\n")
        }
        if !blockHashValue.isEmpty {
            let title = "accountDetails.blockHash".localized
            let displayVM = TransactionDetailItemViewModel(title: title, displayValue: blockHashValue)
            return [.blockHash(displayVM)]
        }
        return []
    }
    
    private func createDetailsCell() -> [TransactionDetailCell] {
        var detailsValue = ""
        if let details = transaction.details.details, details.count > 0 {
            detailsValue = details.joined(separator: "\n")
        }
        if !detailsValue.isEmpty {
            let title = "accountDetails.events".localized
            let displayVM = TransactionDetailItemViewModel(title: title, displayValue: detailsValue, displayCopy: false)
            return [.details(displayVM)]
        }
        return []
    }
    
    static func == (lhs: TransactionDetailViewModel, rhs: TransactionDetailViewModel) -> Bool {
        lhs.transaction == rhs.transaction && lhs.cells == rhs.cells
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(transaction)
        hasher.combine(cells)
    }
}
