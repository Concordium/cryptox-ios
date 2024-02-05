//
//  NFTDataItemCell.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 23.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

import Kingfisher


class NFTDataItemCell: UICollectionViewCell, NibReusable {
    
    @IBOutlet private weak var wrapView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var marketplaceLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    
    var model: NFTTokenViewModel? {
        didSet {
            guard let model = model else { return }
            update(with: model)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        wrapView.layer.cornerRadius = 10
    }
}


extension NFTDataItemCell {
    
    private func update(with model: NFTTokenViewModel) {
        nameLabel.text = model.name
        marketplaceLabel.text = model.marketplaceName
        guard let url = URL(string: model.image) else { return }
        updateImage(with: url)
    }
    
    private func updateImage(with url: URL) {
        imageView.kf.indicatorType = .activity
        if url.absoluteString.contains(".mp4") {
            imageView.kf.setImage(with: AVAssetImageDataProvider(assetURL: url, seconds: 1))
        } else {
            imageView.kf.setImage(with: url)
        }
    }
}
