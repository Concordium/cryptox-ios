//
//  TokenEntity.swift
//  ConcordiumWalvar
//
//  Created by Maxim Liashenko on 27.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

import RealmSwift


final class TokenEntity: Object {
    @objc dynamic var blockchainID: String = ""
    @objc dynamic var nftID: String = ""
    @objc dynamic var marketplace: String = ""
    @objc dynamic var marketplaceName: String = ""
    @objc dynamic var nftPage: String = ""
    @objc dynamic var nftMetadataURL: String? = nil
    @objc dynamic var nftName: String = ""
    @objc dynamic var ownerAddress: String = ""
    @objc dynamic var authorAddress: String = ""
    @objc dynamic var authorRoyalty: String = ""
    @objc dynamic var iconPreviewURL: String = ""
    @objc dynamic var imageURL: String = ""
    @objc dynamic var quantity: String = ""
    @objc dynamic var totalMinted: String = ""
    @objc dynamic var saleStatus: String = ""

    convenience init(blockchainID: String, nftID: String, marketplace: String, marketplaceName: String, nftPage: String, nftMetadataURL: String?, nftName: String, ownerAddress: String, authorAddress: String, authorRoyalty: String, iconPreviewURL: String, imageURL: String, quantity: String, totalMinted: String, saleStatus: String) {
        self.init()
        self.blockchainID = blockchainID
        self.nftID = nftID
        self.marketplace = marketplace
        self.marketplaceName = marketplaceName
        self.nftPage = nftPage
        self.nftMetadataURL = nftMetadataURL
        self.nftName = nftName
        self.ownerAddress = ownerAddress
        self.authorAddress = authorAddress
        self.authorRoyalty = authorRoyalty
        self.iconPreviewURL = iconPreviewURL
        self.imageURL = imageURL
        self.quantity = quantity
        self.totalMinted = totalMinted
        self.saleStatus = saleStatus
    }
}
