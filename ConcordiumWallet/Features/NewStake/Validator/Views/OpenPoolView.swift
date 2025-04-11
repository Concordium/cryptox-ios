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
        HStack(spacing: 0) {
            pickerOption(
                title: ValidatorPoolSetting.open.getDisplayValue(),
                index: 0,
                isFirst: true,
                isLast: viewModel.showsCloseForNew == false
            )

            if viewModel.showsCloseForNew {
                pickerOption(
                    title: ValidatorPoolSetting.closedForNew.getDisplayValue(),
                    index: 1,
                    isFirst: false,
                    isLast: true
                )
            } else {
                pickerOption(
                    title: ValidatorPoolSetting.closed.getDisplayValue(),
                    index: 2,
                    isFirst: false,
                    isLast: true
                )
            }
        }
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.grey4, lineWidth: 1)
        )
        .cornerRadius(12)
        .animation(.smooth(duration: 0.7), value: selectedIndex)
    }

    @ViewBuilder
    private func pickerOption(title: String, index: Int, isFirst: Bool, isLast: Bool) -> some View {
        Button(action: {
            withAnimation(.smooth(duration: 0.7)) {
                selectedIndex = index
            }
        }) {
            Text(title)
                .font(.satoshi(size: 15, weight: .medium))
                .foregroundColor(selectedIndex == index ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedIndex == index ? Color.white : Color.clear)
                .clipShape(RoundedCornerShape(isFirst: isFirst, isLast: isLast, radius: 0))
        }
    }
}

// Custom Shape for Rounded Corners
struct RoundedCornerShape: Shape {
    var isFirst: Bool
    var isLast: Bool
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isFirst {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius), style: .continuous)
        } else if isLast {
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius), style: .continuous)
        } else {
            path.addRect(rect)
        }

        return path
    }
}

#Preview(body: {
    PoolSettingsSelector(selectedIndex: .constant(0), viewModel: ValidatorPoolSettingsViewModel(dataHandler: BakerDataHandler(account: AccountEntity(), action: .register), navigationManager: NavigationManager()))
})
