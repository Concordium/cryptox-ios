//
//  ImportTokenView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 26.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum ImportTokenError {
    case tokeSaveFailed
}

@MainActor
final class ImportTokenViewModel: ObservableObject {
    @Published var tokens: [CIS2Token] = []
    @Published var selectedToken: CIS2Token?
    @Published var error: ImportTokenError?
    @Published var isLoading: Bool = false
    @Published var hasMore: Bool = true
    @Published var currentPage = 1
    
    private let storageManager: StorageManagerProtocol
    private let address: String
    private var allContractTokens = [String]()
    private let batchSize = 20
    private var contractIndex: Int?
    
    private let cis2Service: CIS2Service
    
    init(storageManager: StorageManagerProtocol, networkManager: NetworkManagerProtocol, address: String) {
        self.storageManager = storageManager
        self.address = address
        self.cis2Service = CIS2Service(networkManager: networkManager, storageManager: storageManager)
        
        logger.debugLog("savedTokens: -- \(self.storageManager.getAccountSavedCIS2Tokens(address))")
    }
    
    func search(name: String) async {
        do {
            guard let index = Int(name) else { return }
            allContractTokens = try await cis2Service.fetchTokens(contractIndex: name).tokens.map(\.token)
            contractIndex = index
            loadMore()
        } catch {
            logger.errorLog(error.localizedDescription)
        }
    }
    
    func saveToken(_ token: CIS2Token?) {
        guard let token = token else { return }
        guard !storageManager.getAccountSavedCIS2Tokens(address).contains(token) else { return }
        
        do {
            try storageManager.storeCIS2Token(token: token, address: address)
        } catch {
            logger.errorLog(error.localizedDescription)
        }
    }
    
    func loadMore() {
        guard !isLoading, hasMore, let contractIndex else { return }
        
        isLoading = true
        
        Task {
            do {
                let ids = allContractTokens.dropFirst((currentPage - 1) * batchSize).prefix(batchSize)
                
                guard !ids.isEmpty else {
                    return await MainActor.run {
                        hasMore = false
                        isLoading = false
                    }
                }
                
                let fetchedTokens = try await self.cis2Service.fetchAllTokensData(contractIndex: contractIndex, tokenIds: ids.joined(separator: ","))
                
                await MainActor.run {
                    
                    if currentPage == 1 {
                        tokens = fetchedTokens
                    } else {
                        tokens += fetchedTokens
                    }
                    hasMore = tokens.count < allContractTokens.count
                    currentPage += 1
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct ImportTokenView: View {
    @StateObject var viewModel: ImportTokenViewModel
    
    @State private var searchText: String = ""
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                List(viewModel.tokens, id: \.tokenId) { token in
                    Button {
                        viewModel.selectedToken = token
                    } label: {
                        TokenView(token: token, isSelected: viewModel.selectedToken == token)
                    }
                    .onAppear {
                        if token == viewModel.tokens.last {
                            viewModel.loadMore()
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .searchable(text: $searchText)
                .keyboardType(.numberPad)
                .onChange(of: searchText) { value in
                    Task {
                        if !value.isEmpty &&  value.count > 3 {
                            await viewModel.search(name: value)
                        } else {
                            viewModel.tokens.removeAll()
                            viewModel.selectedToken = nil
                        }
                    }
                }
                .padding(.top, 16)
                
                HStack(spacing: 20) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.vertical, 11)
                            .background(Color.clear)
                            .overlay(
                                Capsule(style: .circular)
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                    
                    Button {
                        viewModel.saveToken(viewModel.selectedToken)
                        dismiss()
                    } label: {
                        Text("Import")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.black)
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.vertical, 11)
                            .background(viewModel.selectedToken == nil ? .white.opacity(0.7) : .white)
                            .clipShape(Capsule())
                    }
                    .disabled(viewModel.selectedToken == nil)
                }
                .padding(.top, 25)
                .padding(.bottom, 24)
                .padding(.horizontal, 20)
            }
            .navigationTitle("nft.import.title")
        }
    }
}
