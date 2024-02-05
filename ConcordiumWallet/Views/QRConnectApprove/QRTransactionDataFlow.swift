//
//  QRTransactionView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 14.10.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation
import CloudKit


protocol ActionTypeProtocol { }

protocol ActionProtocol: AnyObject {
    func didInitiate(action: ActionTypeProtocol)
}


enum QRTransaction {
    
    enum Action: ActionTypeProtocol {
        case accept
        case cancel
        case edit
        case showData
    }
    
}
