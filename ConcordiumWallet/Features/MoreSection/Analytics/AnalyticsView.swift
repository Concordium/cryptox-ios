//
//  AnalyticsView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 02.08.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import MatomoTracker

struct AnalyticsView: View {
    
    @State private var isAllowedAppTracking = UserDefaults.bool(forKey: "isAnalyticsEnabled")
    
    var body: some View {
        VStack(spacing: 24) {
            Divider()
                .tint(Color("black_secondary"))
            Toggle(isOn: $isAllowedAppTracking) {
                Text("analytics.allowTracking".localized)
                    .font(.satoshi(size: 19, weight: .medium))
                    .foregroundColor(Color.whiteMain)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.greenSecondary))
            .onChange(of: isAllowedAppTracking, perform: { value in
                UserDefaults.standard.set(value, forKey: "isAnalyticsEnabled")
                MatomoTracker.shared.isOptedOut = !value
            })
            
            Text("analytics.trackMessage".localized)
                .font(.satoshi(size: 14, weight: .regular))
                .foregroundColor(Color.blackAditional)
            
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
