//
//  AnyToken.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum AnyToken: Equatable, Hashable {
    case cis2(CIS2Token)
    case plt(PLTToken)
    
    var tokenId: String {
        switch self {
        case .cis2(let token): return token.tokenId
        case .plt(let token): return token.tokenID
        }
    }
    
    var name: String {
        switch self {
        case .cis2(let token): return token.metadata.name ?? ""
        case .plt(let token): return token.tokenState.moduleState.name
        }
    }
}
