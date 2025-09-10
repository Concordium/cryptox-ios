//
//  PLTTokenEntity + Extensions.swift
//  CryptoX
//
//  Created by Zhanna Komar on 04.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

extension PLTTokenEntity {

    func asPLTToken() -> PLTToken? {
        let tokenState = tokenState
        let moduleState = tokenState.moduleState
        let governanceAccount = moduleState.governanceAccount
        let metadata = moduleState.metadata
        return PLTToken(tokenID: tokenId,
                        tokenState: TokenState(decimals: Int(tokenState.decimals),
                                        moduleState: ModuleState(allowList: moduleState.allowList,
                                                                 burnable: moduleState.burnable,
                                                                 denyList: moduleState.denyList,
                                                                 governanceAccount: GovernanceAccount(address: governanceAccount.address,
                                                                                                      type: governanceAccount.type),
                                                                 metadata: TokenMetadata(url: metadata.url),
                                                                 mintable: moduleState.mintable,
                                                                 name: moduleState.name,
                                                                 paused: moduleState.paused),
                                        tokenModuleRef: tokenState.tokenModuleRef,
                                               totalSupply: TokenBalance(decimals: Int(tokenState.decimals), value: "0.00"))
        )
    }
}
