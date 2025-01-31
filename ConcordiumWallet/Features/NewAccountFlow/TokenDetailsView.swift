//
//  TokenDetailsView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 13.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct TokenDetailsView: View {
    
    var token: AccountDetailAccount
    var isAddTokenDetails: Bool = false

    @Binding var showRawMd: Bool
    
    var body: some View {
        ZStack {
            Color.blackMain
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 31) {
                VStack(alignment: .leading, spacing: 8) {
                    switch token {
                    case .ccd(_):
                        HStack(spacing: 8) {
                            Image("ccd")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("CCD token")
                                .font(.satoshi(size: 16, weight: .semibold))
                                .foregroundStyle(.whiteMain)
                        }
                        Text("Description")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        Text("ccd.description".localized)
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity)
                            .frame(height: 1)
                            .background(.white.opacity(0.1))
                        
                        Text("Decimals")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        
                        Text("0 – 6")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        
                    case .token(let token, _):
                        HStack(spacing: 8) {
                            if let url = token.metadata.thumbnail?.url {
                                CryptoImage(url: url.toURL, size: .custom(width: 20, height: 20))
                                    .aspectRatio(contentMode: .fit)
                            }
                            Text(token.metadata.name ?? "")
                                .font(.satoshi(size: 16, weight: .semibold))
                                .foregroundStyle(.whiteMain)
                        }
                        Text("Description")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        Text(token.metadata.description ?? "")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity)
                            .frame(height: 1)
                            .background(.white.opacity(0.1))
                        
                        Text("Decimals")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        
                        Text("0 – \(token.metadata.decimals?.string ?? "")")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(maxWidth: .infinity)
                            .frame(height: 1)
                            .background(.white.opacity(0.1))
                        
                        Text("Contract index, subindex")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        
                        Text("\(token.contractAddress.index), \(token.contractAddress.subindex)")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .padding(16)
                .background(.grey3.opacity(0.3))
                .cornerRadius(12)
                
                if token.name != "ccd" && isAddTokenDetails {
                    HStack(spacing: 8) {
                        Image("notebook")
                        Text("Show raw metadata")
                            .font(.satoshi(size: 15, weight: .medium))
                            .foregroundStyle(.whiteMain)
                    }
                    .onTapGesture {
                        showRawMd = true
                    }
                }
                if isAddTokenDetails {
                    Spacer()
                }
            }
            .padding(.top, isAddTokenDetails ? 20 : 0)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
