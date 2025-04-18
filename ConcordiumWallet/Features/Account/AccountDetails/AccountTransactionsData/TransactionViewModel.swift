//
// Created by Concordium on 29/04/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation

struct TransactionViewModel {
    var status: SubmissionStatusEnum?
    var outcome: OutcomeEnum?
    var cost: GTU?
    var amount: GTU?
    var total: GTU? // we can sometimes not know the value of an encrypted amount
    var title: String
    var date: Date
    var memo: Memo?
    var details: TransactionDetailsViewModel
    var submissionId: String?

    let source: TransactionType
    var isLast = false
    // To uniquely identity the view model in the table view
    let identifier = UUID()
}

struct TransactionDetailsViewModel {
    var rejectReason: String?
    var origin: String?
    var fromAddressName: String?
    var fromAddressValue: String?
    var toAddressName: String?
    var toAddressValue: String?
    var transactionHash: String?
    var blockHashes: [String]?
    var details: [String]?
}

private struct AddressDisplay {
    static func string(from source: String) -> String {
        String(source.prefix(6))
    }
}

// swiftlint:disable function_body_length
extension TransactionViewModel {
    init(remoteTransactionData transaction: Transaction,
         account: AccountDataType,
         balanceType: AccountBalanceTypeEnum,
         encryptedAmountLookup: (String?) -> Int?,
         recipientListLookup: (String?) -> String?) {
        var title: String = ""
        if let description = transaction.details.detailsDescription {
            title = description
        } else if let destination = transaction.details.transferDestination,
           transaction.details.transferSource != nil,
           OriginTypeEnum.typeSelf == transaction.origin?.type {
            title = recipientListLookup(destination) ?? AddressDisplay.string(from: destination)
        } else if transaction.details.transferDestination != nil,
                  let source = transaction.details.transferSource,
                  OriginTypeEnum.account == transaction.origin?.type {
            title = recipientListLookup(source) ?? AddressDisplay.string(from: source)
        }
        
        let isEncryptedAmountTransfer = transaction.details.type == "encryptedAmountTransfer"
        let isEncryptedAmountTransferWithMemo = transaction.details.type == "encryptedAmountTransferWithMemo"
        let isShielded = isEncryptedAmountTransfer || isEncryptedAmountTransferWithMemo
        
        self.init(
            status: .finalized,
            outcome: transaction.details.outcome,
            cost: GTU(intValue: Int(transaction.cost ?? "0" ) ?? 0),
            amount: (transaction.subtotal) != nil ? GTU(intValue: Int(transaction.subtotal ?? "0") ?? 0) : nil,
            total: GTU(intValue: Int(transaction.total ?? "0") ?? 0),
            title: title,
            date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime ?? 0.0)),
            memo: Memo(hex: transaction.details.memo),
            details: TransactionDetailsViewModel(remoteTransactionData: transaction, account: account, recipientListLookup: recipientListLookup),
            source: transaction
        )
        LegacyLogger.trace("Converted remote transaction to view model: \(self)")
    }
    
    init(localTransferData transfer: TransferDataType,
         submissionStatus: SubmissionStatus?,
         account: AccountDataType,
         balanceType: AccountBalanceTypeEnum,
         encryptedAmountLookup: (String?) -> Int?,
         recipientListLookup: (String?) -> String?) {
        let title: String
        switch transfer.transferType {
        case .transferToPublic:
            title = "transaction.unshieldedAmount".localized
        case .registerDelegation, .updateDelegation, .removeDelegation:
            title = "transaction.configuredelegation".localized
        case .registerBaker, .updateBakerKeys, .updateBakerPool, .updateBakerStake, .removeBaker:
            title = "transaction.configurebaker".localized
        default:
            title = recipientListLookup(transfer.toAddress) ?? AddressDisplay.string(from: transfer.toAddress)
        }
        
        let totalGTU = GTU(intValue: transfer.getPublicBalanceChange())
        var transferAmount = Int(transfer.amount) ?? 0
        transferAmount.negate() // amount is stored as positive in database, but outgoing transfer is always negative.
        let amountGTU = GTU(intValue: transferAmount)
        let costGTU = GTU(intValue: Int(transfer.cost) ?? 0)
        
        self.init(status: transfer.transactionStatus ?? SubmissionStatusEnum.received,
                  outcome: transfer.outcome,
                  cost: costGTU,
                  amount: amountGTU,
                  total: totalGTU,
                  title: title,
                  date: transfer.createdAt,
                  memo: Memo(hex: transfer.memo),
                  details: TransactionDetailsViewModel(localTransferData: transfer,
                                                       submissionStatus: submissionStatus,
                                                       account: account,
                                                       recipientListLookup: recipientListLookup),
                  source: transfer)
        LegacyLogger.trace("Converted local transfer to view model: \(self)")
    }
    
    // For mocking purpose only
    init() {
        title = ""
        date = Date()
        details = TransactionDetailsViewModel()
        total = GTU(intValue: 0)
        source = TransferEntity()
        isLast = false
    }
}

extension TransactionDetailsViewModel {
    init(remoteTransactionData transaction: Transaction, account: AccountDataType, recipientListLookup: (String?) -> String?) {
        let details = transaction.details
        
        var originAddress: String?
        if details.transferSource == nil && OriginTypeEnum.account == transaction.origin?.type {
            originAddress = transaction.origin?.address
        }
        
        var transactionEvents: [String]?
        if OutcomeEnum.success == details.outcome && details.transferSource == nil && details.transferDestination == nil {
            transactionEvents = details.events
        }
        
        let fromAddressName: String? = recipientListLookup(details.transferSource)
        
        let toAddressName: String? = recipientListLookup(details.transferDestination)
        
        self.init(rejectReason: details.rejectReason,
                  origin: (originAddress),
                  fromAddressName: fromAddressName,
                  fromAddressValue: details.transferSource,
                  toAddressName: toAddressName,
                  toAddressValue: details.transferDestination,
                  transactionHash: transaction.transactionHash,
                  blockHashes: [transaction.blockHash],
                  details: transactionEvents)
    }
    
    init(localTransferData transfer: TransferDataType,
         submissionStatus: SubmissionStatus? = nil,
         account: AccountDataType,
         recipientListLookup: (String?) -> String?) {
        self.init(rejectReason: submissionStatus?.rejectReason,
                  origin: nil,
                  fromAddressName: account.name, // local transfers are always from local account
                  fromAddressValue: transfer.fromAddress,
                  toAddressName: recipientListLookup(transfer.toAddress),
                  toAddressValue: transfer.toAddress,
                  transactionHash: submissionStatus?.transactionHash,
                  blockHashes: submissionStatus?.blockHashes,
                  details: nil)
    }
}

extension TransactionViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: TransactionViewModel, rhs: TransactionViewModel) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

extension TransactionDetailsViewModel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rejectReason.hashValue)
        hasher.combine(origin.hashValue)
        hasher.combine(fromAddressName.hashValue)
        hasher.combine(fromAddressValue.hashValue)
        hasher.combine(toAddressName.hashValue)
        hasher.combine(toAddressValue.hashValue)
        hasher.combine(transactionHash.hashValue)
        hasher.combine(blockHashes.hashValue)
        hasher.combine(details.hashValue)
    }
    
    public static func == (lhs: TransactionDetailsViewModel, rhs: TransactionDetailsViewModel) -> Bool {
        lhs.rejectReason == rhs.rejectReason &&
        lhs.origin == rhs.origin &&
        lhs.fromAddressName == rhs.fromAddressName &&
        lhs.fromAddressValue == rhs.fromAddressValue &&
        lhs.toAddressName == rhs.toAddressName &&
        lhs.toAddressValue == rhs.toAddressValue &&
        lhs.transactionHash == rhs.transactionHash &&
        lhs.blockHashes == rhs.blockHashes &&
        lhs.details == rhs.details
    }
}

extension TransactionViewModel: CustomStringConvertible {
    var description: String {
        """
        Transaction:
            title: '\(title)'
            date: \(date)
            memo: \(memo?.displayValue ?? "nil")
            cost: \(cost?.displayValueWithGStroke() ?? "nil")
            amount: \(amount?.displayValueWithGStroke() ?? "nil")
            total: \(total?.displayValueWithGStroke() ?? "")
            status: \(status?.rawValue ?? "nil"); outcome: \(outcome?.rawValue ?? "nil")
        """
    }
}
