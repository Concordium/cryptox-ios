//
//  MenuItemCellView.swift
//  ConcordiumWallet
//
//  Created by Concordium on 5/10/20.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation
import UIKit

class MenuItemCellView: UITableViewCell {
    @IBOutlet weak var menuItemTitleLabel: UILabel!
    @IBOutlet weak var menuItemImage: UIImageView!
    
    func bind(viewModel: MenuCell) {
        menuItemTitleLabel.text = viewModel.title
        menuItemTitleLabel.textColor = viewModel.color
        menuItemImage.tintColor = viewModel.color.withAlphaComponent(0.7)
        
        if let img = viewModel.image {
            menuItemImage.image = img
            menuItemImage.isHidden = false
        } else {
            menuItemImage.isHidden = true
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        alpha = highlighted ? 0.7 : 1
    }
}
