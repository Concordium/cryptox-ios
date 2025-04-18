//
//  Data+Additions.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 11.01.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
    
    var hexDescription: String {
        reduce("") {$0 + String(format: "%02x", $1)}
    }
    
    init?(hex: String) {
        let length = hex.count / 2
        var data = Data(capacity: length)
        var index = hex.startIndex
        for _ in 0..<length {
            let end = hex.index(index, offsetBy: 2)
            let bytes = hex[index..<end]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            index = end
        }
        self = data
    }
}
