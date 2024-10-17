//
//  AllowNotificationsPopup.swift
//  CryptoX
//
//  Created by Zhanna Komar on 06.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AllowNotificationsPopup: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        PopupContainer(icon: "icon_notification",
                       title: "Don't miss a thing",
                       subtitle: "Get notified about transactions, new features, and other news.",
                       content: requestAccessForPushNotifications()) {
            isVisible = false
        }
    }
    
    private func requestAccessForPushNotifications() -> some View {
        VStack {
            Button {
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        } else {
                            print("Notifications not granted")
                        }
                    }
                    isVisible = false
                }
            } label: {
                Text("Allow notifications")
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
