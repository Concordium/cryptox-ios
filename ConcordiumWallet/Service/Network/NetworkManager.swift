//
// Created by Concordium on 13/02/2020.
// Copyright (c) 2020 concordium. All rights reserved.
//

import Foundation
import Combine

protocol NetworkSession {
    func load(request: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>
    func load(request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension URLSession: NetworkSession {
    func load(request: URLRequest) -> AnyPublisher<DataTaskPublisher.Output, DataTaskPublisher.Failure> {
        dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
    
    func load(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            dataTask(with: request) { data, urlResponse, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = urlResponse as? HTTPURLResponse {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: NetworkError.invalidResponse)
                }
            }.resume()
        }
    }
}

final class NetworkManager: NetworkManagerProtocol {
    private let session: NetworkSession
    private let decoder = newJSONDecoder()

    init(session: NetworkSession = URLSession(configuration: URLSessionConfiguration.ephemeral)) {
        self.session = session
    }

    func load<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
        if LegacyLogger.shouldLog(on: .debug) {
            if
                let bodyData = request.httpBody,
                let bodyString = String(data: bodyData, encoding: .utf8),
                let httpMethod = request.httpMethod
            {
                LegacyLogger.debug("TX \(String(describing: httpMethod)) \(String(describing: request.url)):\n\(bodyString)")
            } else if let httpMethod = request.httpMethod {
                LegacyLogger.debug("TX \(String(describing: httpMethod)) \(request)")
            }
        }
        return session.load(request: request)
                .mapError { err in
                    return NetworkError.communicationError(error: err) }
                .flatMap { data, response -> AnyPublisher<Data, Error> in
                    guard let response = response as? HTTPURLResponse else {
                        return .fail(NetworkError.invalidResponse)
                    }

                    guard 200..<300 ~= response.statusCode else {
                        LegacyLogger.error("RX \(response.statusCode) \(String(describing: request.url)):\n\(String(data: data, encoding: .utf8) ?? "")")
                        if let error = try? ServerErrorMessage(data: data) {
                            return .fail(NetworkError.serverError(error: error))
                        }
                        return .fail(NetworkError.dataLoadingError(statusCode: response.statusCode, data: data))
                    }
                    
                    if let url = response.url, let fields = response.allHeaderFields as? [String: String] {
                        CookieJar.cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
                    }

                    return .just(data)
                }
                .map { data in
                    if let url = request.url {
                        LegacyLogger.debug("RX \(String(describing: url)):\n\(String(data: data, encoding: .utf8) ?? "")")
                    }
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .mapError({ error -> Error in
                    if error is NetworkError {
                        return error // do not attempt to map an error that is not caused by the json decoding
                    }
                    LegacyLogger.error("cannot decode - \(String(describing: request.url)):\n\(error)")
                    return NetworkError.jsonDecodingError(error: error)
                })
                .performInBackground()
                // comment this in to force loading indicator
//                .delay(for: 1.0, scheduler: RunLoop.main)
                .eraseToAnyPublisher()
    }
    
    func load<T>(_ request: URLRequest) async throws -> T where T: Decodable {
        if LegacyLogger.shouldLog(on: .debug) {
            if
                let bodyData = request.httpBody,
                let bodyString = String(data: bodyData, encoding: .utf8),
                let httpMethod = request.httpMethod
            {
                LegacyLogger.debug("TX \(String(describing: httpMethod)) \(String(describing: request.url)):\n\(bodyString)")
            } else if let httpMethod = request.httpMethod {
                LegacyLogger.debug("TX \(String(describing: httpMethod)) \(request)")
            }
        }
        
        do {
            let (data, response) = try await session.load(request: request)
            
            guard 200..<300 ~= response.statusCode else {
                LegacyLogger.error("RX \(response.statusCode) \(String(describing: request.url)):\n\(String(data: data, encoding: .utf8) ?? "")")
                if let error = try? ServerErrorMessage(data: data) {
                    throw NetworkError.serverError(error: error)
                }
                throw NetworkError.dataLoadingError(statusCode: response.statusCode, data: data)
            }
            
            if let url = response.url, let fields = response.allHeaderFields as? [String: String] {
                CookieJar.cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
            }
            
            return try decoder.decode(T.self, from: data)
        } catch {
            if error is DecodingError {
                throw NetworkError.jsonDecodingError(error: error)
            } else {
                throw NetworkError.communicationError(error: error)
            }
        }
    }
    
    func loadRecovery<T>(_ request: URLRequest) async throws -> T where T: Decodable {
        if LegacyLogger.shouldLog(on: .debug) {
            if
                let bodyData = request.httpBody,
                let bodyString = String(data: bodyData, encoding: .utf8),
                let httpMethod = request.httpMethod
            {
                LegacyLogger.debug("TX \(String(describing: httpMethod)) \(String(describing: request.url)):\n\(bodyString)")
            } else if let httpMethod = request.httpMethod {
                LegacyLogger.debug("TX \(String(describing: httpMethod)) \(request)")
            }
        }
        
        let (data, response) = try await session.load(request: request)
        
        guard 200..<300 ~= response.statusCode else {
            LegacyLogger.error("RX \(response.statusCode) \(String(describing: request.url)):\n\(String(data: data, encoding: .utf8) ?? "")")
            
            throw NetworkError.dataLoadingError(statusCode: response.statusCode, data: data)
        }
        
        if let url = response.url, let fields = response.allHeaderFields as? [String: String] {
            CookieJar.cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch let err {
            // In case of wallet recovery DTS double encodes the response and that's a workaround for this.
            if let json = try? decoder.decode(String.self, from: data) {
                return try decoder.decode(T.self, from: Data(json.utf8))
            }
            throw err
        }
    }
}
