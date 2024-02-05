//
//  NFTMarketplaceCell.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 31.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

class NFTMarketplaceCell: UITableViewCell,NibReusable {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var countLabel: UILabel!

    var model: NFTMarketplaceViewModel? {
        didSet {
            guard let model = model else { return }
            update(with: model)
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}


extension NFTMarketplaceCell {
    
    private func update(with model: NFTMarketplaceViewModel) {
        nameLabel.text = model.name
        countLabel.text = model.count == 1 ? "\(model.count) item " : "\(model.count) items "
    }
}
