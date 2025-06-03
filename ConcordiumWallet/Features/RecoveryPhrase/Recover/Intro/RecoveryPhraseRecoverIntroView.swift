//
//  RecoveryPhraseRecoverIntroView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 28/07/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct RecoveryPhraseRecoverIntroView: Page {
    @ObservedObject var viewModel: RecoveryPhraseRecoverIntroViewModel
    
    var pageBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.title).font(.satoshi(size: 19, weight: .medium))
                .foregroundColor(.white)
                .frame(alignment: .leading)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("recover_wallet_seed_phrase_title".localized)
                    .font(Font.satoshi(size: 19, weight: .medium))
                    .foregroundColor(.white)
                Text("recover_wallet_seed_phrase_body".localized)
                    .font(Font.satoshi(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                Button(viewModel.continueLabel) {
                    viewModel.send(.finish)
                }.applyCapsuleButtonStyle()
            }
            .padding(20)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(24)
            
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("recover_wallet_export_title".localized)
                        .font(Font.satoshi(size: 19, weight: .medium))
                        .foregroundColor(.white)
                        .frame(alignment: .leading)
                    Text("recover_wallet_export_body".localized)
                        .font(Font.satoshi(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                        .frame(alignment: .leading)
                }
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(24)
            
            Spacer()
        }
        .padding(18)
        .modifier(AppBackgroundModifier())
    }
}

struct RecoveryPhraseRecoverIntroView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseRecoverIntroView(
            viewModel: .init(
                title: "How to recover your wallet:",
                body: """
There are two steps to recovering a wallet:

1. Entering your secret recover phrase
2. Recovering your accounts and identities

The first step is manual process, in which you have to enter all your 24 words one by one.

The second step is most often automatic, but in some cases you will have to make some additional inputs. We’ll get back to that.

Let’s get to the secrect recovery phrase!
""",
                continueLabel: "Continue"
            )
        )
    }
}
