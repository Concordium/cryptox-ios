//
//  Optional+Ext.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 03.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

extension Optional where Wrapped == Int {
    func `if`(_ f: (Int) -> Int, _ failureCase: Int = 0) -> Int {
        guard let v = self else { return failureCase }
        return f(v)
    }
}
