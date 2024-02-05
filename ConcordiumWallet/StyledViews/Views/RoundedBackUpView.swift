//
//  RoundedBackUpView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 25.01.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import UIKit

class RoundedBackupView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 14.0
    }
}
