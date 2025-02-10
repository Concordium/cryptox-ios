//
//  File.swift
//  CryptoX
//
//  Created by Max on 05.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Concordium

// Helpers
extension ConcordiumClient {
    /// - Parameter expiry: The transaction expiry in seconds since Unix epoch.
    static func calculateTransactionExpiry(from expiry: TransactionTime) -> TransactionTime {
        // Adding 10 minutes (600 seconds) to the expiry
        let tenMinutesInSeconds: TransactionTime = 600
        return expiry + tenMinutesInSeconds
    }
}
