//
//  CCDOnrampView.swift
//  CryptoX
//
//  Created by Max on 08.07.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct CCDOnrampView: View {
    var body: some View {
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
                            Link(destination: provider.url) {
                                ProviderView(provider: provider)
                                    .frame(maxWidth: .infinity)
                                    .overlay(alignment: .trailing) {
                                        if provider.isPaymentProvider {
                                            Image(systemName: "creditcard")
                                                .tint(.white)
                                                .padding(.trailing, 32)
                                        }
                                    }
                            }
                            .listRowBackground(Color.clear)
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
                    .padding(.top, 64)
                    .padding(.bottom, 32)
                    .padding(.horizontal, 54)
                    .id("footer")
            }
            .modifier(AppBackgroundModifier())
            .listSectionSeparator(.hidden)
            .listStyle(.plain)
        })
    }
    
    private func ListHeader() -> some View {
        VStack(spacing: 8) {
            Text("ccd_onramp_list_header_title".localized)
                .font(.satoshi(size: 24, weight: .medium))
                .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.94))
            VStack(spacing: 2) {
                Text("ccd_onramp_list_header_subtitle".localized)
                    .multilineTextAlignment(.center)
                Text("ccd_onramp_list_header_subtitle_more".localized)
                    .underline()
            }
            .font(.satoshi(size: 14, weight: .regular))
            .foregroundColor(Color(red: 0.8, green: 0.84, blue: 0.84))
        }
        .padding(.top, 32)
        .padding(.horizontal, 48)
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

#Preview {
    CCDOnrampView()
}
