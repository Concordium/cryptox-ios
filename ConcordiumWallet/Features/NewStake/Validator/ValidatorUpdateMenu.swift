//
//  ValidatorUpdateMenu.swift
//  CryptoX
//
//  Created by Zhanna Komar on 05.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ValidatorUpdateMenu: View {
    @ObservedObject var viewModel: ValidatorUpdateMenuViewModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            RoundedButton(action: {
                viewModel.updateStake()
            }, title: "baking.menu.updatebakerstake".localized)
            
            RoundedButton(action: {
                viewModel.updatePoolSettings()
            }, title: "baking.menu.updatepoolsettings".localized)
            
            RoundedButton(action: {
                viewModel.updateBakerKeys()
            }, title: "baking.menu.updatebakerkeys".localized)
            
            Button(action: {
                
            }, label: {
                Text("baking.menu.stopbaking".localized)
                    .font(Font.satoshi(size: 15, weight: .bold))
                    .foregroundColor(.attentionRed)
                    .padding(.vertical, 18.5)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white, lineWidth: 1)
                    )
            })
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
}
