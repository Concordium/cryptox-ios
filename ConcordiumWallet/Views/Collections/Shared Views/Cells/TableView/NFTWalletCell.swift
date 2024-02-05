//
//  NFTMarketplaceEmptyCell.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 31.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

class NFTWalletCell: UITableViewCell, NibReusable {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var countLabel: UILabel!

    var model: NFTWalletViewModel? {
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


extension NFTWalletCell {
    
    private func update(with model: NFTWalletViewModel) {
        nameLabel.text = model.name
        countLabel.text = model.count == 1 ? "\(model.count) item " : "\(model.count) items "
    }
}
