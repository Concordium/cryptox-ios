//
//  UITableView+scroll.swift
//  sos-demo
//
//  Concordium on 22/10/2019.
//  Copyright © 2019 Ruxandra Nistor. All rights reserved.
//

import UIKit

extension UITableView {
    func sizeHeaderToFit() {
        if let headerView = tableHeaderView {
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()

            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var frame = headerView.frame
            frame.size.height = height
            headerView.frame = frame

            tableHeaderView = headerView
        }
    }
}
