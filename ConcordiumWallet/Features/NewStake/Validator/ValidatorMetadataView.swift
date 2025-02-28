//
//  ValidatorMetadataView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 19.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ValidatorMetadataView: View {
    @FocusState var isFieldFocused: Bool
    @ObservedObject var viewModel: ValidatorMetadataViewModel
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        VStack(alignment:.leading, spacing: 24) {
            Text("validator.metadata.desc".localized)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish2)
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("validator.enter.md.url".localized)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish3)
                        .opacity(0.5)
                        .multilineTextAlignment(.leading)
                    TextField("", text: $viewModel.currentMetadataUrl)
                        .foregroundColor(.white)
                        .focused($isFieldFocused)
                        .tint(.white)
                        .font(.system(size: 16))
                }
                if !viewModel.currentMetadataUrl.isEmpty {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.MineralBlue.blueish3)
                        .frame(width: 18, height: 18)
                        .onTapGesture {
                            withAnimation {
                                viewModel.currentMetadataUrl = ""
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFieldFocused ? Color.MineralBlue.blueish3 : Color.grey3, lineWidth: 1)
                    .background(.clear)
                    .cornerRadius(12)
            )
            
            Spacer()
            
            RoundedButton(action: {
                viewModel.pressedContinue {
                    self.navigationManager.navigate(to: .generateKey(
                        ValidatorGenerateKeysViewModel(dataHandler: viewModel.dataHandler,
                                                                       account: viewModel.dataHandler.account,
                                                       dependencyProvider: ServicesProvider.defaultProvider())))

                }
            }, title: "continue_btn_title".localized)
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
}
