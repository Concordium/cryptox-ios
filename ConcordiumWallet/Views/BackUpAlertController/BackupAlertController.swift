//
//  BackupAlertController.swift
//  ConcordiumWallet
//
//  Created by Maxim Liashenko on 25.01.2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit


class BackupAlertFactory {
    class func create(delegate: BackupAlertControllerDelegate) -> BackupAlertController {
        BackupAlertController.instantiate(fromStoryboard: "Account") { coder in
            return BackupAlertController(coder: coder, delegate: delegate)
        }
    }
}

protocol BackupAlertControllerDelegate: AnyObject {
    func didApplyBackupOk()
}

enum BackupAlertMode {
    case export
    case remove
    
    var title: String {
        switch self {
        case .export:
            return "backupwarning.title".localized
        case .remove:
            return "backupwarning.remove.title".localized
        }
    }
    
    var message: String {
        switch self {
        case .export:
            return "backupwarning.message".localized
        case .remove:
            return "backupwarning.remove.message".localized
        }
    }
    
    var button: String {
        switch self {
        case .export:
            return "backupwarning.button.ok".localized
        case .remove:
            return "backupwarning.remove.button.ok".localized
        }
    }
    
    var color: UIColor {
        switch self {
        case .export:
            return UIColor.greenSecondary
        case .remove:
            return UIColor.pinkyAdditional
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .export:
            return UIImage(named: "icon-backup")
        case .remove:
            return UIImage(named: "trash_icon")
        }
    }
    

}

class BackupAlertController: UIViewController, Storyboarded {

    var mode: BackupAlertMode = .export
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var opaqueView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var okButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    private weak var delegate: BackupAlertControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        opaqueView.alpha = 0.4
        closeButton.setTitle(nil, for: .normal)
        setup(mode: mode)
    }
    
    init?(coder: NSCoder, delegate: BackupAlertControllerDelegate) {
        self.delegate = delegate
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(mode: BackupAlertMode = .export) {
        titleLabel.text = mode.title
        messageLabel.text = mode.message
        okButton.setTitle(mode.button, for: .normal)
        containerView.backgroundColor = mode.color
        iconImageView.image = mode.icon
    }
}


extension BackupAlertController {
    
    @IBAction func didTapCancal() {
        dismiss(animated: false)
    }
    
    @IBAction func didTapOk() {
      
        OperationQueue.main.addOperation( {  [weak self] in
            
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut) {
                self?.okButton.setTitleColor(UIColor.greySecondary, for: .normal)
            } completion: { _ in
                self?.okButton.isEnabled = false
            }
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut) {
                self?.containerView.alpha = 0.0
            } completion: { _ in
                self?.dismiss(animated: false, completion: {
                    self?.delegate?.didApplyBackupOk()
                })
            }
        })
    }
}
