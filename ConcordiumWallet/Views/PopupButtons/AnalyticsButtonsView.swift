//
//  AnalyticsButtonsView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 07.08.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import UIKit
import MatomoTracker

///
/// Matomo tracker dosent need `ATTrackingManager.requestTrackingAuthorization`
///
/// - https://matomo.org/faq/general/does-apples-ios-14-5-software-update-which-requires-asking-for-consent-for-tracking-impact-matomo/
///

struct AnalyticsButtonsView: View {
    
    @Binding var isPresented: Bool
    
    var container: UIViewController?
    
    var body: some View {
        Button(action: {
            updateTrackingProperties(isAllowed: true)
            isPresented = false
            container?.dismiss(animated: true)
        }, label: {
            Text("analytics.allowTracking".localized)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                .cornerRadius(21)
        })
        
        Button(action: {
            Vibration.vibrate(with: .light)
            updateTrackingProperties(isAllowed: false)
            isPresented = false
            container?.dismiss(animated: true)
        }, label: {
            Text("analytics.askNotToTrack".localized)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.08, green: 0.09, blue: 0.11))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        })
    }
    
    private func updateTrackingProperties(isAllowed: Bool) {
        UserDefaults.standard.set(isAllowed, forKey: "isAnalyticsEnabled")
        MatomoTracker.shared.isOptedOut = !isAllowed
    }
}
