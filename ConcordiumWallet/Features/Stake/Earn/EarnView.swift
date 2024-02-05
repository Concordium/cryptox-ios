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
        VStack(alignment: .leading, spacing: 16) {
            Text("earn.desc.part1".localized)
                .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                .font(.system(size: 15, weight: .medium))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "info")
                    .frame(width: 18, height: 18)
                    .background(Color(red: 0.08, green: 0.62, blue: 0.5))
                    .clipShape(Circle())

                Text("earn.desc.part2".localized)
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .regular))
            }
                .padding()
                .background(Color(red: 0.08, green: 0.62, blue: 0.5).opacity(0.05))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.08, green: 0.62, blue: 0.5), lineWidth: 1)
                )
            
            
            VStack(alignment: .leading, spacing: 16) {
                Text("earn.desc.baking.header".localized)
                    .foregroundColor(.white)
                    .font(.system(size: 19, weight: .medium))
                Text(viewModel.bakingText)
                    .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                    .font(.system(size: 15, weight: .medium))
                Button("earn.button.baker".localized) {
                    self.viewModel.send(.bakerTapped)
                }
                .applyCapsuleButtonStyle()
            }
            .modifier(GrayRoundedBackgroundModifier())
            
            VStack(alignment: .leading, spacing: 16) {
                Text("earn.desc.delegation.header".localized)
                    .foregroundColor(.white)
                    .font(.system(size: 19, weight: .medium))
                Text("earn.desc.delegation.text".localized)
                    .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                    .font(.system(size: 15, weight: .medium))
                Button("earn.button.delegation".localized) {
                    self.viewModel.send(.delegationTapped)
                }
                .applyCapsuleButtonStyle()
            }
            .modifier(GrayRoundedBackgroundModifier())
            
            Spacer()
        }
        .padding(16)
        .onAppear(perform: {
            viewModel.loadMinStake()
        })
        .modifier(AppBackgroundModifier())
    }
}

struct EarnView_Previews: PreviewProvider {
    static var previews: some View {
        EarnView(
            viewModel: .init(account: AccountDataTypeFactory.create())
        )
    }
}
