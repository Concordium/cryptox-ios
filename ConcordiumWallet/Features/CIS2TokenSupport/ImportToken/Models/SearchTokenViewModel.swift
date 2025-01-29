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
        case idle, searching, found([CIS2Token]), error(String)
        
        var items: [CIS2Token] {
            if case .found(let array) = self {
                return array
            }
            return []
        }
        
        var isSearching: Bool {
            if case .searching = self {
                return true
            }
            return false
        }
    }
    
    @Published var state: SearchTokenViewModel.State = .idle
    
    private let cis2Service: CIS2Service
    
    init(cis2Service: CIS2Service){
        self.cis2Service = cis2Service
    }
    
    func runSearch(_ tokenIndex: String? = nil, contractIndex: Int) {
        guard !state.isSearching else { return }
        
        state = .searching
        Task {
            do {
                let data = try await searchTokenData(by: tokenIndex, contractIndex: contractIndex)
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
    
    private func searchTokenData(by tokenId: String? = nil, contractIndex: Int) async throws -> [CIS2Token] {
        var tokens = [CIS2Token]()
        do {
            tokens = try await cis2Service.fetchAllTokensData(contractIndex: contractIndex, tokenIds: tokenId)
        } catch {
            logger.errorLog(error.localizedDescription)
        }
        return tokens
        
    }
}
