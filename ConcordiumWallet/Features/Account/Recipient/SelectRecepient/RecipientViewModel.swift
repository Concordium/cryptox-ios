//
//  RecipientViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

class RecipientViewModel: Hashable {
    var name: String = ""
    var address: String = ""
    // To know the original index of the item, beause I change the list with searching
    var realIndex = 0
    var isEncrypted: Bool = false
    var recipient: RecipientDataType?
    
    init(name: String, address: String, isEncrypted: Bool = false) {
        self.name = name
        self.address = address
        self.isEncrypted = isEncrypted
    }
    
    init(recipient: RecipientDataType, realIndex: Int, isEncrypted: Bool = false) {
        self.name = recipient.name
        self.address = recipient.address
        self.realIndex = realIndex
        self.isEncrypted = isEncrypted
        self.recipient = recipient
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(address)
    }

    static func == (lhs: RecipientViewModel, rhs: RecipientViewModel) -> Bool {
        lhs.address == rhs.address
    }
}
