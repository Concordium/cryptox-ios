//
//  ValidatorGenerateKeysView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ValidatorGenerateKeysView: View {
    @State private var exportPressed: Bool = false
    @ObservedObject var viewModel: ValidatorGenerateKeysViewModel
    @EnvironmentObject private var navigationManager: NavigationManager
    var pressedButtonColor: Color {
        exportPressed ? Color.buttonPressed : .white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("validator.validator.keys.desc".localized)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish2)
            
            VStack(alignment: .leading, spacing: 6) {
                keySection(title: viewModel.electionKeyTitle, key: viewModel.electionKeyContent)
                Divider()
                keySection(title: viewModel.signatureKeyTitle, key: viewModel.signatureKeyContent)
                Divider()
                keySection(title: viewModel.aggregationKeyTitle.localized, key: viewModel.aggregationKeyContent)
            }
            .padding([.leading, .top], 14)
            .padding(.trailing, 26)
            .padding(.bottom, 18)
            .background(.grey3.opacity(0.3))
            .cornerRadius(12)

            Spacer()
            
            RoundedButton(action: {
                exportPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    exportPressed = false
                    viewModel.handleExport()
                }
            },
                          title: "continue_btn_title".localized)
        }
        .sheet(isPresented: $viewModel.showShareSheet, content: {
            if let fileToShare = viewModel.fileToShare {
                ShareSheetView(fileURL: fileToShare) { completed in
                    viewModel.handleExportEnded(completed: completed) {
                        navigationManager.navigate(to: .validatorRequestConfirmation(ValidatorSubmissionViewModel(dataHandler: viewModel.dataHandler, dependencyProvider: ServicesProvider.defaultProvider())))
                    }
                }
            }
        })
        .onAppear {
            viewModel.showAlert = true
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
        .modifier(AlertModifier(alertOptions: viewModel.alertOptionsForKeys, isPresenting: $viewModel.showAlert))
    }
    
    private func keySection(title: String, key: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
            Text(key)
                .font(.satoshi(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .truncationMode(.tail)
                .lineLimit(1)
        }
    }
}
