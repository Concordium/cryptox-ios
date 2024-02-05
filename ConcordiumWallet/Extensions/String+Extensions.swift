//
//  String+Extensions.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 27.04.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

extension LosslessStringConvertible {
    var string: String { .init(self) }
}

extension String {
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."

        var versionComponents = components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count

        if zeroDiff == 0 {
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff))
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros)
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents
                .joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
        }
    }
}


extension Optional where Wrapped == String {
    var toURL: URL? {
        guard let self = self else { return nil }
        return URL(string: self)
    }
}

extension String {
    var toURL: URL? {
        URL(string: self)
    }
}
