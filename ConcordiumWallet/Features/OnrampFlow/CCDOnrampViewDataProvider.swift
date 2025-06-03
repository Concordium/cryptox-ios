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
    
    struct DataProvider: Identifiable {
        let title: String
        let url: URL
        let icon: URL
        var isPaymentProvider: Bool = false
        
        var id: String { url.absoluteString }
    }
    
    static var sections: [DataProvidersSection] {
#if MAINNET
        [
            DataProvidersSection(title: "Payment Gateway", providers: CCDOnrampViewDataProvider.swipelux),
            DataProvidersSection(title: "CEX", providers: CCDOnrampViewDataProvider.cex),
            DataProvidersSection(title: "DEX", providers: [CCDOnrampViewDataProvider.dex]),
        ]
#else
        [
            DataProvidersSection(title: "Payment Gateway", providers: CCDOnrampViewDataProvider.swipelux),
            DataProvidersSection(title: "CEX", providers: CCDOnrampViewDataProvider.cex),
            DataProvidersSection(title: "DEX", providers: [CCDOnrampViewDataProvider.dex]),
            DataProvidersSection(title: "Testnet", providers: [CCDOnrampViewDataProvider.testnet]),
        ]
#endif

    }
    
    static var swipelux: [DataProvider] {
        [
            DataProvider(
                title: "Swipelux",
                url: URL(string: "https://track.swipelux.com")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/65e825be9290e43f9d1bc29b_52c3517d-1bb0-4705-a952-8f0d2746b4c5.jpg")!,
                isPaymentProvider: true
            ),
            DataProvider(
                title: "Wert",
                url: URL(string: "https://widget.wert.io/01HM0W8FTFG4TEBRB0JPM18G5W/widget/?commodity=CCD&network=concordium&commodity_id=ccd.simple.concordium")!,
                icon: URL(string: "https://partner.wert.io/icons/apple-touch-icon.png")!,
                isPaymentProvider: true
            )
        ]
    }
    
    static var testnet: DataProvider {
        DataProvider(
            title: "CCD Faucet",
            url: URL(string: "https://radiokot.github.io/ccd-faucet/")!,
            icon: URL(string: "https://em-content.zobj.net/source/apple/391/smiling-face-with-sunglasses_1f60e.png")!,
            isPaymentProvider: true
        )
    }
    
    static var cex: [DataProvider] {
        [
            DataProvider(
                title: "KuCoin",
                url: URL(string: "https://www.kucoin.com/")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/64f0d1d17b59787f0d1b3740_logo-favicon-kucoin.png")!
            ),
            DataProvider(
                title: "Bitfinex",
                url: URL(string: "https://trading.bitfinex.com/t/CCD:USD?type=exchange")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/64f0d15bd065ec0e03a32ac5_bitfinex.png")!
            ),
            DataProvider(
                title: "Lets Exchange",
                url: URL(string: "https://letsexchange.io/")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/64fed810c7dd2cfc068c17cf_1680692222678%20(1).jpg")!
            ),
            DataProvider(
                title: "AscendEX (BitMax)",
                url: URL(string: "https://ascendex.com/en/cashtrade-spottrading/usdt/ccd")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/64f0d273cc264cf97db45e72_logo-favicon-ascendex.png")!
            ),
            DataProvider(
                title: "MEXC",
                url: URL(string: "https://www.mexc.com/")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/64f0d2446607fca14ba4af27_logo-favicon-mexc.png")!
            ),
            DataProvider(
                title: "Bit2Me Pro",
                url: URL(string: "https://bit2me.com/price/concordium")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/64f0d2d9a6d5f9d1cca6dfe6_logo-favicon-bit2me.png")!
            ),
            DataProvider(
                title: "LCX",
                url: URL(string: "https://exchange.lcx.com/")!,
                icon: URL(string: "https://assets-global.website-files.com/64f060f3fc95f9d2081781db/660ef2975d8736c5529f54b9_LCX.jpg")!
            ),
            DataProvider(
                title: "Gate.io",
                url: URL(string: "https://www.gate.io/trade/CCD_USDT")!,
                icon: Bundle.main.url(forResource: "Gate_io", withExtension: "png")!
            )
        ]
    }
    
    static var dex: DataProvider {
        #if MAINNET
            DataProvider(
                title: "Concordex",
                url: URL(string: "https://app.concordex.io/trade?mode=simple")!,
                icon: URL(string: "https://cdn.prod.website-files.com/64f060f3fc95f9d2081781db/64f0d420d065ec0e03a694b9_logo-favicon-concordex.png")!
            )
        #else
            DataProvider(
                title: "Concordex Testnet",
                url: URL(string: "https://testnet.concordex.io/trade?mode=simple")!,
                icon: URL(string: "https://cdn.prod.website-files.com/64f060f3fc95f9d2081781db/64f0d420d065ec0e03a694b9_logo-favicon-concordex.png")!
            )
        #endif
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
        }
        return provider.url
    }
}
