//
//  AddTokenView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 10.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum ImportTokenError {
    case tokeSaveFailed
}

struct AddTokenView: View {
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @Binding var path: [AccountNavigationPaths]
    @StateObject var viewModel: ImportTokenViewModel
    @StateObject var searchTokenViewModel: SearchTokenViewModel
    var onTokenAdded: (() -> Void)
    @State private var contractIndex: String = ""
    @State private var tokenId: String = ""
    @State private var showingTokenIdView = false
    @State private var showTokenDetailView = false
    @State private var isEnteredNumbers: Bool = false
    @FocusState private var isContractIdTextFieldFocused: Bool
    @FocusState private var isTokenIdTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter a contract index to add tokens.")
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3)
                .opacity(0.5)
                .multilineTextAlignment(.leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Contract index")
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish3)
                        .opacity(0.5)
                        .multilineTextAlignment(.leading)
                    TextField("", text: $contractIndex)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .tint(.white)
                        .focused($isContractIdTextFieldFocused)
                        .keyboardType(.numberPad)
                        .onChange(of: contractIndex) { value in
                            handleContractIndexSearch(value)
                        }
                        .onSubmit {
                            searchTokenViewModel.runSearch(contractIndex: Int(contractIndex) ?? 0)
                        }
                }
                Image(systemName: !contractIndex.isEmpty ? "xmark" : "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.MineralBlue.blueish3)
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        if !contractIndex.isEmpty {
                            withAnimation {
                                contractIndex = ""
                                tokenId = ""
                            }
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isContractIdTextFieldFocused ? Color.MineralBlue.blueish3 : Color.grey3, lineWidth: 1)
                    .background(.clear)
                    .cornerRadius(12)
            )
            
            if viewModel.tokens.count > 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Token ID")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish3)
                                .opacity(0.5)
                                .multilineTextAlignment(.leading)
                            TextField("", text: $tokenId)
                                .foregroundColor(.white)
                                .tint(.white)
                                .focused($isTokenIdTextFieldFocused)
                                .font(.system(size: 16))
                                .onChange(of: tokenId) { value in
                                    if value.isEmpty {
                                        searchTokenViewModel.state = .idle
                                    }
                                }
                        }
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.MineralBlue.blueish3)
                            .frame(width: 20, height: 20)
                            .onTapGesture {
                                searchTokenViewModel.runSearch(tokenId, contractIndex: Int(contractIndex) ?? 0)
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTokenIdTextFieldFocused ? Color.MineralBlue.blueish3 : Color.grey3, lineWidth: 1)
                            .background(.clear)
                            .cornerRadius(12)
                    )
                }
            }
            GeometryReader { proxy in
                if tokenId.isEmpty {
                    AllTokensListView(proxy)
                } else {
                    SearchTokensListView(proxy)
                }
            }
            .refreshable {
                if tokenId.isEmpty || contractIndex.isEmpty {
                    viewModel.loadInitial()
                }
            }
            if viewModel.selectedToken != nil {
                Button {
                    viewModel.saveToken(viewModel.selectedToken)
                    onTokenAdded()
                    path.removeLast()
                } label: {
                    Text("Continue")
                        .font(.satoshi(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressedButtonStyle())
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("ico_back")
                        .resizable()
                        .foregroundColor(.greySecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(.circle)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Add token")
                        .font(.satoshi(size: 17, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
        }
        .modifier(AppBackgroundModifier())
    }
    
    private func handleContractIndexSearch(_ value: String) {
        Task {
            if !value.isEmpty && value.count > 3 {
                viewModel.tokens = []
                withAnimation(.easeInOut) {
                    isEnteredNumbers = true
                }
                await viewModel.search(name: value)
            } else {
                withAnimation(.easeInOut) {
                    isEnteredNumbers = false
                }
                viewModel.initialSearchState()
            }
        }
    }
    
    @ViewBuilder
    private func SearchTokensListView(_ proxy: GeometryProxy) -> some View {
        switch searchTokenViewModel.state {
        case .idle, .error:
            EmptyView()
        case .searching:
            ProgressView()
                .frame(width: proxy.size.width, height: proxy.size.height)
        case .found(let tokens):
            if tokens.isEmpty {
                SearchTokenFullscreenText(text: "This contract has no tokens", proxy: proxy)
            } else {
                tokenListView(tokens, proxy)
            }
        }
    }
    
    @ViewBuilder
    private func AllTokensListView(_ proxy: GeometryProxy) -> some View {
        Group {
            if !viewModel.tokens.isEmpty && !viewModel.isLoading {
                tokenListView(viewModel.tokens, proxy)
            }
        }
    }
    
    @ViewBuilder
    private func tokenListView(_ tokens: [CIS2Token], _ proxy: GeometryProxy) -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(tokens, id: \.tokenId) { token in
                        tokenCell(token, scrollProxy: scrollProxy)
                    }
                    .refreshable {
                        if tokenId.isEmpty {
                            viewModel.loadInitial()
                        }
                    }
                }
            }
            .padding(.top, 14)
        }
    }
    
    @ViewBuilder
    private func SearchTokenFullscreenText(text: String, proxy: GeometryProxy) -> some View {
        ZStack {
            Text(text)
                .font(.satoshi(size: 15, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
    }
    
    @ViewBuilder
    private func tokenCell(_ token: CIS2Token, scrollProxy: ScrollViewProxy) -> some View {
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
                  .onTapGesture {
                      path.append(.addTokenDetails(token: AccountDetailAccount.token(token: token, amount: "")))
                  }
                  .onAppear {
                      if token == viewModel.tokens.last && tokenId.isEmpty {
                          withAnimation {
                              viewModel.loadMore()
                          }
                          // Restore scroll position
                          scrollProxy.scrollTo(token.tokenId, anchor: .top)
                      }
                  }
    }
    
    private func resetToContractSearch() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingTokenIdView = false
            showTokenDetailView = false
            viewModel.selectedToken = nil
            viewModel.tokens = []
            tokenId = ""
        }
    }
}
