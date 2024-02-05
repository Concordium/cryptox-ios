//
//  RecoveryPhraseSetupCompleteView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 27/07/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct RecoveryPhraseSetupCompleteView: Page {
    @ObservedObject var viewModel: RecoveryPhraseSetupCompleteViewModel
    
    var pageBody: some View {
        VStack(spacing: 20) {
            PageIndicator(numberOfPages: 4, currentPage: 2)
                .padding([.top, .bottom], 10)
            
            HStack(spacing: 12) {
                Image("ico_successfully").offset(y: -24)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("yay".localized)
                        .font(Font.system(size: 19, weight: .medium))
                        .foregroundColor(.white)
                    Text(viewModel.title)
                        .font(Font.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(24)
            
            Spacer()
            Button(viewModel.continueLabel) {
                viewModel.send(.finish)
            }
            .applyCapsuleButtonStyle()
        }
        .padding(20)
        .modifier(AppBackgroundModifier())
    }
}

struct RecoveryPhraseSetupCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseSetupCompleteView(
            viewModel: .init(
                title: "Your secret recovery phrase has been successfully setup!",
                continueLabel: "Continue"
            )
        )
    }
}
