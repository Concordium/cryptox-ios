//
//  Locate+Additionals.swift
//  Mock
//
//  Created by Maxim Liashenko on 01.12.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation


extension Locale {
    
    static var preferredLanguage: String {
        
        
        let defaultLanguage = "en"
        let currentLanguage = Locale.current.languageCode
        return currentLanguage ?? defaultLanguage
    }
    
    static var country: String {
        get {
            return current.regionCode ?? preferredLanguage
        }
    }
}
