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

struct ImportTokenView: View {
    @StateObject var viewModel: ImportTokenViewModel
    @State private var searchText: String = ""
    @State private var searchTokenIdText: String = ""
    @State private var showingTokenIdView = false
    @State private var tokensArray: [CIS2Token] = []
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if showingTokenIdView {
                    searchTokenByTokenIDView()
                } else {
                    searchTokensByContractIndexView()
                }
            }
            .navigationTitle("nft.import.title")
            .animation(.easeInOut, value: showingTokenIdView)
        }
    }
    
    func searchTokensByContractIndexView() -> some View {
        VStack {
            CustomSearchBar(text: $searchText, placeholder: "Enter contract index")
                .keyboardType(.numberPad)
                .onChange(of: searchText) { value in
                    Task {
                        if !value.isEmpty && value.count > 3 {
                            await viewModel.search(name: value)
                        } else {
                            viewModel.initialSearchState()
                        }
                    }
                }
                .padding(.horizontal, 10)
                .submitLabel(.search)
            Spacer()
            
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
                    DispatchQueue.main.async {
                        showingTokenIdView = true
                    }
                } label: {
                    Text("Look for tokens")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.vertical, 11)
                        .background(viewModel.tokens.isEmpty ? .white.opacity(0.7) : .white)
                        .clipShape(Capsule())
                }
                .disabled(viewModel.tokens.isEmpty)
            }
            .padding(.top, 25)
            .padding(.bottom, 24)
            .padding(.horizontal, 20)
        }
    }
    
    func searchTokenByTokenIDView() -> some View {
        VStack {
            CustomSearchBar(text: $searchTokenIdText, placeholder: "Search for token by ID")
                .onSubmit(of: .text) {
                    Task {
                        tokensArray = await viewModel.search(tokenId: searchTokenIdText)
                    }
                }
                .onChange(of: searchTokenIdText) { value in
                    if value.isEmpty {
                        tokensArray = viewModel.tokens
                    }
                }
                .padding(.horizontal, 10)
            
            List(tokensArray, id: \.tokenId) { token in
                Button {
                    if viewModel.selectedToken != token {
                        viewModel.selectedToken = token
                    }
                    else {
                        viewModel.selectedToken = nil
                    }
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
            .onAppear {
                tokensArray = viewModel.tokens
            }
            .listStyle(.plain)
            .padding(.top, 16)
            HStack(spacing: 20) {
                Button {
                    DispatchQueue.main.async {
                        showingTokenIdView = false
                        viewModel.selectedToken = nil
                        searchTokenIdText = ""
                    }
                } label: {
                    Text("Back")
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
    }
}
