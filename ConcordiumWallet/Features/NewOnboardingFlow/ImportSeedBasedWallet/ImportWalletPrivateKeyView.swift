//
//  ImportWalletPrivateKeyView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct ImportWalletPrivateKeyView: View {
    
    @State var walletPrivateKey: String = ""
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
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
                
            }.frame(maxWidth: .infinity)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Wallet private key")
                    .font(.satoshi(size: 16, weight: .medium))
                
                ZStack(alignment: .trailing) {
                    TextField("Wallet private key here", text: $walletPrivateKey)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.buttonGreyBg, lineWidth: 1))
                        .frame(minWidth: 100, maxWidth: .infinity)
                    
                    Button(action: {
                        withAnimation {
                            if walletPrivateKey.isEmpty {
                                if let pastedText = UIPasteboard.general.string {
                                    walletPrivateKey = pastedText
                                }
                            } else {
                                walletPrivateKey = ""
                            }
                        }
                    }) {
                        Text(walletPrivateKey.isEmpty ? "Paste" : "Clear")
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.buttonGreyBg)
                            .cornerRadius(4)
                    }
                    .animation(.easeInOut, value: walletPrivateKey.isEmpty)
                    .padding(4)
                }
            }
            .padding()
            .background(Color.textBackground.opacity(0.5))
            .cornerRadius(12)
            Spacer()
            Button(action: {
//                viewModel.importAction()
            }, label: {
                HStack {
                    Text("recover_accounts_recover_button_title".localized)
                        .font(Font.satoshi(size: 16, weight: .medium))
                        .lineSpacing(24)
                        .foregroundColor(Color.Neutral.tint7)
                    Spacer()
                    Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                }
                .padding(.horizontal, 24)
            })
//            .disabled(!viewModel.isValidPhrase)
            .frame(height: 56)
            .background(Color.EggShell.tint1)
            .cornerRadius(28, corners: .allCorners)
//            .opacity(viewModel.isValidPhrase ? 1.0 : 0)
//            .animation(.easeInOut, value: viewModel.isValidPhrase)
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

struct ResizableTextFieldWithPasteButton_Previews: PreviewProvider {
    static var previews: some View {
        ImportWalletPrivateKeyView()
    }
}

