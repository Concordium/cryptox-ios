//
//  IdentifiableString.swift
//  CryptoX
//
//  Created by Zhanna Komar on 24.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

struct IdentifiableString: Identifiable {
    var id: String { value }
    var value: String
}

extension String: Identifiable {
    public var id: String { self }
}
