//
//  TransactionCellViewModel.swift
//  ConcordiumWallet
//
//  Created by Concordium on 5/5/20.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation
import SwiftUI

struct TransactionCellViewModel: Equatable, Hashable {
    var title = ""
    var date = ""
    var memo: String?
    var fullDate = ""
    var total: String?
    var amount: String?
    var cost: String?
    var titleColor: Color = .white
    var totalColor: Color = .white
    var amountColor: Color = .white
    var costColor: Color = .white
    var showCostAndAmount = true
    var showErrorIcon = true
    var showStatusIcon = true
    var statusIcon = #imageLiteral(resourceName: "ok_x2")
    var showCostAsEstimate = false
    var pltAmount: String?
    
    // swiftlint:disable all
    init(transactionVM: TransactionViewModel) {
        title = transactionVM.title
        date = GeneralFormatter.formatTime(for: transactionVM.date)
        memo = transactionVM.memo?.displayValue
        fullDate = GeneralFormatter.formatDateWithTime(for: transactionVM.date)
        total = transactionVM.total?.displayValueWithCCDStroke()
        
        if transactionVM.status == .received
            || (transactionVM.status == .committed && transactionVM.outcome == .ambiguous) {
            showErrorIcon = false
            statusIcon = #imageLiteral(resourceName: "time")
            costColor = .primary
            showCostAsEstimate = true
            totalColor = .white
        } else if transactionVM.status == .absent {
            titleColor = .fadedText
            amountColor = .fadedText
            costColor = .fadedText
            showCostAsEstimate = true
            showStatusIcon = false
        } else if transactionVM.status == .committed && transactionVM.outcome == .success {
            showErrorIcon = false
            statusIcon = #imageLiteral(resourceName: "ok")
            if let total = transactionVM.total?.intValue, total > 0 {
                totalColor = .white
            }
        } else if transactionVM.status == .finalized && transactionVM.outcome == .success {
            showErrorIcon = false
            if transactionVM.total?.intValue != nil {
                totalColor = .success
            }
        } else if transactionVM.status == .committed && transactionVM.outcome == .reject {
            titleColor = .fadedText
            statusIcon = #imageLiteral(resourceName: "ok")
            amountColor = .fadedText
        } else if transactionVM.status == .finalized && transactionVM.outcome == .reject {
            titleColor = .fadedText
            amountColor = .fadedText
        }
        self.amount = transactionVM.amount?.displayValueWithCCDStroke()
        if let cost = transactionVM.cost, cost.intValue != 0 {
            self.cost = "with fee " + cost.displayValueWithCCDStroke()
            
            // Prepend with ~ if cost is estimated.
            if showCostAsEstimate {
                self.cost = self.cost?.replacingOccurrences(of: "- ", with: "- ~", options: NSString.CompareOptions.literal, range: nil)
            }
        }
        self.pltAmount = transactionVM.getPLTAmountToDisplay()
    }
}
