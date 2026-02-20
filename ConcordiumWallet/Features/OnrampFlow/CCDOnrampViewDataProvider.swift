//
//  CCDOnrampViewDataProvider.swift
//  CryptoX
//
//  Created by Max on 08.07.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

final class CCDOnrampViewDataProvider {
    struct DataProvidersSection: Identifiable {
        let title: String
        let providers: [DataProvider]
        
        var id: String { title }
    }
    
    enum LogoSource {
        case remote
        case local
    }
    
    struct DataProvider: Identifiable {
        let title: String
        let url: URL
        let icon: String
        let logoSource: LogoSource
        var isPaymentProvider: Bool = false
        
        var id: String { url.absoluteString }
    }
    
    static var sections: [DataProvidersSection] {
#if MAINNET
        [
            DataProvidersSection(title: "Payment Gateway", providers: CCDOnrampViewDataProvider.swipelux),
        ]
#else
        [
            DataProvidersSection(title: "Payment Gateway", providers: CCDOnrampViewDataProvider.swipelux),
            DataProvidersSection(title: "Testnet", providers: [CCDOnrampViewDataProvider.testnet]),
        ]
#endif

    }
    
    static var swipelux: [DataProvider] {
        [
            banxa,
            transak,
            DataProvider(
                title: "Swipelux",
                url: URL(string: "https://track.swipelux.com")!,
                icon: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/65e825be9290e43f9d1bc29b_52c3517d-1bb0-4705-a952-8f0d2746b4c5.jpg",
                logoSource: .remote,
                isPaymentProvider: true
            ),
            DataProvider(
                title: "Wert",
                url: URL(string: "https://widget.wert.io/01HM0W8FTFG4TEBRB0JPM18G5W/widget/?commodity=CCD&network=concordium&commodity_id=ccd.simple.concordium")!,
                icon: "https://partner.wert.io/icons/apple-touch-icon.png",
                logoSource: .remote,
                isPaymentProvider: true
            )
        ]
    }
    
    static var testnet: DataProvider {
        DataProvider(
            title: "CCD Faucet",
            url: URL(string: "https://radiokot.github.io/ccd-faucet/")!,
            icon: "https://em-content.zobj.net/source/apple/391/smiling-face-with-sunglasses_1f60e.png",
            logoSource: .remote,
            isPaymentProvider: true
        )
    }
    
    static var banxa: DataProvider {
        DataProvider(title: "Banxa",
                     url: getBanxaBaseURL(),
                     icon: "https://cdn.prod.website-files.com/67d7fbcd510cf4a3a6267957/685a651d86ccc21ad06deb1b_banxa.jpg",
                     logoSource: .remote,
                     isPaymentProvider: true)
    }
    
    static var transak: DataProvider {
        let title: String
#if MAINNET
        title = "Transak"
#else
        title = "Transak Testnet"
#endif
        return DataProvider(
            title: title,
            url: URL(string: "https://global-stg.transak.com")!,
            icon: "transak_logo",
            logoSource: .local,
            isPaymentProvider: true)
    }
    
    private static func generateSwipeluxURL(
        baseURL: URL,
        targetAddress: String?) -> URL {
            guard let apiKey = Bundle.main.infoDictionary?["API_KEY"] else { return baseURL }
            let settings: [String: Any] = [
                "apiKey": apiKey,
                "defaultValues": [
                    "targetAddress": [
                        "value": targetAddress ?? "",
                        "editable": true
                    ]
                ]
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: settings),
                  let jsonString = String(data: jsonData, encoding: .utf8),
                  let encodedString = jsonString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            else {
                return baseURL
            }
            
            let urlString = "\(baseURL.absoluteString)/?specificSettings=\(encodedString)"

            return URL(string: urlString) ?? baseURL
        }
    
    static func getUrlForProvider(provider: DataProvider, accountAddress: String) async -> URL {
        if provider.title == "Swipelux" {
            return generateSwipeluxURL(baseURL: URL(string: "https://track.swipelux.com")!, targetAddress: accountAddress)
        } else if provider.title == "Wert" {
                if let url = await WertWidgetManager.getWertIOURL(for: accountAddress) {
                    return url
            }
        } else if provider.title == "Banxa" {
            return generateBanxaURL(baseURL: provider.url, targetAddress: accountAddress)
        } else if provider.title == "Transak" {
            do {
                return try await generateTransakURL(targetAddress: accountAddress)
            } catch {
                return provider.url
            }
        }
        return provider.url
    }
    
    private static func getBanxaBaseURL() -> URL {
        var baseURL = ""
#if MAINNET
        baseURL = "https://concordium.banxa.com"
#else
        baseURL = "http://concordium.banxa-sandbox.com"
#endif
        return URL(string: baseURL)!
    }
    
    private static func generateBanxaURL(baseURL: URL, targetAddress: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "coinType", value: "CCD"),
            URLQueryItem(name: "walletAddress", value: targetAddress),
            URLQueryItem(name: "orderType", value: "buy")
        ]
        
        return components?.url ?? baseURL
    }
    
    private static func generateTransakURL(
        targetAddress: String
    ) async throws -> URL {
        let service = TransakService()
        return try await service.fetchTransakURL(for: targetAddress)
    }
}
