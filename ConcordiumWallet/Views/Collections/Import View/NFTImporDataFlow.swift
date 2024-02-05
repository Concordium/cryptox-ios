//
//  NFTImporDataFlow.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 23.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation


struct NFTTokenViewModel {
    let model: Model.NFT.Token
    
    init(with model: Model.NFT.Token) {
        self.model = model
    }
    
    var name: String { model.nftName }
    var marketplaceName: String { model.marketplaceName }
    var image: String {
        let icon_preview_url =  model.iconPreviewURL ?? ""
        return icon_preview_url.isEmpty ? (model.imageURL ?? "") : icon_preview_url
    }
}


enum NFTImport {
    
    
    struct Section {
        // MARK: - Header
        enum Header {
            case header
            case noHeader
        }

        // MARK: - Model
        enum Item {
            case noItems
            case item(NFTTokenViewModel)
        }

        var header: Header
        var items: [Item]
    }
    
    
    
    // MARK: - State
    enum ViewControllerState {
        case inputData
        case loading
        case result([Section])
        case emptyResult
        case error
    }
    
    // MARK: - Action
    enum Action: ActionTypeProtocol {
        case open(item: NFTTokenViewModel)
        case fetch(address: String, name: String)
    }
}



extension NFTImport.Section {
    
    var isEmpty: Bool {
        return items.isEmpty
    }
}
