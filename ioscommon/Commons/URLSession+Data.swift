//
//  URLSession+Data.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 28.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation


@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
extension URLSession {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}
