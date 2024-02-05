//
//  Fonts.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import UIKit
import SwiftUI

struct Fonts {
    static let title = UIFont.systemFont(ofSize: 32)
    static let heading = UIFont.systemFont(ofSize: 24)
    static let subheading = UIFont.systemFont(ofSize: 20)
    static let body = UIFont.systemFont(ofSize: 15)
    static let navigationBarTitle = UIFont.systemFont(ofSize: 17, weight: .bold)
    static let info = UIFont.systemFont(ofSize: 16, weight: .bold)
    static let buttonTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let cellHeading = UIFont.systemFont(ofSize: 10, weight: .medium)
    static let tabBar = UIFont.systemFont(ofSize: 14, weight: .medium)
    static let mono = UIFont(name: "RobotoMono-Regular", size: 12)
}


extension Font {
    static func satoshi(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
            case .bold: return .custom("Satoshi-Bold", size: size)
            case .medium: return .custom("Satoshi-Medium", size: size)
            case .regular: return .custom("Satoshi-Regular", size: size)
            default: return .system(size: size, weight: weight)
        }
    }
    
    static func plexMono(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
            case .bold: return .custom("IBMPlexMono-Bold", size: size)
            case .medium: return .custom("IBMPlexMono-Medium", size: size)
            case .regular: return .custom("IBMPlexMono-Regular", size: size)
            case .semibold: return .custom("IBMPlexMono-Semibold", size: size)
            default: return .system(size: size, weight: weight)
        }
    }
    
    static func plexSans(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
            case .bold: return .custom("IBMPlexSans-Bold", size: size)
            case .medium: return .custom("IBMPlexSans-Medium", size: size)
            case .regular: return .custom("IBMPlexSans-Regular", size: size)
            case .semibold: return .custom("IBMPlexSans-Semibold", size: size)
            case .light: return .custom("IBMPlexSans-Light", size: size)
            default: return .system(size: size, weight: weight)
        }
    }
}
