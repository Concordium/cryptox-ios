//
//  AccountsViewController.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 02.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import Combine
import MessageUI
import UIKit

class AccountsFactory {
    class func create(with presenter: AccountsPresenter) -> AccountsViewController {
        AccountsViewController.instantiate(fromStoryboard: "Account") { coder in
            return AccountsViewController(coder: coder, presenter: presenter)
        }
    }
}

class AccountsViewController: BaseViewController, Storyboarded, AccountsViewProtocol, ShowToast, SupportMail, ShowIdentityFailure {
    var presenter: AccountsPresenterProtocol?
    private weak var updateTimer: Timer?
    
    // Labels
    @IBOutlet weak var tableView: UITableView!
    var dataSource: UITableViewDiffableDataSource<String, AccountViewModel>?

    private var cancellables = Set<AnyCancellable>()

    @IBOutlet weak var warningMessageView: RoundedCornerView!
    @IBOutlet weak var warningMessageLabel: UILabel!
    @IBOutlet weak var warningMessageImageView: UIImageView!
    @IBOutlet weak var warningDismissButton: UIButton!

    @IBOutlet weak var newIdentityMessageLabel: UILabel!
    @IBOutlet weak var noAccountsMessageLabel: UILabel!
    @IBOutlet weak var createNewButton: StandardButton!
    @IBOutlet weak var totalBalanceLabel: UILabel!
    @IBOutlet weak var lockView: UIView!
    @IBOutlet weak var atDisposalLockImageView: UIImageView!
    @IBOutlet weak var atDisposalLabel: UILabel!
    @IBOutlet weak var stakedLabel: UILabel!

    @IBOutlet weak var balanceViewWarningTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var balanceViewTopConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var backupLegacyAccountView: RoundedCornerView!
    @IBOutlet weak var backupLegacyAccountViewLabel: UILabel!
    
    private lazy var qrScanerBarButton: UIBarButtonItem = {
        let closeIcon = UIImage(named: "qr")
        return  UIBarButtonItem(image: closeIcon, style: .plain, target: self, action: #selector(self.qrScanerTapped))
    }()

    init?(coder: NSCoder, presenter: AccountsPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        title = "accounts_tab_title".localized

        presenter?.view = self
        presenter?.viewDidLoad()

        dataSource = UITableViewDiffableDataSource<String, AccountViewModel>(tableView: tableView, cellProvider: createCell)

//        tableView.layer.masksToBounds = false
        tableView.backgroundColor = .clear
        dataSource?.defaultRowAnimation = .none
        tableView.backgroundColor = .clear
        tableView.backgroundView?.backgroundColor = .clear
        tableView.contentInset = .init(top: 0, left: 0, bottom: 54, right: 0)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl

//        warningMessageView.applyConcordiumEdgeStyle(color: .yellowBorder)
        warningMessageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didPressWarning)))
        backupLegacyAccountView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backupPresed)))
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "button_slider_settings"),
//                                                           style: .plain, target: self, action: #selector(self.settingsTapped))
        
//        view.backgroundColor = .yellow
        
        navigationItem.leftBarButtonItem = qrScanerBarButton
        
        backupLegacyAccountViewLabel.text = "Please make a backup of your wallet"
        
        Tracker.track(view: ["Home screen"])
    }

    @objc func backupPresed() {
        presenter?.userSelectedMakeBackup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
        startRefreshTimer()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter?.viewDidAppear()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAccounts(_:)), name:     Notification.Name("seedAccountCoordinatorWasFinishedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAccounts(_:)), name:     Notification.Name("seedIdentityCoordinatorWasFinishedNotification"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRefreshTimer()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("seedAccountCoordinatorWasFinishedNotification"), object: nil)
    }
    
    @objc func qrScanerTapped() {
        presenter?.scanQR()
    }

    @objc private func didPressWarning() {
        HapticFeedbackHelper.generate(feedback: .light)
        presenter?.userPressedWarning()
    }

    @objc func appDidBecomeActive() {
        presenter?.refresh(pendingIdentity: nil)
        startRefreshTimer()
    }
    
    @objc func appWillResignActive() {
        stopRefreshTimer()
    }
    
    @objc func refresh(_ sender: AnyObject) {
        presenter?.refresh(pendingIdentity: nil)
        tableView.refreshControl?.endRefreshing()
    }
    
    @objc func refreshAccounts(_ notification: NSNotification) {
        if let identity = notification.userInfo?["identity"] as? IdentityDataType {
            presenter?.refresh(pendingIdentity: identity.state == .pending ? identity : nil)
        }
    }
    
    func reloadView() {
        tableView.reloadData()
    }

    func startRefreshTimer() {
        updateTimer = Timer.scheduledTimer(timeInterval: 5.0,
                                           target: self,
                                           selector: #selector(refreshOnTimerCallback),
                                           userInfo: nil,
                                           repeats: true)
    }
    
    func stopRefreshTimer() {
        if updateTimer != nil {
            updateTimer?.invalidate()
            updateTimer = nil
        }
    }
    
    @objc func refreshOnTimerCallback() {
        presenter?.refresh(pendingIdentity: nil)
    }
    
    private func createCell(tableView: UITableView, indexPath: IndexPath, viewModel: AccountViewModel) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath) as? AccountCell
        
        cell?.setup(accountViewModel: viewModel)
        cell?.delegate = self
        cell?.cellRow = indexPath.section
        return cell
    }
    
    // swiftlint:disable:next function_body_length
    func bind(to viewModel: AccountsListViewModel) {
        viewModel.$viewState.sink {
            self.setupUI(state: $0)
        }.store(in: &cancellables)

        viewModel.$accounts
            .receive(on: RunLoop.main)
            .sink {
                var snapshot = NSDiffableDataSourceSnapshot<String, AccountViewModel>()
                
                for account in $0 {
                    snapshot.appendSections([account.address])
                    snapshot.appendItems([account], toSection: account.address)
                }
                
                if $0.count > 0 {
                    self.dataSource?.apply(snapshot)
                }
                
                let offset = self.tableView.contentOffset
                self.tableView.reloadData()
                self.tableView.contentOffset = offset
                
        }.store(in: &cancellables)
        
        viewModel.$totalBalance
                .map { $0.displayValue() }
                .assign(to: \.text, on: totalBalanceLabel)
                .store(in: &cancellables)
        
        viewModel.$staked
            .map { $0.displayValue() }
            .assign(to: \.text, on: stakedLabel)
            .store(in: &cancellables)
        
        viewModel.$atDisposal
            .map {
                if viewModel.totalBalanceLockStatus != ShieldedAccountEncryptionStatus.decrypted {
                    return $0.displayValue() + " + "
                } else {
                    return $0.displayValue()
                }
        }.assign(to: \.text, on: atDisposalLabel)
            .store(in: &cancellables)
        
        viewModel.$totalBalanceLockStatus
            .map { $0 == ShieldedAccountEncryptionStatus.decrypted }
            .assign(to: \.isHidden, on: atDisposalLockImageView)
            .store(in: &cancellables)
        
        viewModel.$totalBalanceLockStatus
            .map { $0 == ShieldedAccountEncryptionStatus.decrypted }
        .assign(to: \.isHidden, on: lockView)
        .store(in: &cancellables)
        
        viewModel.$warning.sink { [weak self] warning in
            guard let self = self else { return }
            if let warning = warning {
                self.warningMessageLabel.text = warning.text
                self.warningMessageImageView.image = UIImage(named: warning.imageName)
                self.warningDismissButton.isHidden = !warning.dismissable
                self.warningMessageView.applyConcordiumEdgeStyle(color: .primary)
            }
        }.store(in: &cancellables)
        
        viewModel.$isExportDataBannerShown.sink { [weak self] isShown in
            self?.backupLegacyAccountView.isHidden = !isShown
        }.store(in: &cancellables)
    }
    
    func showIdentityFailed(identityProviderName: String,
                            identityProviderSupport: String,
                            reference: String,
                            completion: @escaping (_ option: IdentityFailureAlertOption) -> Void) {
        showIdentityFailureAlert(identityProviderName: identityProviderName,
                                 identityProviderSupportEmail: identityProviderSupport,
                                 reference: reference,
                                 completion: completion)
    }
    
    func setupUI(state: AccountsUIState) {
        var shouldShowAddAccountButtonInTopBar = false
        switch state {
        case .newIdentity:
            tableView.isHidden = true
            createNewButton.setTitle("accounts.createNewIdentity".localized, for: .normal)
            newIdentityMessageLabel.isHidden = false
            noAccountsMessageLabel.isHidden = false
            createNewButton.isHidden = false
        case .newAccount:
            tableView.isHidden = true
            newIdentityMessageLabel.isHidden = true
            noAccountsMessageLabel.isHidden = false
            createNewButton.isHidden = false
            createNewButton.setTitle("accounts.createNewAccount".localized, for: .normal)
            shouldShowAddAccountButtonInTopBar = true
        case .showAccounts:
            tableView.isHidden = false
            newIdentityMessageLabel.isHidden = true
            noAccountsMessageLabel.isHidden = true
            createNewButton.isHidden = true
            shouldShowAddAccountButtonInTopBar = true
        }
        if shouldShowAddAccountButtonInTopBar {
            let rightButtonImage = UIImage(named: "add")
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightButtonImage,
                                                                style: .plain,
                                                                target: self, action: #selector(createNewButtonPressed))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @IBAction func createNewButtonPressed(_ sender: Any) {
        presenter?.userPressedCreate()
    }

    @IBAction func dismissWarning(_ sender: Any) {
        presenter?.userPressedDisimissWarning()
    }
    
    private func showBackupWarningBanner(_ show: Bool) {
        let duration: TimeInterval = 0.25

        if show {
            UIView.animate(withDuration: duration, animations: {  [weak self] in
                self?.balanceViewTopConstraint.isActive = false
                self?.balanceViewWarningTopConstraint.isActive = true
                self?.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                self?.warningMessageView.isHidden = false
            })
        } else {
            UIView.animate(withDuration: duration, animations: { [weak self] in
                self?.warningMessageView.isHidden = true
                self?.balanceViewTopConstraint.isActive = true
                self?.balanceViewWarningTopConstraint.isActive = false
                self?.view.layoutIfNeeded()
            })
        }
    }
}

extension AccountsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}

extension AccountsViewController: AccountCellDelegate {
    func perform(onCellRow: Int, action: AccountCardAction) {
        presenter?.userPerformed(action: action, on: onCellRow)
    }
}

extension AccountsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true)
    }
}
