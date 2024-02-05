//
//  String+Lines.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Foundation

extension String {
    func splitInto(lines numberOfLines: Int) -> String {
        guard numberOfLines > 0 && count > numberOfLines else {
            return self
        }
        
        let lineLength = count / numberOfLines
        var index = 0
        var lines = [Substring]()
        while index < self.count {
            let start = self.index(startIndex, offsetBy: index)
            let end = self.index(startIndex, offsetBy: min(index+lineLength, count))
            lines.append(self[start..<end])
            index += lineLength
        }
        
        return lines.joined(separator: "\n")
    }
}
