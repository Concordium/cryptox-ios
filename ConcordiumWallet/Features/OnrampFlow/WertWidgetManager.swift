//
//  WertWidgetManager.swift
//  CryptoX
//
//  Created by Zhanna Komar on 09.04.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import CryptoKit
import UIKit
import SafariServices


struct WertCommodityInfo: Codable {
    let commodity: String
    let network: String
}

class WertWidgetManager {
    private static var baseUrl = "https://widget.wert.io/\(AppConstants.Wert.partnerId)/widget"

    private static func createWertSession(for account: String) async throws -> [String: Any] {
        guard let url = URL(string: AppConstants.Wert.url) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AppConstants.Wert.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "flow_type": "simple",
            "wallet_address": account,
            "currency": "USD",
            "commodity": "CCD",
            "network": "concordium"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Invalid JSON")
            throw NSError(domain: "Invalid JSON", code: -2)
        }

        return json
    }

    private static func getWertWidgetUrlString(for account: String) async -> String? {
        do {
            let json = try await createWertSession(for: account)
            if let sessionId = json["sessionId"] as? String {
                let sessionIdEncoded = encodeString(sessionId)
                let commodityEncoded = encodeString("CCD")
                let networkEncoded = encodeString("concordium")
                let layoutModeEncoded = encodeString("Modal")
                
                let commodityInfo = [WertCommodityInfo(commodity: "CCD", network: "concordium")]
                guard let jsonData = try? JSONEncoder().encode(commodityInfo),
                      let jsonString = String(data: jsonData, encoding: .utf8) else {
                    return nil
                }

                let commoditiesEncoded = encodeString(jsonString)
                
                let url = "\(baseUrl)?" +
                                  "session_id=\(sessionIdEncoded)&" +
                                  "commodity=\(commodityEncoded)&" +
                                  "network=\(networkEncoded)&" +
                                  "commodities=\(commoditiesEncoded)&" +
                                  "widget_layout_mode=\(layoutModeEncoded)"
                return url
            }
        } catch {
            print("Wert session error:", error)
        }
        return nil
    }

    static func getWertIOURL(for account: String) async -> URL? {
        guard let urlString = await getWertWidgetUrlString(for: account), let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
    
    private static func encodeString(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}
