//
//  ImportSeedPhraseBackupFileView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.06.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportSeedPhraseBackupFileView: View {
    @ObservedObject var viewModel: BackupFileViewModel
    @State var isShowPasscodeViewShown: Bool = false
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                Text("import.walletPrivateKey.title".localized)
                    .font(.satoshi(size: 24, weight: .medium))
                    .foregroundColor(Color.Neutral.tint1)
                    .multilineTextAlignment(.center)
                Text("import.walletPrivateKey.subtitle".localized)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundColor(Color.Neutral.tint2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            
            List {
                ForEach(viewModel.backupFiles) { file in
                    backupCell(title: file.name)
                        .listRowBackground(Color.clear)
                        .padding(.top, 8)
                        .onTapGesture {
                            viewModel.importAction(url: file.url, pwHash: "")
                        }
                }
            }
            .listStyle(.plain)
            .listRowSeparator(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    @ViewBuilder
    func backupCell(title: String) -> some View {
        HStack(alignment: .center, spacing: 17) {
            Image(systemName: "icloud.and.arrow.down")
                    .resizable()
                    .frame(width: 40, height: 40)
                HStack(spacing: 0) {
                    Text(title)
                        .font(.satoshi(size: 15, weight: .medium))
                }
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(.grey2.opacity(0.3))
        .cornerRadius(12)
    }
}
