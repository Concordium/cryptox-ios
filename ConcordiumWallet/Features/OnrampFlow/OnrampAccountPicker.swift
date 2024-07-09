//
//  OnrampAccountPicker.swift
//  CryptoX
//
//  Created by Max on 09.07.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct OnrampAccountPicker: View {
    @SwiftUI.Environment(\.openURL) var openURL
    @SwiftUI.Environment(\.dismiss) private var dismiss

    let accountModels: [AccountPreviewViewModel]
    let provider: CCDOnrampViewDataProvider.DataProvider
    
    var body: some View {
        List {
            ListHeader()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.bottom, 48)
            
            ForEach(accountModels) { account in
                Button(action: {
                    UIPasteboard.general.string = account.address
                    openURL(provider.url)
                    dismiss()
                }, label: {
                    AccountView(account)
                        .contentShape(.rect)
                })
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
        }
        .modifier(AppBackgroundModifier())
        .listSectionSeparator(.hidden)
        .listStyle(.plain)
    }
    
    private func ListHeader() -> some View {
        VStack(spacing: 8) {
            Text("ccd_onramp_account_picker_list_header_title".localized)
                .font(.satoshi(size: 24, weight: .medium))
                .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.94))
            Text("ccd_onramp_account_picker_list_header_subtitle".localized)
                .multilineTextAlignment(.center)
            .font(.satoshi(size: 14, weight: .regular))
            .foregroundColor(Color(red: 0.8, green: 0.84, blue: 0.84))
        }
        .padding(.top, 32)
        .padding(.horizontal, 48)
    }
    
    private func AccountView(_ account: AccountPreviewViewModel) -> some View {
        HStack {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(account.accountName)
                        .font(.satoshi(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.94))
                    Spacer()
                    Text(account.totalAmount)
                        .layoutPriority(1)
                        .font(.satoshi(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.94))
                    Text("CCD")
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                }
                HStack {
                    Text(account.accountOwner)
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                    Spacer()
                }
            }
            Spacer()
            Image("ico_side_arrow")
        }
        .padding(8)
    }
}
