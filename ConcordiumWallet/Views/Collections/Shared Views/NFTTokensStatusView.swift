//
//  NFTTokensStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

import Combine


protocol NFTTokensStatusViewDelegate: AnyObject {
    
    func didTap(from: NFTTokensStatusView, with model: NFTTokenViewModel)
    func didChangeSearch(from: NFTTokensStatusView, with text: String)
}


class NFTTokensStatusView: UIView, NibLoadable {
    typealias Section = NFTProviders.Section
    
    var delegate: NFTTokensStatusViewDelegate?
    private var cancellables: [AnyCancellable] = []
    
    private var items: [Section] = []
    
    @IBOutlet private weak var searchBar: UISearchBar! {
        didSet { setupSearchBar() }
    }
    
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet { setup() }
    }
}

extension NFTTokensStatusView {
    
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
    
    private func setupSearchBar() {
        searchBar.backgroundColor = .clear
        searchBar.isTranslucent = true
        searchBar.backgroundImage = UIImage()
        // Remove border of search field to match design
        let searchField = searchBar.searchTextField
        searchField.font = UIFont.systemFont(ofSize: 17.0)
        searchField.layer.cornerRadius = 8.0
        searchField.borderStyle = .none
        searchField.backgroundColor = UIColor.greyAdditional.withAlphaComponent(0.1)
        searchBar.placeholder = "token name"
        
        searchBar.searchTextField.textPublisher.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (value) in
                guard let `self` = self else { return }
                self.delegate?.didChangeSearch(from: self, with: value)
            })
            .store(in: &cancellables)
    }
    
    func update(with items: [Section]) {
        self.items = items
        collectionView.reloadData()
    }
}


// MARK: - UICollectionViewDataSource
extension NFTTokensStatusView: UICollectionViewDataSource {
    
    
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
        case .token(let item):
            let cell: NFTDataItemCell = collectionView.dequeueReusableCell(for: indexPath)
            cell.model = item
            return cell
        case .noItems:
            let cell: NFTDataEmptyCell = collectionView.dequeueReusableCell(for: indexPath)
            return cell
        default:
            fatalError()
        }
    }
}


// MARK: - UICollectionViewDelegate
extension NFTTokensStatusView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let element = items[indexPath.section].items[indexPath.item]
        
        switch element {
        case .token(let item):
            delegate?.didTap(from: self, with: item)
        default:
            break
        }
    }
}


// MARK: - UICollectionViewDelegateFlowLayout
extension NFTTokensStatusView: UICollectionViewDelegateFlowLayout {
    
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
       
        let element = items[indexPath.section]

        var contentHeight: CGFloat = 0.0
        switch element.header {
        case .header:
            contentHeight =  NFTDataReusableView.height()
        case .noHeader:
            contentHeight = 0.0
        }
        
        switch element.items[indexPath.item] {
            
        case .token:
            let cvWidth = collectionView.bounds.width
            let itemsSpacing = CGFloat(8)
            let countSpacing: CGFloat = 18
            
            let cellWidth: CGFloat = (cvWidth - countSpacing * itemsInLine - itemsSpacing) / CGFloat(itemsInLine)
            
            let cellHeight: CGFloat = cellWidth + 66
            let size = CGSize(width: cellWidth, height: cellHeight )
            return size
            
        case .noItems:
            let width = collectionView.frame.width
            let height = collectionView.frame.height - (contentHeight * 2.0)
            return CGSize(width: width, height: height)
        default:
            return .zero
        }
        
    }
    
    var itemsInLine: CGFloat {
        return 2
    }
}


// MARK: - instantie
extension NFTTokensStatusView {
    
    class func instantie(delegate: NFTTokensStatusViewDelegate? = nil) -> NFTTokensStatusView {
        let view =  NFTTokensStatusView.loadFromNib()
        view.delegate = delegate
        return view
    }
}
