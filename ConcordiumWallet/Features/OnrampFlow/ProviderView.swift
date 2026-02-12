//
//  ProviderView.swift
//  CryptoX
//
//  Created by Max on 08.07.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ProviderView: View {
    let provider: CCDOnrampViewDataProvider.DataProvider
    
    var body: some View {
        HStack(spacing: 12) {
            if provider.logoSource == .remote, let url = URL(string: provider.icon) {
                AsyncImage(url: url, scale: 1.0) { image in
                    image
                        .resizable()
                        .clipShape(Circle())
                } placeholder: {
                    Color.gray.opacity(0.4).clipShape(Circle())
                }
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
            } else {
                Image(provider.icon)
                    .resizable()
                    .clipShape(Circle())
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
            }
            Text(provider.title)
            Spacer()
            Image("ico_side_arrow")
        }
    }
}

#Preview {
    ProviderView(provider: CCDOnrampViewDataProvider.testnet)
}
