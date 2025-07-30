//
//  TokenFetcher.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum TokenFetchingError: Error {
    case failedToFetchTokens(error: Error)
    case contractIndexMissing
    case fetchFailed(reason: String)
}

class TokenFetcher {
    let pltTokenService: PLTTokenServiceProtocol
    let cis2Service: CIS2Service

    init(pltTokenService: PLTTokenServiceProtocol, cis2Service: CIS2Service) {
        self.pltTokenService = pltTokenService
        self.cis2Service = cis2Service
    }

    func fetchAllTokens(for tokenIDs: [String], contractIndex: Int?) async -> UnifiedTokensResult {
        async let pltResult: Result<[PLTToken], TokenFetchingError> = {
            let tokens = await pltTokenService.fetchTokenInfo(for: tokenIDs)
            return .success(tokens)
        }()

            async let cis2Result: Result<[CIS2Token], TokenFetchingError> = {
                do {
                    if let contractIndex {
                        let tokens = try await cis2Service.fetchAllTokensData(contractIndex: contractIndex, tokenIds: tokenIDs.joined(separator: ","))
                        return .success(tokens)
                    } else {
                        return .failure(.contractIndexMissing)
                    }
                } catch {
                    return .failure(.failedToFetchTokens(error: error))
                }
            }()
        let pltTokensResult = await pltResult
        let cis2TokensResult = await cis2Result

        return UnifiedTokensResult(
            cis2: (try? cis2TokensResult.get()) ?? [],
            plt: (try? pltTokensResult.get()) ?? [],
            cis2Error: cis2TokensResult.failure,
            pltError: pltTokensResult.failure
        )
    }
}

extension Result {
    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
