//
//  NotificationsView.swift
//  StagingNet
//
//  Created by Zhanna Komar on 06.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct NotificationsView: View {
    @State private var isCCDTransactionNotificationAllowed = UserDefaults.bool(forKey: TransactionNotificationNames.ccd.rawValue)
    @State private var isCIS2TransactionNotificationAllowed = UserDefaults.bool(forKey: TransactionNotificationNames.cis2.rawValue)
    
    var body: some View {
        VStack(spacing: 24) {
            Divider()
                .tint(Color("black_secondary"))
            Toggle(isOn: $isCCDTransactionNotificationAllowed) {
                Text("notifications.ccdtransactions".localized)
                    .font(.satoshi(size: 19, weight: .medium))
                    .foregroundColor(Color.whiteMain)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.greenSecondary))
            .onChange(of: isCCDTransactionNotificationAllowed, perform: { value in
                // TODO: handle state changed
                UserDefaults.standard.set(value, forKey: TransactionNotificationNames.ccd.rawValue)
            })
            
            Toggle(isOn: $isCIS2TransactionNotificationAllowed) {
                Text("notifications.cis2tokentransactions".localized)
                    .font(.satoshi(size: 19, weight: .medium))
                    .foregroundColor(Color.whiteMain)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.greenSecondary))
            .onChange(of: isCIS2TransactionNotificationAllowed, perform: { value in
                // TODO: handle state changed
                UserDefaults.standard.set(value, forKey: TransactionNotificationNames.cis2.rawValue)
            })
            Spacer()
        }
        .padding()
        .background(content: {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.14, green: 0.14, blue: 0.15), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.03, green: 0.03, blue: 0.04), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .ignoresSafeArea(.all)
        })
    }
}

#Preview {
    NotificationsView()
}
