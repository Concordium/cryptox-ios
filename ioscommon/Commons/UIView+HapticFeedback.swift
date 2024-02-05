//
//  UIView+HapticFeedback.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 11.09.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit
import AudioToolbox



extension UIView {
    
    func vibrate(with type: Vibration) {
        Vibration.vibrate(with: type)
    }
}


enum Vibration {
    
    case error
    case success
    case warning
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case oldSchool
    
    static func vibrate(with type: Vibration) {
        switch type {
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .oldSchool:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
}
