//
//  AnyPublisher+Extentions.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Combine

extension Publishers {
    struct MissingOutputError: Error {}
}

extension Publisher {
    func singleOutput() async throws -> Output {
        for try await output in values {
            // Since we're immediately returning upon receiving
            // the first output value, that'll cancel our
            // subscription to the current publisher:
            return output
        }
        
        throw Publishers.MissingOutputError()
    }
}

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = first()
                .sink { result in
                    switch result {
                        case .finished:
                            break
                        case let .failure(error):
                            continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
        }
    }
}
