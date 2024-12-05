//
//  RecoveryPhraseInputView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 28/07/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct RecoveryPhraseInputView: Page {
    @ObservedObject var viewModel: RecoveryPhraseInputViewModel
    
    @State private var selectedIndex = 0
    
    var pageBody: some View {
        VStack(alignment: .leading) {
            Text(viewModel.title)
                .font(Font.satoshi(size: 19, weight: .medium))
                .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                .frame(maxWidth: .infinity)
                .modifier(GrayRoundedBackgroundModifier())
                .padding(.bottom, 32)

            ErrorLabel(error: viewModel.error).padding(.bottom, 12)

            Button(viewModel.clearAll) {
                viewModel.send(.clearAll)
                selectedIndex = 0
            }
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.73, green: 0.75, blue: 0.78))
                .padding(.bottom, 16)

            WordSelection(
                selectedWords: viewModel.selectedWords,
                selectedIndex: $selectedIndex,
                suggestions: viewModel.currentSuggestions,
                editable: true,
                currentInput: $viewModel.currentInput,
                action: { word in viewModel.send(.wordSelected(index: selectedIndex, word: word)) }
            )
            Spacer()
        }
        .padding(16)
        .modifier(AppBackgroundModifier())
    }
}

struct RecoverPhraseInputView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseInputView(
            viewModel: .init(
                title: "Enter the correct word for each index.",
                clearAll: "Clear all",
                clearBelow: "Clear below",
                selectedWords: Array(repeating: "", count: 24),
                currentInput: "",
                currentSuggestions: [],
                error: nil
            )
        )
    }
}
