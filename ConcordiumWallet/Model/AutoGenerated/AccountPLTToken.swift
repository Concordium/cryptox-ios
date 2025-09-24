// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let accountToken = try? JSONDecoder().decode(AccountToken.self, from: jsonData)

import Foundation

// MARK: - PLTToken
struct AccountPLTToken: Codable, Equatable, Hashable {
    let token: PLTToken
    let tokenAccountState: TokenAccountState
}

struct PLTToken: Codable, Equatable, Hashable {

    let tokenID: String
    let tokenState: TokenState

    enum CodingKeys: String, CodingKey {
        case tokenID = "tokenId"
        case tokenState
    }
}

struct TokenState: Codable, Equatable, Hashable {
    let decimals: Int
    let moduleState: ModuleState
    let tokenModuleRef: String
    let totalSupply: TokenBalance
}

struct ModuleState: Codable, Equatable, Hashable {
    let allowList, burnable, denyList: Bool
    let governanceAccount: GovernanceAccount
    let metadata: TokenMetadata?
    let mintable: Bool
    let name: String
    let paused: Bool
}

struct GovernanceAccount: Codable, Equatable, Hashable {
    let address, type: String
}

struct TokenMetadata: Codable, Equatable, Hashable {
    let url: String
    let checksumSha256: String?
}

struct TokenBalance: Codable, Equatable, Hashable {
    let decimals: Int
    let value: String
}

struct TokenAccountState: Codable, Equatable, Hashable {
    let balance: TokenBalance
    let state: TokenBalanceState
}

struct TokenBalanceState: Codable, Equatable, Hashable {
    let denyList: Bool?
    let allowList: Bool?
}

struct PLTMetadata: Codable, Equatable, Hashable {
    let description: String?
    let thumbnail: Resource?
}

struct Resource: Codable, Equatable, Hashable {
    let url: String?
}

extension AccountPLTToken {

    /// Builds a value-type `PLTToken` from a Core Data `PLTTokenEntity`.
    static func makeToken(from entity: AccountPLTTokenEntity) -> AccountPLTToken {

        // MARK: - unwrap the object graph (fail fast if critical links are nil)
        let tokenObj = entity.token
        let tokenStateObj = tokenObj.tokenState
        let moduleStateObj = tokenStateObj.moduleState
        let governanceObj = moduleStateObj.governanceAccount
        let metadataObj = moduleStateObj.metadata
        let totalSupplyObj = tokenStateObj.totalSupply
        let accountStateObj = entity.tokenAccountState
        let balanceObj = accountStateObj.balance
        let stateObj = accountStateObj.state

        // MARK: - leaf structs
        let governance = GovernanceAccount(
            address: governanceObj.address,
            type:    governanceObj.type
        )

        let metadata = TokenMetadata(url: metadataObj.url, checksumSha256: metadataObj.checksumSha256)

        let moduleState = ModuleState(
            allowList:       moduleStateObj.allowList,
            burnable:        moduleStateObj.burnable,
            denyList:        moduleStateObj.denyList,
            governanceAccount: governance,
            metadata:        metadata,
            mintable:        moduleStateObj.mintable,
            name:            moduleStateObj.name,
            paused:          moduleStateObj.paused
        )

        let totalSupply = TokenBalance(
            decimals: Int(totalSupplyObj.decimals),
            value:    totalSupplyObj.value ?? "0"
        )

        let tokenState = TokenState(
            decimals:       Int(tokenStateObj.decimals),
            moduleState:    moduleState,
            tokenModuleRef: tokenStateObj.tokenModuleRef,
            totalSupply:    totalSupply
        )

        let balance = TokenBalance(
            decimals: Int(balanceObj.decimals),
            value:    balanceObj.value ?? "0"
        )

        let state = TokenBalanceState(denyList: stateObj?.denyList, allowList: stateObj?.allowList)

        let tokenAccountState = TokenAccountState(balance: balance, state: state)

        // MARK: - root structs
        let token = PLTToken(
            tokenID:    tokenObj.tokenId,
            tokenState: tokenState
        )

        return AccountPLTToken(token: token, tokenAccountState: tokenAccountState)
    }
}

extension PLTToken: Identifiable {
    var id: Int { tokenID.hashValue ^ tokenState.decimals.hashValue }
}
