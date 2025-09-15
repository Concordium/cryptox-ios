//
//  UnifiedToken.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum UnifiedToken: Identifiable, Equatable, Hashable {
    case cis2(CIS2Token)
    case plt(PLTTokenModel)

    var id: String {
        switch self {
        case .cis2(let token): return token.tokenId
        case .plt(let token): return token.pltToken.tokenID
        }
    }
    
    var name: String {
        switch self {
        case .cis2(let token): return token.metadata.name ?? ""
        case .plt(let token): return token.pltToken.tokenState.moduleState.name
        }
    }
}

class UnifiedTokensResult {
    var tokens: [UnifiedToken]
    var cis2Error: TokenFetchingError?
    var pltError: TokenFetchingError?
    
    init(tokens: [UnifiedToken] = [], cis2Error: TokenFetchingError? = nil, pltError: TokenFetchingError? = nil) {
        self.tokens = tokens
        self.cis2Error = cis2Error
        self.pltError = pltError
    }
    
    func clearAll() {
        tokens.removeAll()
        cis2Error = nil
        pltError = nil
    }
    
    func addNewTokens(cis2Tokens: [CIS2Token], pltTokens: [PLTTokenModel]) {
        let newCIS2 = cis2Tokens.map { UnifiedToken.cis2($0) }
        let newPLT = pltTokens.map { UnifiedToken.plt($0) }
        tokens.append(contentsOf: newCIS2 + newPLT)
    }
    
    var cis2Tokens: [CIS2Token] {
        tokens.compactMap {
            if case let .cis2(token) = $0 { token } else { nil }
        }
    }
    
    var pltTokens: [PLTTokenModel] {
        tokens.compactMap {
            if case let .plt(token) = $0 { token } else { nil }
        }
    }
}

extension UnifiedToken {
    func toAccountDetailAccount() -> AccountDetailAccount {
        switch self {
        case .cis2(let token):
            return AccountDetailAccount.token(token: token, amount: "")
        case .plt(let pltToken):
            return AccountDetailAccount.plt(token: AccountPLTToken(token: pltToken.pltToken, tokenAccountState: TokenAccountState(balance: TokenBalance(decimals: 2, value: ""), state: TokenBalanceState(denyList: nil, allowList: nil))), amount: "", metadata: pltToken.metadata)
        }
    }
}
