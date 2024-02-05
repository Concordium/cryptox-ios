//
//  CIS2TokenMetadataEntity.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 29.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import Foundation
import RealmSwift

class CIS2TokenEntity: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var symbol: String = ""
    @objc dynamic var decimals: Int = 0
    @objc dynamic var descr: String = ""
    @objc dynamic var thumbnail: String = ""
    @objc dynamic var accountOwnerAddress: String = ""
    
    @objc dynamic var tokenId: String = ""
    @objc dynamic var contractName: String = ""
    
    @objc dynamic var index: Int = 0
    @objc dynamic var subindex: Int = 0
    @objc dynamic var unique: Bool = false
    
    convenience init(token: CIS2Token, address: String) {
        self.init()
        self.name = token.metadata.name ?? ""
        self.symbol = token.metadata.symbol ?? ""
        self.decimals = token.metadata.decimals ?? 0
        self.descr = token.metadata.description ?? ""
        self.thumbnail = token.metadata.thumbnail?.url ?? ""
        self.accountOwnerAddress = address
        self.tokenId = token.tokenId
        self.contractName = token.contractName
        self.index = token.contractAddress.index
        self.subindex = token.contractAddress.subindex
        self.unique = token.metadata.unique ?? false
    }
}
