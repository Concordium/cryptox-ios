//
//  Array+Ext.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 03.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}
