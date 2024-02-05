//
//  Data+Hex.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 02.11.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import Foundation


extension Data {
    
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
