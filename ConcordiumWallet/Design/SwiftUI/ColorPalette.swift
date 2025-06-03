//
//  ColorPalette.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI

enum Pallette {
    static var primary: Color {
        return Color("primary")
    }
    
    static var primarySelected: Color {
        return Color("primarySelected")
    }
    
    static var secondary: Color {
        return Color("secondary")
    }
    
    static var buttonText: Color {
        return Color("buttonText")
    }
    
    static var fadedText: Color {
        return Color("fadedText")
    }
    
    static var text: Color {
        return Color("text")
    }
    
    static var errorText: Color {
        return Color("errorText")
    }
    
    static var error: Color {
        return Color("error")
    }
    
    static var whiteText: Color {
        return Color("whiteText")
    }
    
    static var background: Color {
        return Color("background")
    }
    
    static var barBackground: Color {
        return Color("barBackground")
    }
    
    static var barButton: Color {
        return Color("barButton")
    }
    
    static var inactiveButton: Color {
        return Color("inactiveButton")
    }
    
    static var inactiveCard: Color {
        return Color("inactiveCard")
    }
    
    static var separator: Color {
        return Color("separator")
    }
    
    static var shadow: Color {
        return Color("shadow")
    }
    
    static var success: Color {
        return Color("success")
    }
    
    static var headerCellColor: Color {
        return Color("headerCellColor")
    }
    
    static var yellowBorder: Color {
        return Color("yellowBorder")
    }
    
    static var recoveryBackground: Color {
        return Color("recoveryBackground")
    }
}


/// v2.0
extension Pallette {
    static var greySecondary: Color {
        Color("grey_secondary")
    }
    
    static var greenSecondary: Color {
        Color("green_secondary")
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
