//
//  ConnectionRequestVC.swift
//  ConcordiumWallet
//
//  Created by Alex Kudlak on 2021-08-12.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit
import Combine
import SwiftUI

enum ConnectionRequestVCType {
    case connection
    case walletSelection
}

class ConnectionRequestVC: UIViewController, Storyboarded {
    @IBOutlet private weak var calcelButton: UIButton!
    @IBOutlet private weak var connectButton: UIButton!
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var redDotView: UIView!
    @IBOutlet private weak var tv: UITableView!
    @IBOutlet private weak var actionTitleLabel: UILabel!
    
    @ObservedObject var service = WebSocketService()
    var connectionData: QRDataResponse?
    var accs: [AccountDataType]?
    var dependencyProvider: AccountsFlowCoordinatorDependencyProvider?
    private var selectedAcc: AccountDataType!
    var status: ConnectionRequestVCType = .connection
    
    override func viewDidLoad() {
        super.viewDidLoad()

        service.dependencyProvider = dependencyProvider
        service.connectionData = connectionData
        service.connect(url: connectionData?.ws_conn ?? "")
        selectedAcc = self.accs?.first
        service.accs = accs
        setupUI()
    }
    
    private func setupUI() {
        if status == .walletSelection {
            tv.isHidden = false
            actionTitleLabel.text = "Add Wallet"
        }
        calcelButton.layer.cornerRadius = 26
        connectButton.layer.cornerRadius = 26
        redDotView.layer.cornerRadius = 2.5
        
        calcelButton.layer.borderWidth = 1
        calcelButton.layer.borderColor = UIColor(red: 0.831, green: 0.839, blue: 0.863, alpha: 1).cgColor
        
        titleLabel.text = connectionData?.site.title
        descriptionLabel.text = connectionData?.site.description
        if let urlStr = connectionData?.site.icon_link, let url = URL(string: urlStr) {
            imgView.tintColor = UIColor.greyAdditional
            imgView.load(url: url, renderingMode: .alwaysTemplate)
        }
    }
    
    @IBAction func closeVC(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func cancellAction(_ sender: UIButton) {
        service.sendRejectionMessage()
        dismiss(animated: true)
    }
    
    @IBAction func connectAction(_ sender: UIButton) {
        if status == .connection {
            service.sendMessage()
        } else {
            service.sendWallet()
        }
        dismiss(animated: true)
    }
}

extension ConnectionRequestVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.accs?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AccountTransactionTVCell", for: indexPath) as? AccountTransactionTVCell else { return UITableViewCell() }
        
        guard let account = accs?[indexPath.row] else { return UITableViewCell() }
        cell.setup(account: account)
        
        if account.address == selectedAcc.address {
            cell.backView.backgroundColor = UIColor.greyAdditional.withAlphaComponent(0.2)
        }
        
        
        return cell
    }
}
extension ConnectionRequestVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAcc = accs?[indexPath.row]
        service.accs = [selectedAcc]
        tv.reloadData()
    }
}

class AccountTransactionTVCell: UITableViewCell {
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var hashLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var backView: UIView!
    
    override func prepareForReuse() {
        backView.backgroundColor = UIColor.greyAdditional.withAlphaComponent(0.1)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgView.layer.cornerRadius = 21.0
        backView.layer.cornerRadius = 24.0
        layer.cornerRadius = 24.0
    }
    
    func setup(account: AccountDataType) {
        hashLabel.text = "\(account.displayName) (\(account.address))"
        balanceLabel.text = "Balance: " + GTU(intValue: account.forecastBalance).displayValue() + " CCD"
        
        if let iconEncoded = account.identity?.identityProvider?.icon {
            imgView.image = UIImage.decodeBase64(toImage: iconEncoded)
        }

    }
}

extension UIImageView {
    func load(url: URL, renderingMode:  UIImage.RenderingMode = .automatic) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        let tintableImage = image.withRenderingMode(renderingMode)
                        self?.image = tintableImage
                    }
                }
            }
        }
    }
}
