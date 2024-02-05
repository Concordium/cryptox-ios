//
//  NFTDataStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

protocol NFTDataStatusViewDelegate: AnyObject {
    
    func didTap(from: NFTDataStatusView, with model: NFTTokenViewModel)
}


class NFTDataStatusView: UIView, NibLoadable {
    typealias Section = NFTImport.Section
    
    var delegate: NFTDataStatusViewDelegate?
    
    private var items: [Section] = []
    
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet { setup() }
    }
}

extension NFTDataStatusView {
    
    private func setup() {
        collectionView.alwaysBounceVertical = true
        collectionView.isScrollEnabled = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(cellType: NFTDataItemCell.self)
        collectionView.register(cellType: NFTDataEmptyCell.self)
        collectionView.register(viewType: NFTDataReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
    }
    
    func update(with items: [Section]) {
        self.items = items
        collectionView.reloadData()
    }
}


// MARK: - UICollectionViewDataSource
extension NFTDataStatusView: UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let item = items[indexPath.section].header
        switch item {
        case .header, .noHeader:
            let view: NFTDataReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, for: indexPath)
            return view
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let element = items[indexPath.section].items[indexPath.item]

        switch element {
        case .item(let item):
            let cell: NFTDataItemCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.model = item
            return cell
        case .noItems:
            let cell: NFTDataItemCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell
        }
    }
}


// MARK: - UICollectionViewDelegate
extension NFTDataStatusView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let element = items[indexPath.section].items[indexPath.item]
        
        switch element {
        case .item(let item):
            delegate?.didTap(from: self, with: item)
        default:
            break
        }
    }
}


// MARK: - UICollectionViewDelegateFlowLayout
extension NFTDataStatusView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let element = items[section].header
        switch element {
        case .header:
            let height =  NFTDataReusableView.height()

            return CGSize(width: collectionView.frame.size.width, height: height)
        case .noHeader:
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 28, left: 18, bottom: 0, right: 18)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cvWidth = collectionView.bounds.width
        let itemsSpacing = CGFloat(8)
        let countSpacing: CGFloat = 18

        let cellWidth: CGFloat = (cvWidth - countSpacing * itemsInLine - itemsSpacing) / CGFloat(itemsInLine)
        
        let cellHeight: CGFloat = cellWidth + 66
        let size = CGSize(width: cellWidth, height: cellHeight )
        return size
    }
    
    var itemsInLine: CGFloat {
        return 2
    }
}


// MARK: - instantie
extension NFTDataStatusView {
    
    class func instantie(delegate: NFTDataStatusViewDelegate? = nil) -> NFTDataStatusView {
        let view =  NFTDataStatusView.loadFromNib()
        view.delegate = delegate
        return view
    }
}
