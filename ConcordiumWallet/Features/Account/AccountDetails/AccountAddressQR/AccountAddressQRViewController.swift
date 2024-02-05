//
//  AccountAddressQRViewController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 15/04/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import Combine

class AccountAddressQRFactory {
    class func create(with presenter: AccountAddressQRPresenter) -> AccountAddressQRViewController {
        AccountAddressQRViewController.instantiate(fromStoryboard: "Account") {coder in
            return AccountAddressQRViewController(coder: coder, presenter: presenter)
        }
    }
}

class AccountAddressQRViewController: BaseViewController, Storyboarded, ShowToast {

	var presenter: AccountAddressQRPresenterProtocol
    private var cancellables: [AnyCancellable] = []

    @IBOutlet weak var qrView: UIImageView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var accountNameLabel: UILabel!
    
    @IBOutlet weak var shareButton: XButton!
    @IBOutlet weak var copyButton: XButton!
    
    init?(coder: NSCoder, presenter: AccountAddressQRPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        shareButton.applyStyle(.whiteStrokePill)
        copyButton.applyStyle(.whiteStrokePill)

        presenter.view = self
        presenter.viewDidLoad()
        self.title = "accountAddress.title".localized
        showCloseButton()
    }

    func showCloseButton() {
        let closeIcon = UIImage(named: "ico_close")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.closeButtonTapped))
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true)
//        presenter.closeButtonTapped()
    }

    @IBAction func shareButtonTapped(_ sender: Any) {
        presenter.shareButtonTapped()
    }

    @IBAction func copyButtonTapped(_ sender: Any) {
        presenter.copyButtonTapped()
        showToast(withMessage: "accountAddress.toast.addressCopied".localized)
    }

    func showQRCode(for address: String) {
        guard let image = generateCode(address, foregroundColor: .black, backgroundColor: .clear) else { return }
        qrView.image = image
        qrView.tintColor = .black
        qrView.backgroundColor = .clear
    }

    func generateCode(_ string: String, foregroundColor: UIColor = .white, backgroundColor: UIColor = .black) -> UIImage? {
        guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }

        let transform = CGAffineTransform.init(scaleX: 10, y: 10)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        let transformed = filter?.outputImage?.transformed(by: transform)

        let invertFilter = CIFilter(name: "CIColorInvert")
        invertFilter?.setValue(transformed, forKey: kCIInputImageKey)
        let inverted = invertFilter?.outputImage

        let alphaFilter = CIFilter(name: "CIMaskToAlpha")
        alphaFilter?.setValue(inverted, forKey: kCIInputImageKey)

        if let outputImage = alphaFilter?.outputImage {
            return UIImage(ciImage: outputImage)
                    .withRenderingMode(.alwaysTemplate)
        }
        return nil
    }
}

extension AccountAddressQRViewController: AccountAddressQRViewProtocol {
    func bind(to viewModel: AccountAddressViewModel) {
        viewModel.$accountAddress.sink(receiveValue: {value in
            self.showQRCode(for: value)
            self.addressLabel.text = value
        }).store(in: &cancellables)
        viewModel.$accountName.map {"\($0):"}
            .assignNoRetain(to: \.text, on: accountNameLabel)
            .store(in: &cancellables)
    }
}
