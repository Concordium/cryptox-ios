//
//  SessionProposalView.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 18.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI
import ReownWalletKit

enum SessionProposalError: Error {
    case environmentMismatch, methodMismatch
}

final class SessionProposalViewModel: ObservableObject {
    let sessionProposal: Session.Proposal
    
    @Published var selectedAccount: AccountEntity?
    @Published var isAllowButtonDisabled: Bool = true
    @Published var error: SessionProposalError?
    
    var allowedRequestMethods = [
        "sign_and_send_transaction",
        "sign_message",
        "request_verifiable_presentation" // used for id2.5
    ]
    
    var currentChain: [String] {
#if TESTNET
        ["ccd:testnet", "ccd:4221332d34e1694168c2a0c0b3fd0f27"]
#elseif MAINNET
        ["ccd:mainnet", "ccd:9dd9ca4d19e9393877d2c44b70f89acb"]
#else // Staging
        ["ccd:stagenet", "ccd:4221332d34e1694168c2a0c0b3fd0f27"]
#endif
    }
    
    private let wallet: MobileWalletProtocol
    private let storageManager: StorageManagerProtocol
    private let redirectURL: String?
    
    // Combined namespaces from both required and optional
    // This handles the deprecation where requiredNamespaces may be empty and namespaces are in optionalNamespaces
    var proposalNamespaces: [String: ProposalNamespace] {
        var combined = sessionProposal.optionalNamespaces ?? [:]
        for (key, value) in sessionProposal.requiredNamespaces {
            combined[key] = value
        }
        return combined
    }
    
    // Find the namespace that contains the currentChain
    private var currentChainNamespace: (key: String, namespace: ProposalNamespace)? {
        for (key, namespace) in proposalNamespaces {
            if let chains = namespace.chains,
               chains.contains(where: { currentChain.contains($0.absoluteString) }) {
                return (key, namespace)
            }
        }
        return nil
    }
    
    // Chains from the current chain namespace only
    private var proposalChains: [Blockchain] {
        guard let namespace = currentChainNamespace?.namespace,
              let chains = namespace.chains else {
            return []
        }
        return Array(chains)
    }
    
    // Only the current chain for approval
    private var currentChainBlockchain: Blockchain? {
        proposalChains.first(where: { currentChain.contains($0.absoluteString) })
    }
    
    // Methods from the current chain namespace only
    private var proposalMethods: [String] {
        guard let namespace = currentChainNamespace?.namespace else {
            return []
        }
        return Array(namespace.methods)
    }
    
    // Filtered methods that are in allowedRequestMethods
    private var allowedProposalMethods: [String] {
        proposalMethods.filter { allowedRequestMethods.contains($0) }
    }
    
    // Events from the current chain namespace only
    private var proposalEvents: [String] {
        guard let namespace = currentChainNamespace?.namespace else {
            return []
        }
        return Array(namespace.events)
    }
    
    // Expose current chain namespace for UI display
    var currentChainNamespaceForDisplay: ProposalNamespace? {
        currentChainNamespace?.namespace
    }
    
    init(sessionProposal: Session.Proposal, wallet: MobileWalletProtocol, storageManager: StorageManagerProtocol, redirectURL: String? = nil) {
        self.wallet = wallet
        self.sessionProposal = sessionProposal
        self.storageManager = storageManager
        self.redirectURL = redirectURL
        
        let allAccounts = self.accounts()
        if let lastSelectedAccountAddress = AppSettings.lastSelectedAccountAddress,
           let lastSelectedAccount = allAccounts.first(where: { $0.address == lastSelectedAccountAddress }) {
            self.selectedAccount = lastSelectedAccount
        } else {
            self.selectedAccount = allAccounts.first
        }
        
        let isCorrectChain = currentChainNamespace != nil
        // All methods must be in allowedRequestMethods (no unknown methods allowed)
        // Methods can be less than allowedRequestMethods, but cannot include unknown ones
        let isCorrectMethods: Bool = proposalMethods.allSatisfy { allowedRequestMethods.contains($0) }

        logger.debugLog("""
            wc: session proposal
            currentChain: \(currentChain)
            found namespace: \(currentChainNamespace?.key ?? "none")
            chains: \(proposalChains.map(\.absoluteString))
            methods: \(proposalMethods.joined(separator: ", "))
            allowed methods: \(allowedProposalMethods.joined(separator: ", "))
        
            isCorrectChain: \(isCorrectChain)
            isCorrectMethods: \(isCorrectMethods)
        """)
        
        switch (isCorrectChain, isCorrectMethods) {
            case(true, true):
                isAllowButtonDisabled = false
            case (false, _):
                error = .environmentMismatch
            case (_, false):
                error = .methodMismatch
        }
    }
    
    func accounts() -> [AccountEntity] {
        storageManager.getAccounts().compactMap { $0 as? AccountEntity }.filter { $0.isReadOnly == false }
    }
    
    @MainActor
    func approveSessionRequest(_ completion: ((_ url: String?) -> Void)?) async {
        guard let currentChainBlockchain = currentChainBlockchain else {
            logger.debugLog("wc: Cannot approve - currentChain not found")
            return
        }
        
        let supportedAccounts: [Account] = [Account(blockchain: currentChainBlockchain, address: selectedAccount?.address ?? "")!]
        let finalRedirectURL = redirectURL ?? sessionProposal.proposer.redirect?.universal

        do {
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: [currentChainBlockchain],
                methods: allowedProposalMethods,
                events: proposalEvents,
                accounts: supportedAccounts
            )
            
            try await Sign.instance.approve(proposalId: sessionProposal.id, namespaces: sessionNamespaces)
            
            completion?(finalRedirectURL)
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
    
    @MainActor
    func rejectSessionRequest(_ completion: (() -> Void)?) async {
        do {
            try await Sign.instance.rejectSession(proposalId: sessionProposal.id, reason: .userRejected)
            completion?()
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
}

struct SessionProposalView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: SessionProposalViewModel
    
    @State var isPickerPresented = false
    @State private var isAdvancedVisible = false

    var body: some View {
        ZStack {
            Color.clear
            
            VStack {
                Spacer()
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 24) {
                    Image("connect")
                        .padding(8)
                        .aspectRatio(contentMode: .fit)
                        .background(.blackMain)
                        .cornerRadius(12)
                        .padding(.bottom, -16)
                    Text("Connect to \(viewModel.sessionProposal.proposer.name)?")
                        .foregroundColor(.white)
                        .font(.satoshi(size: 28, weight: .bold))
                        .multilineTextAlignment(.leading)
                    
                    Text(viewModel.sessionProposal.proposer.description)
                        .foregroundColor(.greyMain)
                        .font(.satoshi(size: 14, weight: .medium))
                    
                    VStack(spacing: 14) {
                        Button(action: {
                            isPickerPresented = true
                        }, label: {
                            HStack(spacing: 8) {
                                if let selectedAccount = viewModel.selectedAccount {
                                    VStack(spacing: 14) {
                                        WCAccountCell(account: selectedAccount)
                                        HStack(spacing: 8) {
                                            Text("Choose another account")
                                                .foregroundColor(.white)
                                                .font(.satoshi(size: 14, weight: .medium))
                                            Image("ico_arrow")
                                            Spacer()
                                        }
                                    }
                                } else {
                                    Text("Tap to select account")
                                        .frame(maxWidth: .infinity)
                                        .padding(16)
                                        .background(Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                        })
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Button {
                                withAnimation(.easeInOut) {
                                    isAdvancedVisible.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Advanced")
                                        .font(.satoshi(size: 14, weight: .medium))
                                        .foregroundStyle(.greyMain)
                                    Image(systemName: isAdvancedVisible ? "chevron.up" : "chevron.down")
                                        .renderingMode(.template)
                                        .foregroundStyle(.greyMain)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if isAdvancedVisible {
                                ScrollView {
                                    if let namespaces = viewModel.currentChainNamespaceForDisplay {
                                        sessionProposalView(namespaces: namespaces)
                                    }
                                }
                                .frame(height: 250)
                                .padding(.top, 12)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut, value: isAdvancedVisible)
                    }
                    .overlay {
                        if let error = viewModel.error {
                            ZStack {
                                switch error {
                                    case .environmentMismatch:
                                        Text("The session proposal did not contain a valid namespace. Allowed namespaces are: \(viewModel.currentChain)")
                                            .multilineTextAlignment(.center)
                                    case .methodMismatch:
                                        Text("An unsupported method was requested, supported methods are: \(viewModel.allowedRequestMethods.joined(separator: ", "))")
                                            .multilineTextAlignment(.center)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.thinMaterial)
                            .cornerRadius(24)
                        }
                    }
                    
                    HStack(spacing: 24) {
                        Button {
                            Task(priority: .userInitiated) {
                                await viewModel.rejectSessionRequest { dismiss() }
                            }
                        } label: {
                            Text("Decline")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(DeclineButtonStyle())
                        
                        Button {
                            Task(priority: .userInitiated) {
                                await viewModel.approveSessionRequest { url in
                                    dismiss()
                                    if let url, let redirectURL = URL(string: url) {
                                        DispatchQueue.main.async {
                                            UIApplication.shared.open(redirectURL)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text("Allow")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AllowButtonStyle(disabled: viewModel.selectedAccount == nil))
                        .opacity(viewModel.isAllowButtonDisabled ? 0.7 : 1.0)
                        .disabled(viewModel.isAllowButtonDisabled)
                    }
                    .padding(.top, 25)
                    .padding(.bottom, 24)
                }
                .padding(20)
                .background(.surfaceTertiary)
                .cornerRadius(34)
                .padding(.horizontal, 10)
            }
            .background(.clear)
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $isPickerPresented) {
            List(viewModel.accounts()) { item in
                Button(action: {
                    self.viewModel.selectedAccount = item
                    self.isPickerPresented = false
                }, label: {
                    WCAccountCell(account: item)
                })
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
    }
    
    private func sessionProposalView(namespaces: ProposalNamespace) -> some View {
        VStack {
            VStack(spacing: 0) {
                TagsView(items: Array(namespaces.chains ?? [])) {
                    Text($0.absoluteString.uppercased())
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundColor(Color.greySecondary)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 20)
                }
                HStack {
                    Text("Methods")
                        .foregroundColor(.white)
                        .font(.satoshi(size: 14, weight: .medium))
                    Spacer()
                }
                
                TagsView(items: Array(namespaces.methods)) {
                    Text($0)
                        .foregroundColor(Color.init(hex: 0x9EF2EB))
                        .font(.satoshi(size: 15, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.init(hex: 0x9EF2EB, alpha: 0.12))
                        .clipShape(Capsule())
                }
                
                if !namespaces.events.isEmpty {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Events")
                                .foregroundColor(.white)
                                .font(.satoshi(size: 14, weight: .medium))
                            
                            Spacer()
                        }
                        
                        TagsView(items: Array(namespaces.events)) {
                            Text($0)
                                .foregroundColor(Color.init(hex: 0x9EF2EB))
                                .font(.satoshi(size: 15, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.init(hex: 0x9EF2EB, alpha: 0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(20)
            .overlay(
                RoundedCorner(radius: 24, corners: .allCorners)
                    .stroke(.white.opacity(0.3), lineWidth: 2)
            )
        }
        .background(.clear)
        .cornerRadius(25, corners: .allCorners)
        .padding(.bottom, 15)
    }
}

extension AccountEntity: Identifiable {}
