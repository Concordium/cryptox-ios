//
//  SearchTokenViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 22.08.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

final class SearchTokenViewModel: ObservableObject {
    enum State {
        case idle, searching, found(UnifiedTokensResult), error(String)
        
        var items: UnifiedTokensResult? {
            if case .found(let array) = self {
                return array
            }
            return nil
        }
        
        var isSearching: Bool {
            if case .searching = self {
                return true
            }
            return false
        }
    }
    
    @Published var state: SearchTokenViewModel.State = .idle
    @Published var query: String = ""
    @Published var tokenId: String = ""
    @Published var tokens: UnifiedTokensResult?
    @Published var lastVisibleTokenId: String?
    private let cis2Service: CIS2Service
    private let pltService: PLTTokenService
    
    init(cis2Service: CIS2Service, pltService: PLTTokenService){
        self.cis2Service = cis2Service
        self.pltService = pltService
    }
    
    func runSearch(_ tokenIndex: String? = nil, contractIndex: Int) {
        guard !state.isSearching else { return }
        
        state = .searching
        Task {
            do {
                let data = await searchTokenData(by: tokenIndex, contractIndex: contractIndex)
                await MainActor.run {
                    state = .found(data)
                }
            } catch {
                await MainActor.run {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func searchTokenData(by tokenId: String? = nil, contractIndex: Int) async -> UnifiedTokensResult {
        let result = UnifiedTokensResult()

        async let cis2TokensResult: Result<[CIS2Token], Error> = {
            do {
                let tokens = try await cis2Service.fetchAllTokensData(contractIndex: contractIndex, tokenIds: tokenId)
                return .success(tokens)
            } catch {
                return .failure(error)
            }
        }()

        async let pltTokensResult: Result<[PLTToken], Error> = {
            guard let tokenId else { return .success([]) }
            do {
                let tokens = try await pltService.fetchTokens(for: tokenId)
                return .success(tokens)
            } catch {
                return .failure(error)
            }
        }()

        let cis2Result = await cis2TokensResult
        let pltResult = await pltTokensResult

        switch cis2Result {
        case .success(let cis2Tokens):
            result.addNewTokens(cis2Tokens: cis2Tokens, pltTokens: [])
        case .failure(let error):
            result.cis2Error = TokenFetchingError.fetchFailed(reason: error.localizedDescription)
        }

        switch pltResult {
        case .success(let pltTokens):
            result.addNewTokens(cis2Tokens: [], pltTokens: pltTokens)
        case .failure(let error):
            result.pltError = TokenFetchingError.fetchFailed(reason: error.localizedDescription)
        }

        return result
    }
}
