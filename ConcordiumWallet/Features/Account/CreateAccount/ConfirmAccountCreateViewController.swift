//
//  RevealAttributesViewController.swift
//  ConcordiumWallet
//
//  Concordium on 17/11/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit

class RevealAttributesFactory {
    class func create(with presenter: ConfirmAccountCreatePresenter) -> ConfirmAccountCreateViewController {
        ConfirmAccountCreateViewController.instantiate(fromStoryboard: "Account") { coder in
            return ConfirmAccountCreateViewController(coder: coder, presenter: presenter)
        }
    }
}

class ConfirmAccountCreateViewController: BaseViewController, RevealAttributesViewProtocol, Storyboarded {

    @IBOutlet weak var identityCard: IdentityCardView!
    
    var presenter: RevealAttributesPresenterProtocol

    init?(coder: NSCoder, presenter: RevealAttributesPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addIcon = UIImage(named: "ico_close")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: addIcon, style: .plain, target: self, action: #selector(self.closeButtonTapped))
        
        presenter.view = self
        presenter.viewDidLoad()
    }
    
    @IBAction func finishAction(_ sender: Any) {
        presenter.finish()
    }
    
    @objc func closeButtonTapped() {
        presenter.closeButtonPressed()
    }
    
    func bindData(model: IdentityInfoViewModel) {
        identityCard.titleLabel?.text = model.nickname
        identityCard.expirationDateLabel?.text = model.expiresOn
        identityCard.iconImageView?.image = UIImage.decodeBase64(toImage: model.iconEncoded)
    }
}
