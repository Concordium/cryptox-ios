//
//  EarnView.swift
//  Mock
//
//  Created by Lars Christensen on 21/12/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct EarnView: Page {
    @ObservedObject var viewModel: EarnViewModel
    
    var pageBody: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(spacing: 16) {
                    Text("earn.desc.part1".localized)
                        .font(.satoshi(size: 16, weight: .regular))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color.whiteText)
                    
                    HStack(alignment: .center) {
                        Image("ico_info_green")
                            .frame(width: 24, height: 24)
                        
                        Text("earn.desc.part2".localized)
                            .font(.satoshi(size: 16, weight: .regular))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color.whiteText)
                            .padding()
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .background(Color(red: 0.27, green: 0.36, blue: 0.35).opacity(0.5))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .inset(by: 0.5)
                            .stroke(Color.greenSecondary))
                    
                    CardView(title: "earn.desc.baking.header".localized,
                             description: viewModel.bakingText,
                             buttonTitle: "earn.button.baker".localized) {
                        self.viewModel.send(.bakerTapped)
                    }
                    
                    CardView(title: "earn.desc.delegation.header".localized,
                             description: "earn.desc.delegation.text".localized,
                             buttonTitle: "earn.button.delegation".localized) {
                        self.viewModel.send(.delegationTapped)
                    }
                }
                cooldownsSectionView
            }
            .padding(16)
            .onAppear(perform: {
                viewModel.loadMinStake()
            })
        }
        .background(Image("bg_main").resizable().ignoresSafeArea(.all))
    }
    
    @ViewBuilder
    func CardView(title: String, description: String, buttonTitle: String, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.satoshi(size: 16, weight: .heavy))
            Text(description)
                .font(.satoshi(size: 16, weight: .regular))
                .multilineTextAlignment(.leading)
            Button(buttonTitle) {
                onTap()
            }
            .applyStandardButtonStyle()
            .cornerRadius(25)
        }
        .padding()
        .background(Color.greyDark)
        .cornerRadius(20)
    }
    
    private var cooldownsSectionView: some View {
        Group {
            if !viewModel.cooldowns.isEmpty {
                ForEach(viewModel.cooldowns) { cooldown in
                    CooldownCardView(cooldown: cooldown)
                }
            }
        }
    }
}

struct EarnView_Previews: PreviewProvider {
    static var previews: some View {
        EarnView(
            viewModel: .init(account: AccountDataTypeFactory.create())
        )
    }
}
