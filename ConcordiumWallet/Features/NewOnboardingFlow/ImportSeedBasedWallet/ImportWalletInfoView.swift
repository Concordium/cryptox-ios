//
//  ImportWalletInfoView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 18.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ImportWalletInfoView: View {
    let seedWords = ["badge", "skin", "off", "combine", "certain", "trim"]
    @SwiftUI.Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Image("infoBackground").resizable()
            ScrollView {
                
                VStack(alignment: .center, spacing: 20) {
                    Text("Import via seed phrase\n or wallet private key")
                        .font(.satoshi(size: 24, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint7)
                        .multilineTextAlignment(.center)
                        .padding(16)
                    Example(
                        title: "Seed phrase",
                        description: "recover_accounts.info.seedPhraseDescription".localized,
                        example: "badge skin off combine certain trim",
                        isGrid: true
                    )
                    
                    Divider()
                        .tint(Color("grey_additional"))
                    
                    Example(
                        title: "Wallet private key",
                        description: "recover_accounts.info.WalletKeyDescription".localized,
                        example: "hrs12thsmplcdf99hw4scrtkycldllklkl8lwthdffrntwrds...",
                        isGrid: false
                    )
                                        
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Okay")
                            .font(.satoshi(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Neutral.tint7)
                            .foregroundColor(Color.Neutral.tint1)
                            .cornerRadius(25)
                    }
                    .padding(.bottom, 10)
                }
                .padding()
            }
        }
    }
    
    
    @ViewBuilder
    func Example(title: String, description: String, example: String, isGrid: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.satoshi(size: 16, weight: .medium))
                .foregroundStyle(Color.Neutral.tint6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let descriptionArray = description.components(separatedBy: "\n")
            ForEach(descriptionArray, id: \.self) { sentence in
                HStack {
                    Text("•")
                        .font(.satoshi(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Neutral.tint5)
                    Text(sentence)
                        .font(.satoshi(size: 14, weight: .light))
                        .foregroundStyle(Color.Neutral.tint5)
                        .lineLimit(nil)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            VStack(alignment: .leading,spacing: 7) {
                Text("Example")
                    .font(.satoshi(size: 14, weight: .light))
                    .foregroundStyle(Color.Neutral.tint6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                let wordsArray = example.components(separatedBy: " ")
                
                LazyHGrid(rows: [GridItem(.flexible(minimum: 50))], content: {
                    ForEach(wordsArray, id: \.self) { word in
                        Text(word)
                            .font(.satoshi(size: 14, weight: .regular))
                            .foregroundStyle(Color.Neutral.tint4)
                            .padding(isGrid ? 5 : 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .fixedSize(horizontal: true, vertical: false)
                            .multilineTextAlignment(.center)
                    }
                })
            }
        }
    }
}

#Preview {
    ImportWalletInfoView()
}
