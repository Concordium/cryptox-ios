//
//  URLProtocolMock.swift
//  MOCK ConcordiumWallet
//
//  Created by Concordium on 20/04/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation
import Combine

class NetworkSessionMock: NetworkSession {
    /***
       Instead of returning mock objects, setting this to true will fall the server and the
       overwrite local mock json files with the returned data from the server
     */
    let overwriteMockFilesWithServerData = false
    private var overrides = [String: Result<Data, NetworkError>]()

    let urlMapping = [
        ApiConstants.ipInfo: "1.1.2.RX-backend_identity_provider_info",
        ApiConstants.global: "2.1.2.RX-backend_global",
        ApiConstants.submitCredential: "2.3.2.RX_backend_submitCredential",
        ApiConstants.submissionStatus: "2.4.2.RX_backend_submissionStatus",
        ApiConstants.accNonce: "3.1.2.RX_backend_accNonce",
        ApiConstants.transferCost: "2.5.2.RX_backend_transferCost",
        ApiConstants.submitTransfer: "3.3.2.RX_backend_submitTransfer",
        ApiConstants.accountTransactions: "4.2.2.RX_backend_accTransactions_mock",
        ApiConstants.accEncryptionKey: "4.3.2.RX_backend_accEncryptionKey",
        ApiConstants.bakerPool: "5.1.2.RX_backend_baker_pool",
        ApiConstants.chainParameters: "5.2.2.RX_backend_chain_parameters",
        ApiConstants.passiveDelegation: "5.4.2.RX_backend_passiveDelegation"
    ]

    func load(request: URLRequest) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure> {
        if overwriteMockFilesWithServerData {return loadFromServerAndOverwriteWithReceivedData(request: request)}
        if let url = request.url,
           let (data, returnCode) = loadOverride(for: url) ?? loadFile(for: url),
           let urlResponse: URLResponse = HTTPURLResponse(url: request.url!, statusCode: returnCode, httpVersion: nil, headerFields: nil) {
            LegacyLogger.debug("mock returning \(String(data: data, encoding: .utf8)?.prefix(50) ?? "")")
            return .just((data, urlResponse))
        } else {
            return .fail(URLError(.fileDoesNotExist))
        }
    }
    
    func load(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        if overwriteMockFilesWithServerData {
            return try await loadFromServerAndOverwriteWithReceivedData(request: request)
        }
        if let url = request.url,
           let (data, returnCode) = loadOverride(for: url) ?? loadFile(for: url),
           let urlResponse = HTTPURLResponse(url: request.url!, statusCode: returnCode, httpVersion: nil, headerFields: nil) {
            LegacyLogger.debug("mock returning \(String(data: data, encoding: .utf8)?.prefix(50) ?? "")")
            return (data, urlResponse)
        } else {
            throw URLError(.fileDoesNotExist)
        }
    }

    func loadFile(for url: URL) -> (Data, Int)? {
        if let path = Bundle.main.path(forResource: getFilename(for: url), ofType: "json") {
            if let jsonData = NSData(contentsOfFile: path) {
                if path.contains("error") {
                    return (jsonData as Data, 400)
                }
                return (jsonData as Data, 200)
            }
        }
        return nil
    }
    
    private func loadOverride(for url: URL) -> (Data, Int)? {
        guard let result = overrideResult(for: url) else {
            return nil
        }
        
        switch result {
        case let .success(data):
            return (data, 200)
        case let .failure(error):
            switch error {
            case let .dataLoadingError(statusCode, data):
                return (data, statusCode)
            default:
                return (Data(), 400)
            }
        }
    }
    
    private func overrideResult(for url: URL) -> Result<Data, NetworkError>? {
        for key in overrides.keys {
            if url.absoluteString.starts(with: key) {
                return overrides[key]
            }
        }
        
        return nil
    }

    func overrideEndpoint<T: Encodable>(named: String, with object: T) {
        do {
            let data = try JSONEncoder().encode(object)
            
            overrides[named] = .success(data)
        } catch {
            LegacyLogger.warn("unable to encode mock object: \(object)")
        }
    }
    
    func overrideEndpoint(named: String, with error: NetworkError) {
        overrides[named] = .failure(error)
    }
    
    func overrideEndpoint(named: String, withFile location: String) {
        if let path = Bundle.main.path(forResource: location, ofType: "json"), let data = try? Data(contentsOf: .init(fileURLWithPath: path)) {
            overrides[named] = .success(data)
        }
    }
    
    func clearOverrides() {
        overrides.removeAll()
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func getFilename(for url: URL) -> String {
        if url.absoluteString.hasPrefix(ApiConstants.submissionStatus.absoluteString) {
            let submissionId = url.lastPathComponent
            switch submissionId {
            case "a01":
                return "2.4.2.RX_backend_submissionStatus_success"
            case "a02":
                return "2.4.2.RX_backend_submissionStatus_received"
            case "a03":
                return "2.4.2.RX_backend_submissionStatus_committed"
            case "a04":
                return "2.4.2.RX_backend_submissionStatus_absent"
            case "t01":
                return "3.4.2.RX_backend_submissionStatus_rec"
            case "t02":
                return "3.4.2.RX_backend_submissionStatus_com"
            case "t03":
                return "3.4.2.RX_backend_submissionStatus_com_amb"
            case "t04":
                return "3.4.2.RX_backend_submissionStatus_com_reject"
            case "t05":
                return "3.4.2.RX_backend_submissionStatus_abs"
            case "t06":
                return "3.4.2.RX_backend_submissionStatus_fin"
            case "t07":
                return "3.4.2.RX_backend_submissionStatus_fin_reject"
            default:
                return "2.4.2.RX_backend_submissionStatus_success"
            }
        }
        for key in urlMapping.keys {
            if url.absoluteString.hasPrefix(key.absoluteString) {
                return urlMapping[key]!
            }
        }
        return ""
    }
}

extension NetworkSessionMock { // Methods for overwriting data instead of returning the mocked data
    private func loadFromServerAndOverwriteWithReceivedData(request: URLRequest)
                    -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure> {
        URLSession.shared.dataTaskPublisher(for: request).handleEvents(receiveOutput: { (data, _) in
            if let url = request.url,
               let path = Bundle.main.url(forResource: self.getOverwriteFilename(for: url), withExtension: "json") {
                LegacyLogger.info("Writing to \(path)")
                try? data.write(to: path)
            }
        }).eraseToAnyPublisher()
    }
    
    private func loadFromServerAndOverwriteWithReceivedData(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, HTTPURLResponse), Error>) in
            URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response as? HTTPURLResponse {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: NetworkError.invalidResponse)
                }
            }).resume()
        }
        
        if let url = request.url,
           let path = Bundle.main.url(forResource: self.getOverwriteFilename(for: url), withExtension: "json") {
            LegacyLogger.info("Writing to \(path)")
            try? data.write(to: path)
        }
        
        return (data, response)
    }

    func getOverwriteFilename(for url: URL) -> String {
        for key in urlMapping.keys {
            if url.absoluteString.hasPrefix(key.absoluteString) {
                return urlMapping[key]!
            }
        }
        return ""
    }
}
