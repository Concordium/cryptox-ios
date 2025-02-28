//
//  OpenPoolView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 18.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct OpenPoolView: View {
    @ObservedObject var viewModel: ValidatorPoolSettingsViewModel
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("baking.openfordelegators".localized)
                        .font(.satoshi(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    CustomToggle(isOn: $viewModel.isOpened)
                }
                Text("validator.opening.pool.desc".localized)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish2)
            }
            .padding(16)
            .background(.grey3.opacity(0.3))
            .cornerRadius(12)
            Spacer()
            RoundedButton(action: {
                viewModel.pressedContinue()
            }, title: "continue_btn_title".localized)
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
}
