//
//  NFTItemsStatusView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 31.10.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


protocol NFTItemsStatusViewDelegate: AnyObject {
    
    func didTap(from: NFTItemsStatusView, with model: NFTMarketplaceViewModel)
    func didTap(from: NFTItemsStatusView, with model: NFTWalletViewModel)
    func delete(from: NFTItemsStatusView, with model: NFTMarketplaceViewModel)

}


class NFTItemsStatusView: UIView, NibLoadable {
    typealias Section = NFTProviders.Section
    
    var delegate: NFTItemsStatusViewDelegate?
    
    private var items: [Section] = []
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet { setup() }
    }
}


extension NFTItemsStatusView {
    
    private func setup() {
        tableView.alwaysBounceVertical = true
        tableView.isScrollEnabled = true
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(cellType: NFTMarketplaceCell.self)
        tableView.register(cellType: NFTWalletCell.self)
        tableView.register(cellType: NFTProviderEmptyCell.self)
       	
        tableView.register(viewType: NFTProviderHeaderView.self)
    }
    
    func setup(refreshControl: UIRefreshControl) {
        tableView.refreshControl = refreshControl
    }
    
    func update(with items: [Section]) {
        self.items = items
        tableView.reloadData()
    }
}


// MARK: - UITableViewDataSource

extension NFTItemsStatusView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let section = items[section]
        switch section.header {
        case .noHeader:
            return nil
        case .header:
            let view: NFTProviderHeaderView = tableView.dequeueReusableHeaderFooterView(viewType: NFTProviderHeaderView.self)
            return view
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section].items[indexPath.item]
        switch item {
        case .marketplace(let model):
            let cell: NFTMarketplaceCell = tableView.dequeueReusableCell(for: indexPath)
            cell.model = model
            cell.selectionStyle = .none
			return cell
        case .wallet(let model):
            let cell: NFTWalletCell = tableView.dequeueReusableCell(for: indexPath)
            cell.model = model
            cell.selectionStyle = .none
            return cell
        case .token:
            fatalError()
        case .noItems:
            let cell: NFTProviderEmptyCell = tableView.dequeueReusableCell(for: indexPath)
            cell.selectionStyle = .none
            return cell
        }
    }
}


// MARK: - UITableViewDelegate
extension NFTItemsStatusView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = items[section]
        switch section.header {
        case .noHeader:
            return 0.0
        case .header:
            return NFTProviderHeaderView.height
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let item = items[indexPath.section].items[indexPath.item]
        switch item {
        case .marketplace(let model):
            delegate?.didTap(from: self, with: model)
        case .wallet(let model):
            delegate?.didTap(from: self, with: model)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item = items[indexPath.section].items[indexPath.item]
        switch item {
        case .marketplace:
            return true
        default:
            return false
        }
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = items[indexPath.section].items[indexPath.item]
        switch item {
        case .marketplace(let model):
            if editingStyle == .delete {
                
                var target: [Section] = []
                for section in items {
                    var sectionItems = section.items
                    sectionItems.remove(at: indexPath.row)
                    target.append(Section(header: section.header, items: sectionItems))
                }
                
                items = target
                tableView.deleteRows(at: [indexPath], with: .fade)
                delegate?.delete(from: self, with: model)
            }
        default:
            break
        }
    }
    
}



// MARK: - instantie
extension NFTItemsStatusView {
    
    class func instantie(delegate: NFTItemsStatusViewDelegate? = nil) -> NFTItemsStatusView {
        let view =  NFTItemsStatusView.loadFromNib()
        view.delegate = delegate
        return view
    }
}
