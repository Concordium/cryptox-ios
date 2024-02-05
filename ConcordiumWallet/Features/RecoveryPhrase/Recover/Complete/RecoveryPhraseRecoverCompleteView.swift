//
//  RecoveryPhraseRecoverCompleteView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 01/08/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct RecoveryPhraseRecoverCompleteView: Page {
    @ObservedObject var viewModel: RecoveryPhraseRecoverCompleteViewModel
    
    var pageBody: some View {
        VStack {
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
            }.applyCapsuleButtonStyle()
        }
        .padding(.init(top: 10, leading: 16, bottom: 30, trailing: 16))
        .modifier(AppBackgroundModifier())    }
}

struct RecoveryPhraseRecoverCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseRecoverCompleteView(
            viewModel: .init(
                title: "Your secret recovery phrase has been successfully entered! Tap continue to recover your accounts and identities.",
                continueLabel: "Continue"
            )
        )
    }
}
