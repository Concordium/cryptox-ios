//
//  SessionRequestView.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 19.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI

struct SessionRequestView: View {
    @StateObject var viewModel: SessionRequestViewModel
    
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack(spacing: 8) {
                Spacer()
                
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewModel.title)
                                .foregroundColor(.white)
                                .font(.satoshi(size: 28, weight: .semibold))
                            Text(viewModel.method)
                                .foregroundColor(.white.opacity(0.3))
                                .font(.satoshi(size: 13, weight: .regular))
                        }
                        .padding(.top, 10)
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        if let account = viewModel.account {
                            Divider()
                                .padding(.top, 12)
                                .padding(.bottom, 12)
                                .padding(.horizontal, -18)
                            
                            WCAccountCell(account: account)
                                .padding(.bottom, 16)
                        }
                        
                        if viewModel.requestType != nil,
                           case .tokenUpdate = viewModel.requestType! {
                            pltTokenBalanceView()
                        }
                        
                        if let error = viewModel.error {
                            errorMessageView(error: error)
                        }
                        
                        switch viewModel.requestType {
                            case .signMessage, .simpleTransfer, .signAndSend, .tokenUpdate:
                                if viewModel.message != "[:]" {
                                    authRequestView()
                                }
                            case .verifiablePresentation:
                                if let requestModel = viewModel.requestModel as? VerifiablePresentationRequestModel {
                                    VerifiablePresentationRequestParamsView(viewModel: requestModel)
                                } else {
                                    EmptyView()
                                }
                            case .none:
                                EmptyView()
                        }
                    }
                    .frame(minHeight: 100)
                    
                    HStack(spacing: 20) {
                        Button {
                            Task(priority: .userInitiated) { await
                                viewModel.rejectRequest { dismiss() }
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
                            Task(priority: .userInitiated) { await
                                viewModel.approveRequest { redirectURL in
                                    dismiss()
                                    if let redirectURL, let url = URL(string: redirectURL) {
                                        DispatchQueue.main.async {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text("Sign")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black)
                                .font(.satoshi(size: 17, weight: .semibold))
                                .padding(.vertical, 11)
                                .background(viewModel.account == nil ? .white.opacity(0.7) : .white)
                                .clipShape(Capsule())
                        }
                        .disabled(viewModel.account == nil || !viewModel.isSignButtonEnabled || viewModel.pltValidationError != nil)
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
        .onDisappear {
            Task(priority: .userInitiated) {
                if viewModel.shouldRejectOnDismiss {
                    await viewModel.rejectRequest {}
                }
            }
        }
    }
    
    private func errorMessageView(error: SessionRequstError) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Pallette.error)
                .font(.system(size: 14))
                .padding(.top, 2)
            
            Text(error.errorMessage.replacingOccurrences(of: "Request ", with: "").replacingOccurrences(of: "request ", with: ""))
                .font(.satoshi(size: 13, weight: .medium))
                .foregroundColor(Pallette.error)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Pallette.error.opacity(0.1))
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func pltTokenBalanceView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Always show balance if available
            if let balance = viewModel.pltTokenBalance {
                HStack {
                    Text("Balance")
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundColor(Color.greySecondary)
                    Spacer()
                    Text(balance)
                        .font(.satoshi(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.grey3.opacity(0.3))
                .cornerRadius(12)
            }
            
            if let error = viewModel.pltValidationError {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Pallette.error)
                        .font(.system(size: 14))
                        .padding(.top, 2)
                    Text(error)
                        .font(.satoshi(size: 13, weight: .medium))
                        .foregroundColor(Pallette.error)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Pallette.error.opacity(0.1))
                .cornerRadius(12)
            }
            
            if viewModel.pltTokenBalance == nil && viewModel.pltValidationError == nil {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Loading token balance...")
                        .font(.satoshi(size: 13, weight: .medium))
                        .foregroundColor(Color.greySecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.bottom, 8)
    }
    
    private func authRequestView() -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Message")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(Color.greySecondary)
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            let lines = viewModel.message.components(separatedBy: "\n")
                            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                                    let content = (try? AttributedString(markdown: line)) ?? AttributedString(line)
                                    Text(content)
                                        .foregroundColor(.white)
                                        .font(.satoshi(size: 13, weight: .medium))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    // Empty line for spacing
                                    Text("")
                                        .frame(height: 4)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 250)
                }
                .background(Color.clear)
            }
            .background(.clear)
        }
        .clipped()
        .frame(maxWidth: .infinity)
        .padding(16)
        .overlay(
            RoundedCorner(radius: 24, corners: .allCorners)
                .stroke(.white.opacity(0.3), lineWidth: 2)
        )
    }
}
