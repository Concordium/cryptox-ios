//
//  RevealSeedPhraseView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 18.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import MnemonicSwift

final class RevealSeedPhraseViewModel: ObservableObject {
    @Published var mnenonic: [String] = []
    
    private let identitiesService: SeedIdentitiesService
    
    init(identitiesService: SeedIdentitiesService) {
        self.identitiesService = identitiesService
    }
    
    func revealSeedPhrase(_ pwHash: String) {
        Task {
            do {
                let seed = try await identitiesService.mobileWallet.getRecoveryPhrase(pwHash: pwHash).joined(separator: " ")
                await MainActor.run {
                    withAnimation(.bouncy) {
                        self.mnenonic = seed.components(separatedBy: " ")
                    }
                }
            } catch {
                self.mnenonic = []
            }
        }
    }
}

struct RevealSeedPhraseView: View {
    @ObservedObject var viewModel: RevealSeedPhraseViewModel
    
    @SwiftUI.Environment(\.dismiss) var dismiss

    @State var shareText: ShareText?
    @State var isShowPasscodeViewShown: Bool = false
    
    @Namespace private var animation
    
    var body: some View {
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
            
            if viewModel.mnenonic.isEmpty {
                Image("seed_phrase_locked_blur")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .containerShape(.rect)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        isShowPasscodeViewShown.toggle()
                    }
                    .matchedGeometryEffect(id: "LockTransition", in: animation)
            } else {
                MnemonicView()
                    .matchedGeometryEffect(id: "LockTransition", in: animation)
            }
            
            Button {
                if viewModel.mnenonic.isEmpty {
                    isShowPasscodeViewShown.toggle()
                } else {
                    shareText = ShareText(text: viewModel.mnenonic.joined(separator: " "))
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.mnenonic.isEmpty ? "show.seed.phrase".localized : "copy.to.clipoard".localized)
                        .foregroundStyle(Color.Neutral.tint1)
                        .font(.satoshi(size: 14, weight: .medium))
                    Image(viewModel.mnenonic.isEmpty ? "seed_phrase_reveal" : "seed_phrase_copy")
                }
            }
            .padding(.top, 22)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .modifier(AppBackgroundModifier())
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }, label: {
                Image(systemName: "xmark")
                    .font(.callout)
                    .frame(width: 35, height: 35)
                    .foregroundStyle(Color.primary)
                    .background(.ultraThinMaterial, in: .circle)
                    .contentShape(.circle)
            })
            .padding(.top, 12)
            .padding(.trailing, 15)
        }
        .sheet(item: $shareText) { shareText in
            ActivityView(text: shareText.text)
        }
        .passcodeInput(isPresented: $isShowPasscodeViewShown) { pwHash in
            viewModel.revealSeedPhrase(pwHash)
        }
    }
    
    @ViewBuilder
    func MnemonicView() -> some View {
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
            }
            .padding(8)
        }
        .frame(minHeight: 170)
        .frame(maxWidth: .infinity)
        .background(Color.Neutral.tint6)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
        )
    }
}
