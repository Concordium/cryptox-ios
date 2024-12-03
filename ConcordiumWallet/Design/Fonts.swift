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
    static let title = UIFont.satoshi(size: 32, weight: .medium)
    static let heading = UIFont.satoshi(size: 24, weight: .medium)
    static let subheading = UIFont.satoshi(size: 20,  weight: .medium)
    static let body = UIFont.satoshi(size: 15, weight: .medium)
    static let navigationBarTitle = UIFont.satoshi(size: 17, weight: .bold)
    static let info = UIFont.satoshi(size: 16, weight: .bold)
    static let buttonTitle = UIFont.satoshi(size: 17, weight: .semibold)
    static let cellHeading = UIFont.satoshi(size: 10, weight: .medium)
    static let tabBar = UIFont.satoshi(size: 14, weight: .medium)
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

extension UIFont {
    static func satoshi(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        switch weight {
        case .bold: return .init(name: "Satoshi-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
        case .medium: return .init(name: "Satoshi-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
        case .regular: return .init(name:"Satoshi-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
        default: return UIFont.systemFont(ofSize: size, weight: weight)
        }
    }
}
