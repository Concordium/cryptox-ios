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
                }
                PoolSettingsSelector(selectedIndex: $viewModel.selectedPoolSettingIndex, viewModel: viewModel)
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

struct PoolSettingsSelector: View {
    @Binding var selectedIndex: Int
    @ObservedObject var viewModel: ValidatorPoolSettingsViewModel

    var body: some View {
        Picker("", selection: $selectedIndex) {
            if viewModel.showsCloseForNew {
                Text(BakerPoolSetting.open.getDisplayValue()).tag(0)
                    .font(.satoshi(size: 12, weight: .regular))
                Text(BakerPoolSetting.closedForNew.getDisplayValue()).tag(1)
                    .font(.satoshi(size: 12, weight: .regular))
            } else {
                Text(BakerPoolSetting.open.getDisplayValue()).tag(0)
                    .font(.satoshi(size: 12, weight: .regular))
                Text(BakerPoolSetting.closed.getDisplayValue()).tag(2)
                    .font(.satoshi(size: 12, weight: .regular))
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
