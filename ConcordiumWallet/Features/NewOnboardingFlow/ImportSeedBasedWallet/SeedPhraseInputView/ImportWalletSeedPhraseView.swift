//
//  ImportWalletSeedPhraseView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 11.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

final class ImportWalletSeedPhraseViewModel: ObservableObject {
    let onValidPhrase: (RecoveryPhrase) -> Void
    
    @Published var selectedIndex: Int = 0
    @Published var selectedWords: [String] = Array(repeating: "", count: 24)
    @Published var currentInput: String = ""
    @Published var currentSuggestions: [String] = []
    @Published var error: String? = nil
    
    @Published var isValidPhrase: Bool = false
    
    private let recoveryService: RecoveryPhraseServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(recoveryService: RecoveryPhraseServiceProtocol, onValidPhrase: @escaping (RecoveryPhrase) -> Void) {
        self.recoveryService = recoveryService
        self.onValidPhrase = onValidPhrase
        
        $currentInput.sink { [weak self] word in
            guard let self = self else { return }
            if word.count > 1 {
                self.currentSuggestions = recoveryService.suggestions(for: word)
            } else {
                self.currentSuggestions = []
            }
        }.store(in: &cancellables)
    }
    
    func clearAll() {
        selectedWords = Array(repeating: "", count: 24)
        currentSuggestions = []
        isValidPhrase = false
    }
    
    func wordSelected(word: String) {
        selectedWords[selectedIndex] = word
        if selectedWords.allSatisfy({ !$0.isEmpty }) {
            switch recoveryService.validate(recoveryPhrase: selectedWords) {
            case .success:
                isValidPhrase = true
                error = nil
            case .failure:
                error = "recoveryphrase.recover.input.validationerror".localized
                isValidPhrase = false
            }
        }
    }
    
    func importAction() {
        if selectedWords.allSatisfy({ !$0.isEmpty }) {
            switch recoveryService.validate(recoveryPhrase: selectedWords) {
            case let .success(recoveryPhrase):
                    self.onValidPhrase(recoveryPhrase)
            case .failure:
                error = "recoveryphrase.recover.input.validationerror".localized
            }
        }
    }
}

struct ImportWalletSeedPhraseView: View {
    @StateObject var viewModel: ImportWalletSeedPhraseViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 12) {
                Text("import_wallet_seed_phrase_title".localized)
                    .font(.satoshi(size: 24, weight: .medium))
                    .foregroundColor(Color.Neutral.tint1)
                    .multilineTextAlignment(.center)
                Text("import_wallet_seed_phrase_subtitle".localized)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundColor(Color.Neutral.tint2)
                    .multilineTextAlignment(.center)
                    
            }.frame(maxWidth: .infinity)

            ErrorLabel(error: viewModel.error).padding(.bottom, 12)


            SeedPhraseInput(
                selectedWords: $viewModel.selectedWords,
                selectedIndex: $viewModel.selectedIndex,
                suggestions: viewModel.currentSuggestions,
                editable: true,
                currentInput: $viewModel.currentInput,
                action: { word in viewModel.wordSelected(word: word) }
            )
            .overlay(alignment: .bottomLeading) {
                Button("recoveryphrase.recover.input.clearall".localized) {
                    viewModel.clearAll()
                    viewModel.selectedIndex = 0
                }
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.73, green: 0.75, blue: 0.78))
                .offset(y: 28)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.importAction()
            }, label: {
                HStack {
                    Text("recover_accounts_recover_button_title".localized)
                        .font(Font.satoshi(size: 16, weight: .medium))
                        .lineSpacing(24)
                        .foregroundColor(Color.Neutral.tint7)
                    Spacer()
                    Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                }
                .padding(.horizontal, 24)
            })
            .disabled(!viewModel.isValidPhrase)
            .frame(height: 56)
            .background(Color.EggShell.tint1)
            .cornerRadius(28, corners: .allCorners)
            .opacity(viewModel.isValidPhrase ? 1.0 : 0)
            .animation(.easeInOut, value: viewModel.isValidPhrase)
        }
        .padding(16)
        .navigationBarBackButtonHidden(true)
        .modifier(AppBackgroundModifier())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(Color.Neutral.tint1)
                        .frame(width: 35, height: 35)
                        .contentShape(.circle)
                }
            }
        }
    }
}
