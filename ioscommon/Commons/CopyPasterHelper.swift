//
//  CopyPasterHelper.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 17.12.2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit


struct CopyPasterHelper {
    static func copy(string: String) {
        UIPasteboard.general.string = string
    }
}
