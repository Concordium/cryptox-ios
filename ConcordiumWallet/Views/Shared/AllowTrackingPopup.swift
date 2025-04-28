//
//  AllowTrackingPopup.swift
//  CryptoX
//
//  Created by Zhanna Komar on 28.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AllowTrackingPopup: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            PopupContainer(icon: "analytics_icon",
                           title: "allow.tracking.title".localized,
                           subtitle: "allow.tracking.msg".localized,
                           content: buttonsStack()) {
                isVisible = false
            }
        }
    }
    
    private  func buttonsStack() -> some View {
        VStack {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("go.to.settings".localized)
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .cornerRadius(21)
            }
            Button {
                DispatchQueue.main.async {
                    isVisible = false
                }
            } label: {
                Text("Not now")
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
    }
}
