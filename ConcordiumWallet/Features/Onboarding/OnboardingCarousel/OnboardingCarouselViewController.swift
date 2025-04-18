//
//  OnboardingCarouselViewController.swift
//  ConcordiumWallet
//
//  Created by Kristiyan Dobrev on 08/02/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import UIKit

final class OnboardingCarouselFactory {
    class func create(with presenter: OnboardingCarouselPresenterProtocol) -> OnboardingCarouselViewController {
        OnboardingCarouselViewController.instantiate(fromStoryboard: "Onboarding") { coder in
            return OnboardingCarouselViewController(coder: coder, presenter: presenter)
        }
    }
}

final class OnboardingCarouselViewController: BaseViewController, OnboardingCarouselViewProtocol, Storyboarded {

    var presenter: OnboardingCarouselPresenterProtocol

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var nextButton: StandardButton!
    @IBOutlet weak var skipButton: StandardButton!
    @IBOutlet weak var backButton: StandardButton!
    @IBOutlet weak var continueButton: UIButton!

    private var pageTitles = [String]()

    var onboardingCarouselPageViewController: OnboardingCarouselPageViewController?

    init?(coder: NSCoder, presenter: OnboardingCarouselPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.destination {
        case let pageViewController as OnboardingCarouselPageViewController:
            onboardingCarouselPageViewController = pageViewController
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.view = self
        presenter.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "ico_close"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )

        titleLabel.text = pageTitles.first

        nextButton.setTitle("onboardingcarousel.button.next.text".localized, for: .normal)
        backButton.setTitle("onboardingcarousel.button.back.text".localized, for: .normal)
        skipButton.setTitle("onboardingcarousel.button.skip.text".localized, for: .normal)
        continueButton.setTitle("onboardingcarousel.button.continue.text".localized, for: .normal)

        skipButton.setTitleColor(UIColor.white, for: .normal)
        skipButton.backgroundColor = .clear
        skipButton.layer.borderWidth = 2
        skipButton.layer.borderColor = UIColor.white.cgColor

        pageControl.numberOfPages = onboardingCarouselPageViewController?.orderedViewControllers.count ?? 0
        pageControl.currentPage = 0

        onboardingCarouselPageViewController?.controllerDelegate = self

        // If we only have one page we need to show the continue button
        let showContinue = pageControl.numberOfPages <= 1
        
        continueButton.alpha = showContinue ? 1 : 0
        nextButton.alpha = showContinue ? 0 : 1
        backButton.alpha = 0
    }

    func bind(to viewModel: OnboardingCarouselViewModel) {
        pageTitles = viewModel.pages.map { $0.title }
        onboardingCarouselPageViewController?.setup(with: viewModel.pages.map { $0.viewController })
        title = viewModel.title
        // Only show the skip button if there are more than 1 page
        skipButton.alpha = viewModel.pages.count > 1 ? 1 : 0
    }

    @objc private func closeButtonTapped() {
        presenter.userTappedClose()
    }

    @IBAction func continueButtonTapped(_ sender: Any) {
        presenter.userTappedContinue()
    }

    @IBAction func nextButtonTapped(_ sender: Any) {
        onboardingCarouselPageViewController?.goToNextPage()
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        onboardingCarouselPageViewController?.goToPreviousPage()
    }

    @IBAction func skipButtonTapped(_ sender: Any) {
        presenter.userTappedSkip()
    }
}

// MARK: - OnboardingCarouselPageViewControllerDelegate

extension OnboardingCarouselViewController: OnboardingCarouselPageViewControllerDelegate {
    func didChangePage(_ index: Int) {
        pageControl.currentPage = index

        let showBackButton = index > 0
        let showContinueButton = (index + 1) == pageControl.numberOfPages

        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.backButton.alpha = showBackButton ? 1 : 0
            self?.skipButton.alpha = showBackButton ? 0 : 1
            self?.continueButton.alpha = showContinueButton ? 1 : 0
            self?.nextButton.alpha = showContinueButton ? 0 : 1
            self?.titleLabel.text = self?.pageTitles[index]
        }
    }
}
