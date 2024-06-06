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
    
    private let storageManager: StorageManagerProtocol
    private let address: String
    
    init(storageManager: StorageManagerProtocol, address: String) {
        self.storageManager = storageManager
        self.address = address
        
        logger.debugLog("savedTokens: -- \(self.storageManager.getAccountSavedCIS2Tokens(address))")
    }
    
    func search(name: String) async {
        do {
            guard let index = Int(name) else { return }
            tokens = try await CIS2TokenService.getCIS2Tokens(for: index)
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
