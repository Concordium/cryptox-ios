//
//  ImportWalletPrivateKeyView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import UIKit

struct ImportWalletPrivateKeyView: View {
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: ImportWalletPrivateKeyViewModel
 
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                Text("import.walletPrivateKey.title".localized)
                    .font(.satoshi(size: 24, weight: .medium))
                    .foregroundColor(Color.Neutral.tint1)
                    .multilineTextAlignment(.center)
                Text("import.walletPrivateKey.subtitle".localized)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundColor(Color.Neutral.tint2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            
            ErrorLabel(error: viewModel.error).padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Wallet private key")
                    .font(.satoshi(size: 16, weight: .medium))
                
                HStack {
                    if #available(iOS 16.0, *) {
                        TextField("Wallet private key here", text: $viewModel.currentInput, axis: .vertical)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 13)
                            .font(.satoshi(size: 14, weight: .regular))
                            .background(Color(.clear))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .frame(minHeight: 40)
                            .fixedSize(horizontal: false, vertical: true)
                            .onChange(of: viewModel.currentInput) { newValue in
                                if !viewModel.currentInput.isEmpty {
                                    viewModel.validateCurrentInput()
                                }
                            }
                    } else {
                        ZStack(alignment: .leading) {
                            if viewModel.currentInput.isEmpty {
                                Text("Wallet private key here")
                                    .foregroundColor(.gray)
                                    .font(.satoshi(size: 14, weight: .regular))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .allowsHitTesting(false)
                                    .zIndex(1)
                            }
                            TextEditor(text: $viewModel.currentInput)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 13)
                                .font(.satoshi(size: 14, weight: .regular))
                                .background(Color(.clear))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .frame(minHeight: 40)
                                .fixedSize(horizontal: false, vertical: true)
                                .transparentScrolling()
                                .zIndex(0)
                                .onChange(of: viewModel.currentInput) { newValue in
                                    if !viewModel.currentInput.isEmpty {
                                        viewModel.validateCurrentInput()
                                    }
                                }
                        }
                    }
                    Button(action: {
                        withAnimation {
                            if viewModel.currentInput.isEmpty {
                                if let pastedText = UIPasteboard.general.string {
                                    viewModel.currentInput = pastedText
                                }
                            } else {
                                viewModel.clearAll()
                            }
                        }
                    }) {
                        Text(viewModel.currentInput.isEmpty ? "Paste" : "Clear")
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.buttonGreyBg)
                            .cornerRadius(4)
                    }
                    .padding(4)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
            }
            .padding()
            .background(Color.textBackground.opacity(0.5))
            .cornerRadius(12)
            
            Spacer()
            
            Button(action: {
                viewModel.importAction()
            }) {
                HStack {
                    Text("recover_accounts_recover_button_title".localized)
                        .font(Font.satoshi(size: 16, weight: .medium))
                        .lineSpacing(24)
                        .foregroundColor(Color.Neutral.tint7)
                    Spacer()
                    Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                }
                .padding(.horizontal, 24)
            }
            .disabled(!viewModel.isValidPhrase)
            .frame(height: 56)
            .background(.white)
            .cornerRadius(28)
            .opacity(viewModel.isValidPhrase ? 1.0 : 0)
            .animation(.easeInOut, value: viewModel.isValidPhrase)
        }
        .ignoresSafeArea()
        .padding(16)
        .navigationBarBackButtonHidden(true)
        .modifier(AppBackgroundModifier())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(Color.Neutral.tint1)
                        .frame(width: 35, height: 35)
                        .contentShape(.circle)
                }
            }
        }
    }
}

public extension View {
    func transparentScrolling() -> some View {
        if #available(iOS 16.0, *) {
            return scrollContentBackground(.hidden)
        } else {
            return onAppear {
                UITextView.appearance().backgroundColor = .clear
            }
        }
    }
}
