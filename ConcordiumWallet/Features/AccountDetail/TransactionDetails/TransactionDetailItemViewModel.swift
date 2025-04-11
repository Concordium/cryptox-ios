//
//  TransactionDetailItemViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import UIKit
import Combine

typealias TransactionsDetailDataSource = UITableViewDiffableDataSource<SingleSection, TransactionDetailCell>
typealias TransactionDetailSnapShot = NSDiffableDataSourceSnapshot<SingleSection, TransactionDetailCell>

struct TransactionDetailItemViewModel: Hashable {
    var title: String
    var displayValue: String
    var displayCopy: Bool = true
}

enum TransactionDetailCell: Hashable {
    case info(TransactionCellViewModel)
    case error(String)
    case origin(TransactionDetailItemViewModel)
    case from(TransactionDetailItemViewModel)
    case to(TransactionDetailItemViewModel)
    case transactionHash(TransactionDetailItemViewModel)
    case blockHash(TransactionDetailItemViewModel)
    case details(TransactionDetailItemViewModel)
    case memo(TransactionDetailItemViewModel)
}
