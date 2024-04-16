//
// Created by Concordium on 19/02/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation

struct ApiConstants {

#if TESTNET
    static let proxyUrl = URL(string: "https://wallet-proxy.testnet.concordium.com")!
#elseif MAINNET
    static let proxyUrl = URL(string: "https://wallet-proxy.mainnet.concordium.software")!
#else //Staging
    static let proxyUrl = URL(string: "https://wallet-proxy.stagenet.concordium.com")!
#endif
    
    #if TESTNET
    static let scheme = "concordiumwallettest"
    static let networkId = "test"
    static let spaceseven = "https://dev.spaceseven.cloud"
    #elseif MAINNET
    static let scheme = "concordiumwallet"
    static let networkId = "prod"
    static let spaceseven = "https://spaceseven.com"
    #else //Staging
    static let scheme = "concordiumwalletstaging"
    static let networkId = "stage"
    static let spaceseven = "https://stage.spaceseven.cloud"
    #endif
    static let notabeneCallback = "\(scheme)://identity-issuer/callback" // bad naming

    static let appSettings = proxyUrl.appendingPathComponent("/v1/appSettings")

    static let ipInfo =                 proxyUrl.appendingPathComponent("v0/ip_info")
    static let ipInfoV1 = proxyUrl.appendingPathComponent("/v1/ip_info") // should check whether we have it on our be
    static let global =                 proxyUrl.appendingPathComponent("v0/global")
    static let submitCredential =       proxyUrl.appendingPathComponent("v0/submitCredential")
    static let submissionStatus =       proxyUrl.appendingPathComponent("v0/submissionStatus")
    static let accNonce =               proxyUrl.appendingPathComponent("v0/accNonce")
    static let accEncryptionKey =       proxyUrl.appendingPathComponent("v0/accEncryptionKey")
    static let submitTransfer =         proxyUrl.appendingPathComponent("v0/submitTransfer")
    static let transferCost =           proxyUrl.appendingPathComponent("v0/transactionCost")
    static let accountBalance =         proxyUrl.appendingPathComponent("v0/accBalance")
    static let accountTransactions =    proxyUrl.appendingPathComponent("v1/accTransactions")
    static let gtuDrop =                proxyUrl.appendingPathComponent("v0/testnetGTUDrop")
    static let airDrop =                proxyUrl.appendingPathComponent("v0/testnetGTUDrop")
    
    static let passiveDelegation = proxyUrl.appendingPathComponent("/v0/passiveDelegation")
    static let chainParameters = proxyUrl.appendingPathComponent("/v0/chainParameters")
    static let bakerPool = proxyUrl.appendingPathComponent("/v0/bakerPool")
    
    struct CIS2Token {
        static let tokens = proxyUrl.appendingPathComponent("/v0/CIS2Tokens")
        static let tokenMetadata = proxyUrl.appendingPathComponent("/v0/CIS2TokenMetadata")
        static let tokensBalance = proxyUrl.appendingPathComponent("/v0/CIS2TokenBalance")
        static let cis2TokensMetadataV1 = proxyUrl.appendingPathComponent("v1/CIS2TokenMetadata")
        static let cis2TokenBalanceV1 = proxyUrl.appendingPathComponent("v1/CIS2TokenBalance")
    }

    
    
    /// Generate a callback URI associated with an identifier
    static func callbackUri(with identityCreationID: String) -> String {
        "\(notabeneCallback)/\(identityCreationID)"
    }
    /// Check if the URI is a callback URI
    static func isCallbackUri(uri: String) -> Bool {
        uri.hasPrefix(notabeneCallback)
    }
    /// Get the identity creation identifier and poll URL from a callback URI.
    /// Note that the pollUrl is NOT expected to be URL-encoded.
    static func parseCallbackUri(uri: URL) -> (identityCreationId: String, pollUrl: String)? {
        let identityCreationId = uri.absoluteURL.lastPathComponent
        let uriComponents = uri.absoluteString.components(separatedBy: "#code_uri=")
        guard uriComponents.count == 2,
              let pollUrl = uriComponents.last else {
            return nil
        }
        return (identityCreationId, pollUrl)
    }
    
    
    static func build(domain: URL, path: String = "api/v2/nft/get-by-address") -> URL {
        domain.appendingPathComponent(path)
    }
}
