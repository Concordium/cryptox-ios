//
//  StakeStatusViewModelError.swift
//  StagingNet
//
//  Created by Zhanna Komar on 04.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

struct StakeStatusViewModelError: Identifiable {
    let id = UUID()
    let error: Error

    init(_ error: Error) {
        self.error = error
    }
}
