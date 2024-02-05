//
//  NFTRepository.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 31.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation


final class NFTRepository {
    
    struct MarketPlace: Codable, Hashable, Equatable {
        let uuid: UUID
        let host: String
        let name: String
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(uuid)
        }
        
        static func ==(lhs:NFTRepository.MarketPlace, rhs:NFTRepository.MarketPlace) -> Bool { // Implement Equatable
            return lhs.host == rhs.host
        }
    }
    
    private (set) var marketplaces: [NFTMarketplaceViewModel] = []
    public static var shared: NFTRepository = NFTRepository()
    private init() { }
}


// MARK: – Storage
extension NFTRepository.MarketPlace {

    private static let `default` = NFTRepository.MarketPlace(uuid: UUID(), host: ApiConstants.spaceseven, name: "Spaceseven")
    
    static func store(host: String, name: String) {
        let item = NFTRepository.MarketPlace(uuid: UUID(), host: host, name: name)
        var items = NFTRepository.MarketPlace.feth()
        items.append(item)
        UserDefaults.standard.set(value: items, forKey: "marketplaces")
    }
    
    static func feth() -> [NFTRepository.MarketPlace] {
        guard var items: [NFTRepository.MarketPlace] = UserDefaults.standard.codable(forKey: "marketplaces") else { return [NFTRepository.MarketPlace.default] }
        if items.isEmpty && !items.contains(NFTRepository.MarketPlace.default) {
        	items.append(NFTRepository.MarketPlace.default)
        }
        return items
    }
    
    static func remove(by uuid: UUID) {
        let items = NFTRepository.MarketPlace.feth().filter({ $0.uuid != uuid })
        UserDefaults.standard.set(value: items, forKey: "marketplaces")
    }
    
    static func removeAll() {
        let items: [NFTRepository.MarketPlace] = []
        UserDefaults.standard.set(value: items, forKey: "marketplaces")
    }
}


//
extension UserDefaults {
func set<Element: Codable>(value: Element, forKey key: String) {
        let data = try? JSONEncoder().encode(value)
        UserDefaults.standard.setValue(data, forKey: key)
    }
func codable<Element: Codable>(forKey key: String) -> Element? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let element = try? JSONDecoder().decode(Element.self, from: data)
        return element
    }
}
//

