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
                            Text("Sign transaction")
                                .foregroundColor(.white)
                                .font(.system(size: 28, weight: .semibold))
                            Text(viewModel.sessionRequest.method)
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: 13, weight: .regular))
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
                        
                        if viewModel.message != "[:]" {
                            authRequestView()
                        }
                    }
                    .frame(minHeight: 100)
                    .overlay {
                        if let error = viewModel.error {
                            ZStack {
                                Text(error.errorMessage)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.thinMaterial)
                            .cornerRadius(24)
                        }
                    }
                    
                    if let errorText = viewModel.errorText {
                        VStack {
                            Text("qrtransactiondata.error.title".localized)
                                .foregroundColor(Pallette.error)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            Text(errorText)
                                .foregroundColor(Pallette.errorText)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        .padding(.top, 12)
                    }
                    
                    HStack(spacing: 20) {
                        Button {
                            Task(priority: .userInitiated) { await
                                viewModel.rejectRequest { dismiss() }
                            }
                        } label: {
                            Text("Decline")
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
                            Task(priority: .userInitiated) { await
                                viewModel.approveRequest { dismiss() }
                            }
                        } label: {
                            Text("Sign")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.black)
                                .font(.system(size: 17, weight: .semibold))
                                .padding(.vertical, 11)
                                .background(viewModel.account == nil ? .white.opacity(0.7) : .white)
                                .clipShape(Capsule())
                        }
                        .disabled(viewModel.account == nil || !viewModel.isSignButtonEnabled)
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
    
    private func authRequestView() -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Message")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.greySecondary)
                
                VStack(spacing: 0) {
                    ScrollView {
                        Text(viewModel.message)
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(height: 250)
                }
                .background(Color.clear)
            }
            .background(.clear)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .overlay(
            RoundedCorner(radius: 24, corners: .allCorners)
                .stroke(.white.opacity(0.3), lineWidth: 2)
        )
    }
}
