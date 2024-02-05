//
//  Reusable.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 23.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


protocol Reusable: AnyObject {
    static var reuseIdentifier: String { get }
}

extension Reusable {
    static var reuseIdentifier: String {
        return String(reflecting: self)
    }
}

typealias NibReusable = NibLoadable & Reusable

