//
//  UnifiedToken.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum UnifiedToken: Identifiable, Equatable {
    case cis2(CIS2Token)
    case plt(PLTToken)

    var id: String {
        switch self {
        case .cis2(let token): return token.tokenId
        case .plt(let token): return token.tokenID
        }
    }
}

struct UnifiedTokensResult {
    var cis2: [CIS2Token]
    var plt: [PLTToken]
    var cis2Error: TokenFetchingError?
    var pltError: TokenFetchingError?
    
    mutating func clearAll() {
        cis2.removeAll()
        plt.removeAll()
        cis2Error = nil
        pltError = nil
    }
    
    mutating func addNewTokens(_ newTokens: UnifiedTokensResult) {
        cis2.append(contentsOf: newTokens.cis2)
        plt.append(contentsOf: newTokens.plt)
    }
    
    func totalTokensCount() -> Int {
        return cis2.count + plt.count
    }
}

extension UnifiedTokensResult {
    var allTokens: [UnifiedToken] {
        cis2.map { UnifiedToken.cis2($0) } + plt.map { UnifiedToken.plt($0) }
    }
}
