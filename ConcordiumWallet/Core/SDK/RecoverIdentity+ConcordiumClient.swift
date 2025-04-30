//
//  RecoverIdentity+ConcordiumClient.swift
//  CryptoX
//
//  Created by Max on 14.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

extension ConcordiumClient {
     /**
      * Creates the serialized input for requesting an identity issuance.
      * @param wallet the wallet for the seed phrase that the identity should be created with
      * @param provider the chosen identity provider
      * @param global the global cryptographic parameters of the current chain
      * @return returns the identity issuance request as a JSON string
      */
    
    func recoverIdentity(
        with identityProvider: IPInfo,
        global: GlobalWrapper,
        index: Int,
        seed: Seed
    ) async throws -> IdentityRecoveryResponse {
        let identityProviderID = IdentityProviderID(identityProvider.ipIdentity)
        let identityIndex = IdentityIndex(index)
        
        let seed = try WalletSeed(seedHex: seed.value, network: Self.network)
        let walletProxy = WalletProxy(baseURL: ConcordiumClient.walletProxyBaseURL)
        let identityProvider = try await Helper.findIdentityProvider(walletProxy, identityProviderID)!

        let cryptoParams = try await nodeClient.cryptographicParameters(block: .lastFinal)
        let identityReq = try Helper.makeIdentityRecoveryRequest(seed, cryptoParams, identityProvider, identityIndex)
        
        return try await identityReq.send(session: URLSession.shared)
    }
    
    func getAccount(_ resp: IdentityRecoveryResponse, seed: Seed, identityProvider: IPInfo, index: Int) async throws -> Concordium.Account {
        let cryptoParams = try await nodeClient.cryptographicParameters(block: .lastFinal)
        let credentialCounter = CredentialCounter(0)
        
        let identityProviderID = IdentityProviderID(identityProvider.ipIdentity)
        let identityIndex = IdentityIndex(index)

        let seed = try WalletSeed(seedHex: seed.value, network: Self.network)
        let walletProxy = WalletProxy(baseURL: ConcordiumClient.walletProxyBaseURL)
        let identityProvider = try await Helper.findIdentityProvider(walletProxy, identityProviderID)!
        
        let identityObject: Concordium.IdentityObject = try resp.result.get().value
        
        
        let accountDerivation = SeedBasedAccountDerivation(seed: seed, cryptoParams: cryptoParams)
         let seedIndexes = AccountCredentialSeedIndexes(
             identity: .init(providerID: identityProviderID, index: identityIndex),
             counter: credentialCounter
         )
        // Credential to deploy.
        let credential = try accountDerivation.deriveCredential(
            seedIndexes: seedIndexes,
            identity: identityObject,
            provider: identityProvider,
            threshold: 1
        )
        
        // Account used to sign the deployment.
        // The account is composed from just the credential derived above.
        // From this call the credential's signing key will be derived;
        // in the previous only the public key was.
        return try accountDerivation.deriveAccount(credentials: [seedIndexes])
    }
}

import MnemonicSwift

struct Helper {
    public static func decodeSeed(_ seedPhrase: String, _ network: Network) throws -> WalletSeed {
        let seedHex = try Mnemonic.deterministicSeedString(from: seedPhrase)
        return try WalletSeed(seedHex: seedHex, network: network)
    }
    
    public static func identityProviders(_ walletProxy: WalletProxy) async throws -> [IdentityProvider] {
        let res = try await walletProxy.getIdentityProviders.send(session: URLSession.shared)
        return try res.map { try $0.toSDKType() }
    }

    /// Fetch an identity provider with a specific ID.
    public static func findIdentityProvider(_ walletProxy: WalletProxy, _ id: IdentityProviderID) async throws -> IdentityProvider? {
        let res = try await identityProviders(walletProxy)
        return res.first { $0.info.identity == id }
    }
    
    static func makeIdentityRecoveryRequest(
        _ seed: WalletSeed,
        _ cryptoParams: CryptographicParameters,
        _ identityProvider: IdentityProvider,
        _ identityIndex: IdentityIndex
    ) throws -> IdentityRecoveryRequest {
        let identityRequestBuilder = SeedBasedIdentityRequestBuilder(
            seed: seed,
            cryptoParams: cryptoParams
        )
        let reqJSON = try identityRequestBuilder.recoveryRequestJSON(
            provider: identityProvider.info,
            index: identityIndex,
            time: Date.now
        )
        let urlBuilder = IdentityRequestURLBuilder(callbackURL: nil)
        return try urlBuilder.recoveryRequest(
            baseURL: identityProvider.metadata.recoveryStart,
            requestJSON: reqJSON
        )
    }
}
