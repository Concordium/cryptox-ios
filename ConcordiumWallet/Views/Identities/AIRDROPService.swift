//
//  AIRDROPService.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 04.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation


struct AIRDROPService {
    
    static var session: URLSession {
        return URLSession(configuration: URLSessionConfiguration.ephemeral)
    }
    
    static func perform(with airdropId: Int, wallet: String, urlString: String) async throws -> Model.Airdrop {
        
        let parameters: [String: CustomStringConvertible] = [
            "airdrop_id": airdropId,
            "language": "en",
            "address": [
                "concordium": wallet
            ]
        ]
                
        guard let domain = URL(string: urlString) else { throw NetworkError.invalidResponse }
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: parameters, options: [.prettyPrinted]) else { throw NetworkError.invalidResponse }
        guard let request = ResourceRequest(url: domain, httpMethod: .post, body: theJSONData).request else { throw NetworkError.invalidResponse }
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Model.Airdrop.self, from: data)
    }
}
