//
//  RecoveryPhraseOnboardingView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 01/07/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct RecoveryPhraseOnboardingView: Page {
    @ObservedObject var viewModel: RecoveryPhraseOnboardingViewModel
    
    var pageBody: some View {
        VStack(spacing: 20) {
            PageIndicator(numberOfPages: 4, currentPage: 1)

            VStack(alignment: .leading, spacing: 10) {
                StyledLabel(text: viewModel.message, style: .body, textAlignment: .leading)
            }
            .padding(20)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(24)
            
            Spacer()
            
            Button(viewModel.continueLabel) {
                self.viewModel.send(.continueTapped)
            }.applyCapsuleButtonStyle()
        }
        .padding(.init(top: 18, leading: 18, bottom: 18, trailing: 18))
        .modifier(AppBackgroundModifier())
    }
}

struct RecoveryPhraseOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseOnboardingView(viewModel: .init(
            message: "Some very long message",
            continueLabel: "Continue"
        ))
    }
}
