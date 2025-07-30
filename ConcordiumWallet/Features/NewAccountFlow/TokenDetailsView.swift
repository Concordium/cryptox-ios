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
    @State private var showRawMdTapped = false
    
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
                        separator

                        Text("Decimals")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        
                        Text("0 – 6")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        
                    case .token(let cis2Token, _):
                        titleSection(token: token)
                        Text("Description")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        descriptionSection(decimals: cis2Token.metadata.decimals ?? 0, decription: cis2Token.metadata.description ?? "")
                        separator
                        
                        Text("Contract index, subindex")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        
                        Text("\(cis2Token.contractAddress.index), \(cis2Token.contractAddress.subindex)")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    case .plt(let pltToken, _):
                        titleSection(token: token)
                        PLTTokenTags(viewModel: PLTTokenTagViewModel(allowList: pltToken.token.tokenState.moduleState.allowList, denyList: pltToken.token.tokenState.moduleState.denyList))
                            .padding(.bottom, 4)
                        descriptionSection(decimals: pltToken.tokenAccountState.balance.decimals, decription: pltToken.token.tokenState.moduleState.metadata.url)
                    }
                }
                .padding(16)
                .background(.grey3.opacity(0.3))
                .cornerRadius(12)
                
                if token.name != "ccd" && !isAddTokenDetails {
                    HStack(spacing: 8) {
                        Image("notebook")
                            .renderingMode(.template)
                            .foregroundStyle(showRawMdTapped ? .buttonPressed : .whiteMain)
                        Text("Show raw metadata")
                            .font(.satoshi(size: 15, weight: .medium))
                            .foregroundStyle(showRawMdTapped ? .buttonPressed : .whiteMain)
                    }
                    .onTapGesture {
                        showRawMdTapped = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showRawMdTapped = false
                            showRawMd = true
                        }
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
    
    @ViewBuilder
    func titleSection(token: AccountDetailAccount) -> some View {
        HStack(spacing: 8) {
            if let cis2Token = token.cis2Token, let url = cis2Token.metadata.thumbnail?.url {
                CryptoImage(url: url.toURL, size: .custom(width: 20, height: 20))
                    .aspectRatio(contentMode: .fit)
                Text(cis2Token.metadata.name ?? "")
                    .font(.satoshi(size: 16, weight: .semibold))
                    .foregroundStyle(.whiteMain)
            } else if let pltToken = token.pltToken {
                Image("placeholder-crypto-token")
                    .resizable()
                    .clipShape(Circle())
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text(pltToken.token.tokenState.moduleState.name)
                    .font(.satoshi(size: 16, weight: .semibold))
                    .foregroundStyle(.whiteMain)
            }
        }
    }
    
    @ViewBuilder
    func descriptionSection(decimals: Int, decription: String) -> some View {
        Group {
            Text("Description")
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
            Text(decription)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(.whiteMain)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            separator
            
            Text("Decimals")
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
            
            Text("0 – \(decimals)")
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(.whiteMain)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    @ViewBuilder
    private var separator: some View {
        Rectangle()
            .foregroundColor(.clear)
            .frame(maxWidth: .infinity)
            .frame(height: 1)
            .background(.white.opacity(0.1))
    }
}
