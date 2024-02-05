//
//  NFTDataReusableView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 24.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

class NFTDataReusableView: UICollectionReusableView, NibReusable {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}


extension NFTDataReusableView {
    
    class func height() -> CGFloat  {
        100.0
    }
}
