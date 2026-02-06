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
    @State private var showTooltip = false
    var onSuccess: ((String, String?) -> Void)
    private var shouldShowBalanceSection: Bool {
        if case .verifiablePresentation = viewModel.requestType {
            return false
        } else if case .verifiablePresentationV1 = viewModel.requestType {
            return false
        } else {
            return true
        }
    }
    
    private var isSponsoredTransaction: Bool {
        if case .sponsoredTransaction = viewModel.requestType {
            return true
        } else {
            return false
        }
    }
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack(alignment: .leading, spacing: 8) {
                Image(viewModel.iconName)
                    .padding(8)
                    .aspectRatio(contentMode: .fit)
                    .background(.blackMain)
                    .cornerRadius(12)
                Text(viewModel.title)
                    .foregroundColor(.white)
                    .font(.satoshi(size: 28, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let subtitle = viewModel.requestModel?.subtitle {
                    Text(subtitle)
                        .foregroundColor(.greyMain)
                        .font(.satoshi(size: 14, weight: .medium))
                }
                VStack(spacing: 24) {
                    if let account = viewModel.account {
                        WCAccountCell(account: account, shouldShowBalance: shouldShowBalanceSection)
                            .frame(height: shouldShowBalanceSection ? 116 : 52)
                            .padding(.bottom, 16)
                            .padding(.top, 30)
                    }
                    
                    if viewModel.requestType != nil,
                       case .tokenUpdate = viewModel.requestType! {
                        pltTokenBalanceView()
                    }
                    
                    if let error = viewModel.error {
                        errorMessageView(error: error)
                    }
                    
                    if viewModel.requestType != nil {
                        switch viewModel.requestType {
                        case .signMessage, .simpleTransfer, .signAndSend, .tokenUpdate, .sponsoredTransaction:
                            if viewModel.message != "[:]" {
                                authRequestView()
                            }
                        case .verifiablePresentation:
                            if let requestModel = viewModel.requestModel as? VerifiablePresentationRequestModel {
                                VerifiablePresentationRequestParamsView(viewModel: requestModel)
                            }
                        case .verifiablePresentationV1:
                            // For v1, use the same view structure
                            if let requestModel = viewModel.requestModel as? VerifiablePresentationV1RequestModel {
                                VerifiablePresentationV1RequestParamsView(viewModel: requestModel)
                            } else {
                                EmptyView()
                            }
                        case .none:
                            EmptyView()
                        }
                    }
                }
                
                // Show anchor loading status for v1 requests
                if case .verifiablePresentationV1 = viewModel.requestType,
                   let v1Model = viewModel.requestModel as? VerifiablePresentationV1RequestModel {
                    anchorLoadingStatusView(model: v1Model)
                }
                
                HStack(spacing: 20) {
                    Button {
                        Task(priority: .userInitiated) { await
                            viewModel.rejectRequest { dismiss() }
                        }
                    } label: {
                        Text(isSponsoredTransaction ? "Reject" : "Decline")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DeclineButtonStyle())
                    
                    Button {
                        Task(priority: .userInitiated) { await
                            viewModel.approveRequest { redirectURL in
                                dismiss()
                                onSuccess(viewModel.requestModel?.subtitle ?? "Verification", redirectURL)
                                if let redirectURL, let url = URL(string: redirectURL) {
                                    DispatchQueue.main.async {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(isSponsoredTransaction ? "Approve" : "Sign")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AllowButtonStyle(disabled: viewModel.account == nil))
                    .disabled({
                        var isV1Loading = false
                        if case .verifiablePresentationV1 = viewModel.requestType,
                           let v1Model = viewModel.requestModel as? VerifiablePresentationV1RequestModel {
                            isV1Loading = v1Model.isLoadingAnchor || v1Model.anchorLoadError != nil
                        }
                        return viewModel.account == nil || !viewModel.isSignButtonEnabled || viewModel.pltValidationError != nil || isV1Loading
                    }())
                }
                .padding(.top, 25)
                .padding(.bottom, 24)
            }
            .padding(16)
            .background(.surfaceTertiary)
            .cornerRadius(34)
            .frame(maxHeight: .infinity, alignment: .bottom)
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
        VStack(alignment: .leading, spacing: 12) {
            if let formattedDetails = viewModel.formattedTransactionDetails {
                Text(formattedDetails.type)
                    .foregroundColor(.greyMain)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(formattedDetails.details, id: \.label) { detail in
                            HStack {
                                Text(detail.label)
                                    .foregroundStyle(.whiteMain)
                                    .multilineTextAlignment(.leading)
                                    .layoutPriority(1)
                                Spacer()
                                if detail.label == "Transaction Fee", isSponsoredTransaction {
                                    freeTransactionTag
                                        .popover(isPresented: $showTooltip, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom, content: {
                                            InfoTooltipView
                                                .frame(width: 250)
                                                .presentationBackground(Color(red: 0.97, green: 0.96, blue: 0.96))
                                                .presentationCompactAdaptation(.popover)
                                        })
                                } else {
                                    Text(detail.value)
                                        .foregroundStyle(.greyMain)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                }
                .frame(maxHeight: 100)
            }
        }
        .font(.satoshi(size: 14, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
    
    private func transactionDetailRow(label: String, value: String, isAddress: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundColor(Color.greySecondary)
            
            if isAddress {
                // Show full address with copy option
                HStack {
                    Text(value)
                        .font(.satoshi(size: 13, weight: .regular))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = value
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else {
                // For messages, allow more lines and scrolling
                if label == "Message" {
                    ScrollView {
                        Text(value)
                            .font(.satoshi(size: 13, weight: .regular))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                    }
                    .frame(maxHeight: 100)
                } else {
                    Text(value)
                        .font(.satoshi(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.grey3.opacity(0.3))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func anchorLoadingStatusView(model: VerifiablePresentationV1RequestModel) -> some View {
        if model.isLoadingAnchor {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                Text("Verifying request anchor...")
                    .font(.satoshi(size: 13, weight: .medium))
                    .foregroundColor(Color.greySecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.grey3.opacity(0.3))
            .cornerRadius(12)
            .padding(.bottom, 8)
        } else if let error = model.anchorLoadError {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Pallette.error)
                    .font(.system(size: 14))
                    .padding(.top, 2)
                Text("Failed to verify request anchor: \(error)")
                    .font(.satoshi(size: 13, weight: .medium))
                    .foregroundColor(Pallette.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Pallette.error.opacity(0.1))
            .cornerRadius(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
        }
    }
    
    private var freeTransactionTag: some View {
        InfoTag(title: "Free Transaction", image: nil) {
            showTooltip = true
        }
    }
    
    private var InfoTooltipView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Transaction cost covered by:")
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Text(viewModel.sponsor ?? "")
                .font(.satoshi(size: 12, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.97, green: 0.96, blue: 0.96))
        )
    }
}
