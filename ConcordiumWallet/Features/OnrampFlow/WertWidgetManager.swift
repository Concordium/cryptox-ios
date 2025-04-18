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

class WertWidgetManager {

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
                return "https://widget.wert.io/\(AppConstants.Wert.partnerId)/widget?session_id=\(sessionId)&amp;commodity=CCD&amp;network=concordium&amp;commodities=%5B%7B%22commodity%22%3A%22CCD%22%2C%22network%22%3A%22concordium%22%7D%5D&amp;widget_layout_mode=Modal"
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
}
