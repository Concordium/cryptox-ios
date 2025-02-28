//
//  ValidatorMetadataViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 20.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Combine
import Foundation
import SwiftUICore

class ValidatorMetadataViewModel: ObservableObject {
    @Published var currentMetadataUrl: String
    @Published var isNoChanges: Bool = false
    let dataHandler: BakerDataHandler

    init(dataHandler: BakerDataHandler) {
        self.dataHandler = dataHandler
        let currentValue: BakerMetadataURLData? = dataHandler.getCurrentEntry()
        currentMetadataUrl = currentValue?.metadataURL ?? ""
    }
    
    func pressedContinue(completion: @escaping () -> Void) {
        self.dataHandler.add(entry: BakerMetadataURLData(metadataURL: currentMetadataUrl))
        
        if dataHandler.containsChanges() || dataHandler.transferType == .registerBaker {
            completion()
        } else {
            isNoChanges = true
        }
    }
}

extension ValidatorMetadataViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorMetadataViewModel, rhs: ValidatorMetadataViewModel) -> Bool {
        lhs.currentMetadataUrl == rhs.currentMetadataUrl &&
        lhs.isNoChanges == rhs.isNoChanges
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(currentMetadataUrl)
        hasher.combine(isNoChanges)
    }
}
