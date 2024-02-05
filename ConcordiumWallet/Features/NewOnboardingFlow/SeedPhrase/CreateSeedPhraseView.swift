//
//  SeedPhraseView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 22.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import MnemonicSwift

final class CreateSeedPhraseViewModel: ObservableObject {
    var mnenonic: [String]
    var pwHash: String
    
    private let identitiesService: SeedIdentitiesService
    
    init(pwHash: String, identitiesService: SeedIdentitiesService) {
        self.identitiesService = identitiesService
        self.mnenonic = []
        self.pwHash = pwHash
        
        generateMnemonic()
    }
    
    
    func generateMnemonic() {
        do {
            self.mnenonic = try Mnemonic.generateMnemonic(strength: 24 / 3 * 32).components(separatedBy: " ")
        } catch { }
    }
    
    func savePhrase() async throws -> Seed {
        try identitiesService.storePhrase(words: mnenonic, pwHash: pwHash)
    }
}

struct CreateSeedPhraseView: View {
    @StateObject var viewModel: CreateSeedPhraseViewModel
    
    var onConfirmed: ([String]) -> Void
    
    @State var shareText: ShareText?
    @State var isChecked: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {                
                VStack(spacing: 8) {
                    Text("seed_phrase_title".localized)
                        .font(.satoshi(size: 24, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint1)
                    Text("seed_phrase_subtitle".localized)
                        .font(.satoshi(size: 14, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint2)
                        .multilineTextAlignment(.center)
                }
                    .padding(.top, 64)
                
                HStack {
                    HStack(spacing: 4) {
                        Image("seed_green_check")
                        Text("transcribe".localized)
                            .font(.satoshi(size: 12, weight: .regular))
                            .foregroundStyle(Color.Neutral.tint1)
                    }
                    HStack(spacing: 4) {
                        Image("seed_red_check")
                        Text("digital_copy".localized)
                            .font(.satoshi(size: 12, weight: .regular))
                            .foregroundStyle(Color.Neutral.tint1)
                    }
                    HStack(spacing: 4) {
                        Image("seed_red_check")
                        Text("screenshot".localized)
                            .font(.satoshi(size: 12, weight: .regular))
                            .foregroundStyle(Color.Neutral.tint1)
                    }
                }
                
                VStack(alignment: .center) {
                    VStack(spacing: 4) {
                        ForEach(Array(viewModel.mnenonic).chunks(4), id: \.self) { row in
                            HStack(alignment: .center, spacing: 4) {
                                ForEach(row, id: \.self) { word in
                                    SeedPhrasePillView(
                                        word: word,
                                        idx: viewModel.mnenonic.firstIndex(of: word).if({ $0 + 1 })
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }.padding(8)
                }
                .background(Color.Neutral.tint6)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
                )
                .padding(.vertical, 16)
                
                Button {
                    shareText = ShareText(text: viewModel.mnenonic.joined(separator: " "))
                } label: {
                    HStack(spacing: 8) {
                        Text("copy.to.clipoard".localized)
                            .foregroundStyle(Color.Neutral.tint1)
                            .font(.satoshi(size: 14, weight: .medium))
                        Image("seed_phrase_copy")
                    }
                }
                .padding(.top, 22)
                
                Spacer()
                
                
                VStack(spacing: 24) {
                    HStack(spacing: 16) {
                        Image(isChecked ? "checkbox_checked" : "checkbox_unchecked")
                            .contentShape(.rect)
                            .onTapGesture {
                                isChecked.toggle()
                            }
                        Text("seed_phrase_confirm_save".localized)
                            .font(.satoshi(size: 14, weight: .regular))
                            .foregroundStyle(Color.Neutral.tint1)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    Button(action: {
                        Task {
                            do {
                                let seed = try await viewModel.savePhrase()
                                DispatchQueue.main.async {
                                    self.onConfirmed(viewModel.mnenonic)
                                }
                            }
                        }
                    }, label: {
                        HStack {
                            Text("continue_btn_title".localized)
                                .font(Font.satoshi(size: 16, weight: .medium))
                                .lineSpacing(24)
                                .foregroundColor(Color.Neutral.tint7)
                            Spacer()
                            Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                        }
                        .padding(.horizontal, 24)
                    })
                    .opacity(isChecked ? 1.0 : 0.7)
                    .disabled(!isChecked)
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28, corners: .allCorners)
                }
            }
            .padding(.horizontal, 16)
        }
        .modifier(AppBackgroundModifier())
        .sheet(item: $shareText) { shareText in
            ActivityView(text: shareText.text)
        }
    }
}
