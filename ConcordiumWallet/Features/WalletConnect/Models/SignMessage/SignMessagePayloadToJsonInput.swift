//
//  SignMessagePayloadToJsonInput.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

struct SignMessagePayloadToJsonInput: Codable {
    let message: String
    let address: String
    let keys: AccountKeys
}

enum SignableValueRepresentation {
    case decoded(String)
    case raw(String)
}
