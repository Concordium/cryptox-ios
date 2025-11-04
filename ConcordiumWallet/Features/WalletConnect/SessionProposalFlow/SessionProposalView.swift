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
    
    var currentChain: String {
#if TESTNET
        "ccd:testnet"
#elseif MAINNET
        "ccd:mainnet"
#else // Staging
        "ccd:stagenet"
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
    
    private var proposalChains: [Blockchain] {
        Array(Set(proposalNamespaces.compactMap { $0.value.chains }.flatMap { $0 }))
    }
    
    private var proposalMethods: [String] {
        Array(Set(proposalNamespaces.flatMap { $0.value.methods }))
    }
    
    private var proposalEvents: [String] {
        Array(Set(proposalNamespaces.flatMap { $0.value.events }))
    }
    
    init(sessionProposal: Session.Proposal, wallet: MobileWalletProtocol, storageManager: StorageManagerProtocol, redirectURL: String? = nil) {
        self.wallet = wallet
        self.sessionProposal = sessionProposal
        self.storageManager = storageManager
        self.redirectURL = redirectURL
        self.selectedAccount = self.accounts().first
        
        let isCorrectChain = proposalChains.map(\.absoluteString).contains(currentChain)
        let isCorrectMethods: Bool = Set(allowedRequestMethods).isSuperset(of: Set(proposalMethods))

        logger.debugLog("""
            wc: session proposal
            chains: \(proposalChains)
            methods: \(proposalMethods.joined(separator: ", "))
        
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
        let supportedAccounts: [Account] = proposalChains.map { Account(blockchain: $0, address: selectedAccount?.address ?? "")! }        
        let finalRedirectURL = redirectURL ?? sessionProposal.proposer.redirect?.universal

        do {
            let sessionNamespaces = try AutoNamespaces.build(
                sessionProposal: sessionProposal,
                chains: proposalChains,
                methods: proposalMethods,
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
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack {
                Spacer()
                    .padding(.bottom, 16)
                
                VStack(alignment: .leading) {
                    CryptoImage(url: viewModel.sessionProposal.proposer.icons.compactMap(\.toURL).first, size: .medium)
                        .aspectRatio(contentMode: .fit)
                    Text("Connect to \(viewModel.sessionProposal.proposer.name)?")
                        .foregroundColor(.white)
                        .font(.satoshi(size: 28, weight: .semibold))
                    
                    Text(viewModel.sessionProposal.proposer.description)
                        .foregroundColor(.gray)
                        .font(.satoshi(size: 13, weight: .regular))
                    
                    VStack {
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
                        
                        ScrollView {
                            ForEach(viewModel.proposalNamespaces.keys.sorted(), id: \.self) { chain in
                                if let namespaces = viewModel.proposalNamespaces[chain] {
                                    sessionProposalView(namespaces: namespaces)
                                }
                            }
                        }
                        .frame(height: 250)
                        .padding(.top, 12)
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
                    
                    HStack(spacing: 20) {
                        Button {
                            Task(priority: .userInitiated) {
                                await viewModel.rejectSessionRequest { dismiss() }
                            }
                        } label: {
                            Text("Decline")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .font(.satoshi(size: 17, weight: .semibold))
                                .padding(.vertical, 11)
                                .background(Color.clear)
                                .overlay(
                                    Capsule(style: .circular)
                                        .stroke(.white, lineWidth: 2)
                                )
                        }
                        
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
                                .foregroundColor(.black)
                                .font(.satoshi(size: 17, weight: .semibold))
                                .padding(.vertical, 11)
                                .background(viewModel.selectedAccount == nil ? .white.opacity(0.7) : .white)
                                .clipShape(Capsule())
                        }
                        .opacity(viewModel.isAllowButtonDisabled ? 0.7 : 1.0)
                        .disabled(viewModel.isAllowButtonDisabled)
                    }
                    .padding(.top, 25)
                    .padding(.bottom, 24)
                }
                .padding(20)
                .background(Color.blackSecondary)
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
            VStack(alignment: .leading) {
                TagsView(items: Array(namespaces.chains ?? [])) {
                    Text($0.absoluteString.uppercased())
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundColor(Color.greySecondary)
                }
                
                VStack(spacing: 0) {
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
                .padding(16)
                .overlay(
                    RoundedCorner(radius: 24, corners: .allCorners)
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
            }
            .background(.thinMaterial)
            .cornerRadius(25, corners: .allCorners)
        }
        .padding(.bottom, 15)
    }
}

extension AccountEntity: Identifiable {}
