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
    @State private var isTokenDescPopupVisible: Bool = false
    @StateObject private var pltTokenTagVM: TokenTagViewModel

    var onTagInfoTapped: ((String, String) -> Void)? = nil
    
    init(token: AccountDetailAccount,
         isAddTokenDetails: Bool = false,
         showRawMd: Binding<Bool>,
         onTagInfoTapped: ((String, String) -> Void)? = nil) {
        self.token = token
        self.isAddTokenDetails = isAddTokenDetails
        self._showRawMd = showRawMd
        self.onTagInfoTapped = onTagInfoTapped
        
        if case .plt(let pltToken, _, _) = token {
            _pltTokenTagVM = StateObject(
                wrappedValue: TokenTagViewModel(
                    allowList: pltToken.tokenAccountState.state.allowList,
                    denyList:  pltToken.tokenAccountState.state.denyList,
                    paused:    pltToken.token.tokenState.moduleState.paused,
                    cis2Token: nil
                )
            )
        } else if case .token(let token, let amount) = token {
            _pltTokenTagVM = StateObject(
                wrappedValue: TokenTagViewModel(allowList: nil, denyList: nil, paused: nil, cis2Token: true)
            )
        } else {
            _pltTokenTagVM = StateObject(
                wrappedValue: TokenTagViewModel(allowList: nil, denyList: nil, paused: nil, cis2Token: nil)
            )
        }
    }
    
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
                        TokenTags(viewModel: pltTokenTagVM,
                                  cis2Tag: true,
                                  onInfoTapped: { title, desc in
                            onTagInfoTapped?(title, desc)
                        })
                            .padding(.bottom, 4)
                        descriptionSection(decimals: cis2Token.metadata.decimals ?? 0, description: cis2Token.metadata.description ?? "")
                        separator
                        
                        Text("Contract index, subindex")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        
                        Text("\(cis2Token.contractAddress.index), \(cis2Token.contractAddress.subindex)")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(.whiteMain)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    case .plt(let pltToken, _, let md):
                        titleSection(token: token)
                        TokenTags(viewModel: pltTokenTagVM,
                                  cis2Tag: false,
                                  onInfoTapped: { title, desc in
                            onTagInfoTapped?(title, desc)
                        })
                            .padding(.bottom, 4)
                        descriptionSection(decimals: pltToken.token.tokenState.decimals, description: md?.description ?? "")
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
            } else if case let .plt(token, _, metadata) = token {
                if let url = metadata?.thumbnail?.url.toURL {
                    CryptoImage(url: url, size: .custom(width: 20, height: 20))
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image("placeholder-crypto-token")
                        .resizable()
                        .clipShape(Circle())
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                Text(token.token.tokenState.moduleState.name)
                    .font(.satoshi(size: 16, weight: .semibold))
                    .foregroundStyle(.whiteMain)
            }
        }
    }
    
    @ViewBuilder
    func descriptionSection(decimals: Int, description: String) -> some View {
        Group {
            if !description.isEmpty {
                Text("Description")
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                Text(description)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(.whiteMain)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                separator
            }
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
