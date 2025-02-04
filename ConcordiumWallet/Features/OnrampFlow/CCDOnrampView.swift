//
//  CCDOnrampView.swift
//  CryptoX
//
//  Created by Max on 08.07.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct CCDOnrampView: View {
    @SwiftUI.Environment(\.openURL) var openURL
    
    let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    
    @State var isAccountsPickerShown: CCDOnrampViewDataProvider.DataProvider?
    
    var body: some View {
        NavigationView {
            ScrollViewReader(content: { proxy in
                List {
                    ListHeader()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            proxy.scrollTo("footer")
                        }
                    
                    ForEach(CCDOnrampViewDataProvider.sections) { section in
                        Section {
                            ForEach(section.providers) { provider in
                                ProviderView(provider: provider)
                                    .frame(maxWidth: .infinity)
                                    .overlay(alignment: .trailing) {
                                        if provider.isPaymentProvider {
                                            Image(systemName: "creditcard")
                                                .tint(.white)
                                                .padding(.trailing, 32)
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                    .contentShape(.rect)
                                    .onTapGesture {
                                        let accounts = dependencyProvider.storageManager().getAccounts()
                                        if accounts.count > 1 {
                                            isAccountsPickerShown = provider
                                        } else {
                                            UIPasteboard.general.string = accounts.first?.address
                                            let url = provider.title == "Swipelux" ? CCDOnrampViewDataProvider.generateSwipeluxURL(baseURL: provider.url, targetAddress: accounts.first?.address) : provider.url
                                            openURL(url)
                                        }
                                    }
                                    .listRowSeparator(.hidden)
                            }
                        } header: {
                            Text(section.title)
                                .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                                .font(.satoshi(size: 12, weight: .regular))
                        }
                    }
                    
                    ListFooter()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.top, 40)
                        .padding(.bottom, 32)
                        .padding(.horizontal, 32)
                        .id("footer")
                }
                .listSectionSeparator(.hidden)
                .listStyle(.grouped)
                .scrollContentBackground(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .modifier(AppBackgroundModifier())
            })
        }
        .sheet(item: $isAccountsPickerShown, content: { provider in
            OnrampAccountPicker(
                accountModels: dependencyProvider.storageManager().getAccounts().map { AccountPreviewViewModel.init(account: $0, tokens: dependencyProvider.storageManager().getAccountSavedCIS2Tokens($0.address)) },
                provider: provider)
        })
        .onAppear {
            Tracker.track(view: ["CCD Onramp"])
        }
    }
    
    private func ListHeader() -> some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text("ccd_onramp_list_header_subtitle".localized)
                    .multilineTextAlignment(.center)
                Text("ccd_onramp_list_header_subtitle_more".localized)
                    .underline()
            }
            .font(.satoshi(size: 14, weight: .regular))
            .foregroundColor(Color.MineralBlue.blueish3)
        }
        .padding(.top, 20)
        .padding(.horizontal, 30)
    }
    
    private func ListFooter() -> some View {
        VStack(spacing: 8) {
            Text("ccd_onramp_list_footer_title".localized)
                .font(.satoshi(size: 24, weight: .medium))
                .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.94))
            Text("ccd_onramp_list_footer_subtitle".localized)
                .multilineTextAlignment(.leading)
                .font(.satoshi(size: 14, weight: .regular))
                .foregroundColor(Color(red: 0.8, green: 0.84, blue: 0.84))
        }
    }
}
