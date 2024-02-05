//
//  AirDropWalletsView.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 06.11.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


protocol AirDropWalletsViewDelegate: AnyObject {
    
    func cancel(from: AirDropWalletsView)
    func connect(from: AirDropWalletsView)
    func didTap(from: AirDropWalletsView, with model: AccountDataType)
}


class AirDropWalletsView: UIView, NibLoadable {
    
    private weak var delegate: AirDropWalletsViewDelegate? = nil
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var calcelButton: UIButton!
    @IBOutlet private weak var connectButton: UIButton!
    
    private var selectedAcc: AccountDataType?
    var accs: [AccountDataType] = [] {
        didSet {
            selectedAcc = accs.first
            tableView.reloadData()
        }
    }
}


// MARK: – Setup
extension AirDropWalletsView {
    
    func setup() {
        calcelButton.layer.cornerRadius = 26
        connectButton.layer.cornerRadius = 26
        
        calcelButton.layer.borderWidth = 1
        calcelButton.layer.borderColor = UIColor(red: 0.831, green: 0.839, blue: 0.863, alpha: 1).cgColor
        
        tableView.register(cellType: AirDropWalletCell.self)
        
        tableView.dataSource = self
        tableView.delegate = self
    }
}

// MARK: – Actions
extension AirDropWalletsView {
    
    @IBAction func didTapCancel() {
        delegate?.cancel(from: self)
    }
    
    @IBAction func didTapConnect() {
        delegate?.connect(from: self)
    }
}


// MARK: – UITableViewDataSource
extension AirDropWalletsView: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let count = self.accs.count
        return count == 0 ? 0 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.accs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AirDropWalletCell = tableView.dequeueReusableCell(for: indexPath)
        cell.selectionStyle = .none
        let account = accs[indexPath.row]
        cell.setup(account: account)
        
        if let address = selectedAcc?.address , account.address == address {
            cell.backView.backgroundColor = UIColor.greyAdditional.withAlphaComponent(0.2)
        }
                
        return cell
    }
}


// MARK: – UITableViewDelegate
extension AirDropWalletsView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAcc = accs[indexPath.row]
        tableView.reloadData()
        guard let selected = selectedAcc else { return }
        delegate?.didTap(from: self, with: selected)
    }
}

    
// MARK: - instantie
extension AirDropWalletsView {
    
    class func instantie(delegate :AirDropWalletsViewDelegate? = nil) -> AirDropWalletsView {
        let view =  AirDropWalletsView.loadFromNib()
        view.delegate = delegate
        view.setup()
        return view
    }
}
