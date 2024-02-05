//
//  AppConstants.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 17.12.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation

struct AppConstants {
    
    
    // MARK: - Support
    struct Support {
        static let concordiumSupportMail: String =  "contact@pioneeringtechventures.com"
    }
    
    // MARK: - Privacy Policy
    #warning("Max, fix me pls")
    /// fix url
    struct PrivacyPolicy {
        static let url = "https://developer.concordium.software/extra/Terms-and-conditions-Mobile-Wallet.pdf"
        
        static let privacyPolicy = "https://pioneeringtechventures.com/privacy-policy"
        static let termsAndConditions = "https://pioneeringtechventures.com/terms-and-conditions"
    }
    
    struct Media {
        static let youtube = URL(string: "https://youtube.com/@ConcordiumNet?feature=shared")!
        static let ai = URL(string: "https://www.concordium.com/contact")!
    }
    
    struct Email {
        static let contact = "contact@pioneeringtechventures.com"
        static let support = "contact@pioneeringtechventures.com"
    }
}
