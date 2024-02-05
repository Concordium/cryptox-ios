//
//  Date+Expire.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 27.11.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation


extension Date {
    
    static func expiration(from string: String) -> Date {
        let `default` = Date().addingTimeInterval(10 * 60)
        guard let stamp = Double(string) else { return `default` }
        
        return Date(timeIntervalSince1970: stamp)
    }
    
}
