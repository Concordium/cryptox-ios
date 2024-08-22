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
    @StateObject var searchTokenViewModel: SearchTokenViewModel
    @State private var contractIndex: String = ""
    @State private var tokenId: String = ""
    @State private var showingTokenIdView = false
    @State private var showTokenDetailView = false
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
    
    @ViewBuilder
    private func searchTokensByContractIndexView() -> some View {
        VStack {
            searchBar(
                text: $contractIndex,
                placeholder: "Enter contract index",
                keyboardType: .numberPad,
                onSubmit: nil
            )
            .onChange(of: contractIndex) { value in
                handleContractIndexSearch(value)
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
            actionButtons(
                primaryTitle: "Look for tokens",
                primaryAction: { showingTokenIdView = true },
                primaryDisabled: viewModel.tokens.isEmpty,
                secondaryTitle: "Cancel",
                secondaryAction: { dismiss() }
            )
        }
    }
    
    @ViewBuilder
    private func searchTokenByTokenIDView() -> some View {
        VStack {
            searchBar(
                text: $tokenId,
                placeholder: "Search for token by ID",
                keyboardType: .default,
                onSubmit: {
                    searchTokenViewModel.runSearch(tokenId, contractIndex: Int(contractIndex) ?? 0)
                }
            )
            .onChange(of: tokenId) { value in
                if value.isEmpty {
                    searchTokenViewModel.state = .idle
                }
            }
            .padding(.horizontal, 10)
            
            GeometryReader { proxy in
                if tokenId.isEmpty {
                    AllTokensListView(proxy)
                } else {
                    SearchTokensListView(proxy)
                }
            }
            .refreshable {
                if tokenId.isEmpty {
                    viewModel.loadInitial()
                }
            }
            
            actionButtons(
                primaryTitle: "Import",
                primaryAction: {
                    viewModel.saveToken(viewModel.selectedToken)
                    dismiss()
                },
                primaryDisabled: viewModel.selectedToken == nil,
                secondaryTitle: "Back",
                secondaryAction: resetToContractSearch
            )
        }
    }
    
    @ViewBuilder
    private func searchBar(text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType, onSubmit: (() -> Void)?) -> some View {
        CustomSearchBar(text: text, placeholder: placeholder)
            .keyboardType(keyboardType)
            .onSubmit {
                onSubmit?()
            }
    }
    
    private func handleContractIndexSearch(_ value: String) {
        Task {
            if !value.isEmpty && value.count > 3 {
                viewModel.tokens = []
                await viewModel.search(name: value)
            } else {
                viewModel.initialSearchState()
            }
        }
    }
    
    @ViewBuilder
    private func actionButtons(primaryTitle: String, primaryAction: @escaping () -> Void, primaryDisabled: Bool, secondaryTitle: String, secondaryAction: @escaping () -> Void) -> some View {
        HStack(spacing: 20) {
            Button(action: secondaryAction) {
                Text(secondaryTitle)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.vertical, 11)
                    .background(Color.clear)
                    .overlay(Capsule().stroke(.white, lineWidth: 2))
            }
            
            Button(action: primaryAction) {
                Text(primaryTitle)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.vertical, 11)
                    .background(primaryDisabled ? .white.opacity(0.7) : .white)
                    .clipShape(Capsule())
            }
            .disabled(primaryDisabled)
        }
        .padding(.top, 25)
        .padding(.bottom, 24)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func SearchTokensListView(_ proxy: GeometryProxy) -> some View {
        switch searchTokenViewModel.state {
        case .idle:
            SearchTokenFullscreenText(text: "Enter token ID and tap Search", proxy: proxy)
        case .searching:
            ProgressView()
                .frame(width: proxy.size.width, height: proxy.size.height)
        case .found(let tokens):
            if tokens.isEmpty {
                SearchTokenFullscreenText(text: "No tokens matching given predicate.", proxy: proxy)
            } else {
                tokenListView(tokens, proxy)
            }
        case .error:
            SearchTokenFullscreenText(text: "No tokens matching given predicate.", proxy: proxy)
        }
    }
    
    @ViewBuilder
    private func AllTokensListView(_ proxy: GeometryProxy) -> some View {
        Group {
            if !viewModel.isLoading && viewModel.tokens.isEmpty {
                SearchTokenFullscreenText(text: "No tokens found.", proxy: proxy)
            } else {
                tokenListView(viewModel.tokens, proxy)
            }
        }
    }
    
    @ViewBuilder
    private func tokenListView(_ tokens: [CIS2Token], _ proxy: GeometryProxy) -> some View {
        List(tokens, id: \.tokenId) { token in
            TokenView(token: token,
                      isSelected: (viewModel.selectedToken == token || viewModel.isTokenAlreadyImported(tokenId: token.tokenId))) {
                withAnimation(Animation.easeInOut(duration: 0.3)) {
                    guard !viewModel.isTokenAlreadyImported(tokenId: token.tokenId) else { return }
                    if viewModel.selectedToken == token {
                        viewModel.selectedToken = nil
                    } else {
                        viewModel.selectedToken = token
                    }
                }
            }
                      .overlay {
                          NavigationLink(destination: viewModel.showCIS2TokenDetailsFlow(token, onDismiss: {
                              showTokenDetailView = false
                          }), isActive: $showTokenDetailView) {
                              
                          }
                          .fixedSize()
                          .opacity(0.0)
                      }
                      .onAppear {
                          if token == viewModel.tokens.last && tokenId.isEmpty {
                              viewModel.loadMore()
                          }
                      }
                      .listRowSeparator(.hidden)
        }
        .refreshable {
            if tokenId.isEmpty {
                viewModel.loadInitial()
            }
        }
        .listStyle(.plain)
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private func SearchTokenFullscreenText(text: String, proxy: GeometryProxy) -> some View {
        ZStack {
            Text(text)
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
    }
    
    private func resetToContractSearch() {
        showingTokenIdView = false
        showTokenDetailView = false
        viewModel.selectedToken = nil
        viewModel.tokens = []
        tokenId = ""
    }
}
