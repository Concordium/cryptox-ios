//
//  VerifiableJSON.swift
//  CryptoX
//
//  Created by Max on 07.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

struct VerifiableJSON: Codable {
    let verifiablePresentationJson: VerifiablePresentation
}

extension VerifiableJSON {
    func wrappedAsDictionary() throws -> [String: String] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let innerData = try encoder.encode(verifiablePresentationJson)
        guard let innerJSONString = String(data: innerData, encoding: .utf8) else {
            throw NSError(domain: "VerifiableJSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to encode inner presentation"])
        }

        return ["verifiablePresentationJson": innerJSONString]
    }
}
