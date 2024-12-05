//
//  RecoveryPhraseCopyPhraseView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 29/06/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct RecoveryPhraseCopyPhraseView: Page {
    @ObservedObject var viewModel: RecoveryPhraseCopyPhraseViewModel
    
    private var validationBoxEnabled: Bool {
        switch viewModel.recoveryPhrase {
        case .hidden:
            return false
        case .shown:
            return true
        }
    }
    
    var pageBody: some View {
        VStack(spacing: 20) {
            PageIndicator(numberOfPages: 4, currentPage: 1)
            
            if viewModel.recoveryPhrase.areWordsShown {
                List {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.title)
                            .font(Font.satoshi(size: 19, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.leading)
                            .modifier(GrayRoundedBackgroundModifier())
                        
                        WordContainer(state: viewModel.recoveryPhrase)
                        Spacer()
                        ValidationBox(
                            title: viewModel.copyValidationTitle,
                            isChecked: viewModel.hasCopiedPhrase,
                            enabled: validationBoxEnabled
                        ) {  self.viewModel.send(.confirmBoxTapped)}
                        .padding([.leading, .trailing], 25)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .listStyle(.plain)
                .listSectionSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            } else {
                VStack(spacing: 20) {
                    Text(viewModel.recoveryPhrase.hiddenMessage)
                      .font(Font.satoshi(size: 19, weight: .medium))
                      .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                    Button("Reveal") {
                        withAnimation {
                            self.viewModel.send(.showPhrase)
                        }
                    }
                    .applyCapsuleButtonStyle()
                }
                .padding(20)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .cornerRadius(24)
            }
            
            Spacer()
            Button(viewModel.buttonTitle) {
                self.viewModel.send(.continueTapped)
            }
            .applyCapsuleButtonStyle(disabled: !viewModel.hasCopiedPhrase)
        }
        .padding(18)
        .modifier(AppBackgroundModifier())
    }
}


    /// we have grids for this type of layout
private struct WordContainer: View {
    let state: RecoveryPhraseState
    
    var body: some View {
        HStack(spacing: 19) {
            VStack(spacing: 4) {
                ForEach(0..<12) { index in
                    WordPill(index: index, word: state.word(for: index))
                        .ignoreAnimations()
                }.opacity(state.areWordsShown ? 1 : 0)
            }.frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                ForEach(12..<24) { index in
                    WordPill(index: index, word: state.word(for: index))
                        .ignoreAnimations()
                }.opacity(state.areWordsShown ? 1 : 0)
            }.frame(maxWidth: .infinity)
        }
    }
}

private extension RecoveryPhraseState {
    var areWordsShown: Bool {
        if case .shown = self {
            return true
        } else {
            return false
        }
    }
    
    var hiddenMessage: String {
        if case let .hidden(message) = self {
            return message
        } else {
            return ""
        }
    }
    
    func word(for index: Int) -> String {
        if case let .shown(words) = self {
            return String(words[words.startIndex.advanced(by: index)])
        } else {
            return ""
        }
    }
}

private struct WordPill: View {
    let index: Int
    let word: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(index + 1).")
                .font(Font.satoshi(size: 15, weight: .medium))
                .foregroundColor(.greySecondary)
            Text(word)
                .font(Font.satoshi(size: 15, weight: .medium))
                .foregroundColor(.greySecondary)
                .lineLimit(1)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding([.leading, .trailing], 16)
        .padding([.top, .bottom], 6)
        .overlay(
            Capsule()
                .stroke(Color(red: 0.66, green: 0.68, blue: 0.73).opacity(0.2), lineWidth: 1)
        )
    }
}

private struct ValidationBox: View {
    let title: String
    let isChecked: Bool
    let enabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(isChecked ? "checkmark_active" : "checkmark")
                    .resizable()
                    .frame(width: 32, height: 32)
                Text(title)
                    .font(Font.satoshi(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.2)
    }
}

struct RecoveryPhraseCopyPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseCopyPhraseView(
            viewModel: .init(
                title: "Please write all 24 words down in the right order.",
                recoveryPhrase: .hidden(message: "Tap to reveal your secret recovery phrase. Make sure no one else can see it."),
                copyValidationTitle: "I confirm I have written down my 24 word secret recovery phrase.",
                hasCopiedPhrase: false,
                buttonTitle: "Continue"
            )
        )
        
        if let testPhrase = testPhrase {
            RecoveryPhraseCopyPhraseView(
                viewModel: .init(
                    title: "Please write all 24 words down in the right order.",
                    recoveryPhrase: .shown(recoveryPhrase: testPhrase),
                    copyValidationTitle: "I confirm I have written down my 24 word secret recovery phrase.",
                    hasCopiedPhrase: true,
                    buttonTitle: "Continue"
                )
            ).previewDevice(.init(rawValue: "iPhone SE (3rd generation)"))
        }
    }
    
    private static let testPhrase = try? RecoveryPhrase(phrase: [
        "clay", "vehicle", "crane", "debris", "usual", "canal",
        "puzzle", "concert", "asset", "render", "post", "cherry",
        "voyage", "original", "enrich", "gain", "basket", "dust",
        "version", "become", "desk", "oxygen", "doctor", "idea"
    ].joined(separator: " "))
}
