//
//  NewTokenNotificationPopup.swift
//  CryptoX
//
//  Created by Zhanna Komar on 16.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct NewTokenNotificationPopup: View {
    @Binding var isVisible: Bool
    let userInfo: [AnyHashable: Any]
    let storeTokenAction: () -> Void
    @State private var tokenName: String = ""
    
    var body: some View {
        VStack {
            if isVisible {
                PopupContainer(icon: "",
                               title: "You received a new token",
                               subtitle: "\(tokenName) has not been listed in your wallet till this transaction.\nYou can accept it or remove it from the list.",
                               content: addNewToken()) {
                    isVisible = false
                }
            }
        }
        .task {
            tokenName = await getTokenName()
        }
    }
    
    private func addNewToken() -> some View {
        VStack {
            Button {
                isVisible = false
                storeTokenAction()
            } label: {
                Text("Keep it")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .cornerRadius(21)
            }

            Button {
                isVisible = false
            } label: {
                Text("Remove from the wallet")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .background(.clear)
    }
    
    private func getTokenName() async -> String {
        if let tokenMetadata = userInfo["token_metadata"] {
            guard let metadata = await NotificationTokenService().getTokenMetadata(with: tokenMetadata) else {
                return ""
            }
            return metadata.name ?? ""
        }
        return ""
    }

}
