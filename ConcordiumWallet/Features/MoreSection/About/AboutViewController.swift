//
//  AboutViewController.swift
//  Mock
//
//  Created by Concordium on 18/02/2021.
//  Copyright © 2021 concordium. All rights reserved.
//

import UIKit

class AboutFactory {
    class func create(with presenter: AboutPresenter) -> AboutViewController {
        AboutViewController.instantiate(fromStoryboard: "More") { coder in
            return AboutViewController(coder: coder, presenter: presenter)
        }
    }
}

class AboutViewController: BaseViewController, AboutViewProtocol, Storyboarded, UITextViewDelegate {
    var presenter: AboutPresenterProtocol
    
    @IBOutlet weak var supportTextView: UITextView!
    @IBOutlet weak var websiteTextView: UITextView!
    @IBOutlet weak var versionLabel: UILabel! {
        didSet {
            let version = AppSettings.appVersion
            let buildNo = AppSettings.buildNumber
#if MAINNET
            if UserDefaults.bool(forKey: "demomode.userdefaultskey".localized) == true {
                versionLabel.text = "\(version) (\(buildNo))"
            } else {
                versionLabel.text = "\(version)"
            }
#else
            versionLabel.text = "\(version) (\(buildNo))"
#endif
        }
    }
    
    @IBOutlet weak var legalInfoTextView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var privacyPolicyTextField: UITextView!
    
    @IBOutlet weak var tgImage: UIImageView!
    @IBOutlet weak var discordImage: UIImageView!
    @IBOutlet weak var xImage: UIImageView!
    
    @IBOutlet weak var tgView: UIView!
    @IBOutlet weak var xView: UIView!
    @IBOutlet weak var discordView: UIView!
    
    init?(coder: NSCoder, presenter: AboutPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "more.about".localized
        presenter.view = self
        presenter.viewDidLoad()
        
        view.backgroundColor = .blackMain
        scrollView.backgroundColor = .clear
        
        // Note the spaces since we only want to insert links at the exact match in the orginal text.
        let links = ["support@concordium.software": "mailto:support@concordium.software",
                     "concordium.com": "https://concordium.com",
                     "Privacy policy": "https://www.concordium.com/legal/privacy-policy",
                     "Terms and Conditions": "https://developer.concordium.software/en/mainnet/net/resources/terms-and-conditions-cryptox.html"]

        let supportText = "more.about.support.text".localized
        supportTextView.addHyperLinksToText(originalText: supportText, hyperLinks: links)
        supportTextView.textContainerInset = UIEdgeInsets.zero
        supportTextView.textContainer.lineFragmentPadding = 0
        supportTextView.delegate = self

        let websiteText = "more.about.website.text".localized
        websiteTextView.addHyperLinksToText(originalText: websiteText, hyperLinks: links)
        websiteTextView.textContainerInset = UIEdgeInsets.zero
        websiteTextView.textContainer.lineFragmentPadding = 0
        websiteTextView.delegate = self
        
        legalInfoTextView.addHyperLinksToText(originalText: "new_onb_terms".localized, hyperLinks: links)
        legalInfoTextView.textContainerInset = UIEdgeInsets.zero
        legalInfoTextView.textContainer.lineFragmentPadding = 0
        legalInfoTextView.delegate = self
        
        privacyPolicyTextField.addHyperLinksToText(originalText: "new_onb_privacy".localized, hyperLinks: links)
        privacyPolicyTextField.textContainerInset = UIEdgeInsets.zero
        privacyPolicyTextField.textContainer.lineFragmentPadding = 0
        privacyPolicyTextField.delegate = self
        
        tgImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(socialMediaTapped(_:))))
        xImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(socialMediaTapped(_:))))
        discordImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(socialMediaTapped(_:))))
        tgImage.isUserInteractionEnabled = true
        xImage.isUserInteractionEnabled = true
        discordImage.isUserInteractionEnabled = true
        setupSocialMediaButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith link: URL, in characterRange: NSRange) -> Bool {
        UIApplication.shared.open(link)
        return false
    }
    
    @objc func socialMediaTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else { return }
        switch tag {
        case 1:
            UIApplication.shared.open(AppConstants.SocialMedia.tg)
        case 2:
            UIApplication.shared.open(AppConstants.SocialMedia.x_twitter)
        case 3:
            UIApplication.shared.open(AppConstants.SocialMedia.discord)
        default:
            break
        }
    }
    
    private func setupSocialMediaButtons() {
        tgView.layer.cornerRadius = 12
        tgView.layer.borderWidth = 1
        tgView.layer.borderColor = UIColor.white.cgColor
        
        xView.layer.cornerRadius = 12
        xView.layer.borderWidth = 1
        xView.layer.borderColor = UIColor.white.cgColor
        
        discordView.layer.cornerRadius = 12
        discordView.layer.borderWidth = 1
        discordView.layer.borderColor = UIColor.white.cgColor
    }
}

extension UITextView {
    func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
        let font = Fonts.body
        let color = UIColor.primary
        let underline = NSUnderlineStyle.single
        
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        let attributedOriginalText = NSMutableAttributedString(attributedString: originalText.stringWithHighlightedLinks(hyperLinks))
        let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
        attributedOriginalText.addAttribute(.paragraphStyle, value: style, range: fullRange)
        attributedOriginalText.addAttribute(.font, value: font, range: fullRange)
        attributedOriginalText.addAttribute(.foregroundColor, value: UIColor.fadedText, range: fullRange)
        
        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: color,
            NSAttributedString.Key.underlineStyle: underline.rawValue
        ]
        self.attributedText = attributedOriginalText
    }
}
