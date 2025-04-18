//
//  RecoveryPhraseGettingStartedView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 29/06/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI
import Combine

struct RecoveryPhraseGettingStartedView: Page {
    @ObservedObject var viewModel: RecoveryPhraseGettingStartedViewModel
    
    var pageBody: some View {
        ScrollView {
            VStack {
                Text(viewModel.title)
                    .font(Font.satoshi(size: 25, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 339, alignment: .topLeading)
                GettingStartedSection(section: viewModel.createNewWalletSection, tapAction: {
                    viewModel.send(.createNewWallet)
                }, longPressAction: {
                    viewModel.send(.createNewWalletDemoMode)
                })
                GettingStartedSection(section: viewModel.recoverWalletSection, tapAction: {
                    viewModel.send(.recoverWallet)
                }, longPressAction: {
                    viewModel.send(.recoverWalletDemoMode)
                })
            }
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing], 18)
            .alert(isPresented: $viewModel.demoMode) {
                Alert(title: Text("demomode.title".localized), message: Text("demomode.message".localized), primaryButton: .default(Text("demomode.activate".localized), action: {
                    viewModel.send(.enterDemoMode)
                }), secondaryButton: .cancel(Text("demomode.cancel".localized), action: {
                    viewModel.send(.cancelDemoMode)
                }))
            }
        }
        .modifier(AppBackgroundModifier())
    }
}

private struct GettingStartedSection: View {
    let longPressDuration = 10.0
    
    let section: RecoveryPhraseGettingStartedViewModel.Section
    let tapAction: () -> Void
    let longPressAction: () -> Void
    
    init(
        section: RecoveryPhraseGettingStartedViewModel.Section,
        tapAction: @escaping () -> Void,
        longPressAction: @escaping () -> Void
    ) {
        self.section = section
        self.tapAction = tapAction
        self.longPressAction = longPressAction
    }
    
    @ViewBuilder
    var body: some View {
        VStack {
            HStack {
                StyledLabel(text: section.title, style: .body, weight: .bold, textAlignment: .leading)
                Spacer()
            }.padding([.bottom], 10)
            HStack {
                StyledLabel(text: section.body, style: .body, textAlignment: .leading)
                Spacer()
            }
            Button(section.buttonTitle, action: {})
                .applyCapsuleButtonStyle()
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: longPressDuration)
                        .onEnded { _ in
                            longPressAction()
                        }
                )
                .highPriorityGesture(
                    TapGesture()
                        .onEnded { _ in tapAction() }
                )
        }
        .padding(20)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .cornerRadius(24)
    }
}

struct RecoveryPhraseGettingStartedView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseGettingStartedView(viewModel: .init(
            title: "Are you new to concordium?",
            createNewWalletSection: .init(
                title: "Create new wallet",
                body: "Description of recovery phrase\nOn multiple lines",
                buttonTitle: "Set up fresh wallet"
            ),
            recoverWalletSection: .init(
                title: "Recover wallet",
                body: "Description of recover wallet\nOn multiple lines",
                buttonTitle: "Recover wallet"
            )
        ))
    }
}
