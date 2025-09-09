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
    @Binding var path: [NavigationPaths]
    @State private var showingTokenIdView = false
    @State private var showTokenDetailView = false
    @State private var isEnteredNumbers: Bool = false
    @FocusState private var isContractIdTextFieldFocused: Bool
    @FocusState private var isTokenIdTextFieldFocused: Bool
    @State private var selectedTokenId: String?

    private var isContinueDisabled: Bool {
        importVM.selectedToken == nil
    }
    
    let dependencyProvider: ServicesProvider
    let account: AccountDataType
    let onTokenAdded: () -> Void

    @StateObject private var importVM: ImportTokenViewModel
    @StateObject private var searchTokenViewModel: SearchTokenViewModel

    init(path: Binding<[NavigationPaths]>,
         dependencyProvider: ServicesProvider,
         account: AccountDataType,
         onTokenAdded: @escaping () -> Void)
    {
        _path = path
        self.dependencyProvider = dependencyProvider
        self.account = account
        self.onTokenAdded = onTokenAdded

        _importVM = StateObject(wrappedValue:
            ImportTokenViewModel(storageManager: dependencyProvider.storageManager(),
                                 networkManager: dependencyProvider.networkManager(),
                                 account: account))

        _searchTokenViewModel = StateObject(wrappedValue:
            SearchTokenViewModel(
                cis2Service: CIS2Service(networkManager: dependencyProvider.networkManager(),
                                         storageManager: dependencyProvider.storageManager()),
                pltService: PLTTokenService(networkManager: dependencyProvider.networkManager(),
                                            storageManager: dependencyProvider.storageManager())
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Enter the token name or contract index to search for tokens.")
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3)
                .opacity(0.5)
                .multilineTextAlignment(.leading)

            // MARK: Query / Contract index field
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Token name or contract index")
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish3)
                        .opacity(0.5)

                    TextField("", text: $searchTokenViewModel.query)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .tint(.white)
                        .focused($isContractIdTextFieldFocused)
                        .onChange(of: searchTokenViewModel.query) { value in
                            handleContractIndexSearch(value)
                        }
                        .onSubmit {
                            if let contractIndex = Int(searchTokenViewModel.query) {
                                searchTokenViewModel.runSearch(
                                    contractIndex: contractIndex)
                            } else {
                                searchTokenViewModel.runSearch(searchTokenViewModel.query, contractIndex: 0)
                            }
                        }
                }

                Image(systemName: !searchTokenViewModel.query.isEmpty ? "xmark" : "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.MineralBlue.blueish3)
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        if !searchTokenViewModel.query.isEmpty {
                            withAnimation {
                                searchTokenViewModel.query = ""
                                searchTokenViewModel.tokenId = ""
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

            // MARK: Token ID field (only when multiple CIS2 found)
            if let tokens = importVM.tokens, tokens.cis2Tokens.count > 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Token ID")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish3)
                                .opacity(0.5)

                            TextField("", text: $searchTokenViewModel.tokenId)
                                .foregroundColor(.white)
                                .tint(.white)
                                .focused($isTokenIdTextFieldFocused)
                                .font(.system(size: 16))
                                .onChange(of: searchTokenViewModel.tokenId) { value in
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
                                searchTokenViewModel.runSearch(
                                    searchTokenViewModel.tokenId,
                                    contractIndex: Int(searchTokenViewModel.query) ?? 0
                                )
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

            // MARK: Results
            GeometryReader { proxy in
                if !searchTokenViewModel.tokenId.isEmpty {
                    AllTokensListView(proxy)
                } else {
                    SearchTokensListView(proxy)
                }
            }
            .refreshable {
                if searchTokenViewModel.tokenId.isEmpty || searchTokenViewModel.query.isEmpty {
                    importVM.loadInitial() // guard inside to avoid reloading when you have cache
                }
            }

            if case .found(_) = searchTokenViewModel.state {
                Button {
                    importVM.saveToken(importVM.selectedToken)
                    onTokenAdded()
                    path.removeLast()
                } label: {
                    Text("Update token list")
                        .font(.satoshi(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PressedButtonStyle(isDisabled: isContinueDisabled))
                .disabled(isContinueDisabled)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image("ico_back")
                        .resizable()
                        .foregroundColor(.greySecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(.circle)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("search.tokens".localized)
                    .font(.satoshi(size: 17, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .modifier(AppBackgroundModifier())
    }

    // MARK: - Helpers

    private func handleContractIndexSearch(_ value: String) {
        Task {
            if !value.isEmpty && value.count > 1 {
                importVM.tokens?.clearAll()
                withAnimation(.easeInOut) { isEnteredNumbers = true }
                await importVM.search(name: value)
            } else {
                withAnimation(.easeInOut) { isEnteredNumbers = false }
                importVM.initialSearchState()
                searchTokenViewModel.state = .idle
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
            if tokens.tokens.isEmpty {
                SearchTokenFullscreenText(text: "This contract has no tokens", proxy: proxy)
            } else {
                tokenListView(tokens, proxy)
            }
        }
    }

    @ViewBuilder
    private func AllTokensListView(_ proxy: GeometryProxy) -> some View {
        if let tokens = importVM.tokens, tokens.tokens.count > 0 && !importVM.isLoading {
            tokenListView(tokens, proxy)
        }
    }

    @ViewBuilder
    private func tokenListView(_ tokens: UnifiedTokensResult, _ proxy: GeometryProxy) -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(tokens.tokens) { token in
                        tokenCell(token, scrollProxy: scrollProxy)
                    }
                    .refreshable {
                        if searchTokenViewModel.tokenId.isEmpty {
                            importVM.loadInitial()
                        }
                    }
                }
            }
            .padding(.top, 14)
            // Restore scroll where you left off
            .onAppear {
                if let id = searchTokenViewModel.lastVisibleTokenId {
                    withAnimation {
                        scrollProxy.scrollTo(id, anchor: .center)
                    }
                }
            }
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
    private func tokenCell(_ token: UnifiedToken, scrollProxy: ScrollViewProxy) -> some View {
        let isAlreadyImported = importVM.isTokenAlreadyImported(tokenId: token.id)
        let isSelected = (importVM.selectedToken == token || isAlreadyImported)

        TokenView(token: token, isSelected: isSelected) {
            withAnimation(.easeInOut(duration: 0.3)) {
                guard !isAlreadyImported else { return }
                importVM.selectedToken = (importVM.selectedToken == token) ? nil : token
            }
        }
        .id(token.id)
        .background(selectedTokenId == token.id ? Color.selectedCell : Color.grey3.opacity(0.3))
        .cornerRadius(12)
        .onTapGesture {
            selectedTokenId = token.id
            // remember where we were before navigating
            searchTokenViewModel.lastVisibleTokenId = token.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                selectedTokenId = nil
                path.append(.addTokenDetails(token: token.toAccountDetailAccount()))
            }
        }
        .onAppear {
            // infinite scroll for list (respect tokenId from VM)
            if importVM.tokens?.tokens.last == token, searchTokenViewModel.tokenId.isEmpty {
                Task { @MainActor in
                    withAnimation { importVM.loadMore() }
                    scrollProxy.scrollTo(token.id, anchor: .top)
                }
            }
        }
    }
}
