//
//  MoreMenuViewController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 24/04/2020.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit

// For future use, other cell types will be added
enum MenuCell: Hashable {
    case identities(title: String)
    case addressBook(title: String)
    case update(title: String)
    case recovery(title: String)
    case analytics(title: String)
    case about(title: String)
    
    case export(title: String) // for backward compatibility with legacy wallet
    case `import`(title: String) // for backward compatibility with legacy wallet
    
    case deleteAccount(title: String)
    
    case revealSeedPhrase(title: String)
    case unshieldAssets(title: String)
    
    var title: String {
        switch self {
            case .identities(let title),
                    .addressBook(let title),
                    .update(let title),
                    .recovery(let title),
                    .analytics(let title),
                    .about(let title),
                    .import(let title),
                    .export(let title),
                    .deleteAccount(let title),
                    .unshieldAssets(let title),
                    .revealSeedPhrase(let title):
                return title
        }
    }
    
    var image: UIImage? {
        switch self {
            case .identities:
                return UIImage(named: "more_identity")
            case .addressBook:
                return UIImage(named: "more_address_book")
            case .update:
                return UIImage(named: "more_biometric")
            case .recovery:
                return UIImage(named: "more_recovery")
        case .analytics:
            return UIImage(named: "more_analytics")
            case .about:
                return UIImage(named: "more_info")
            case .export:
                return UIImage(named: "more_export")
            case .import:
                return UIImage(named: "more_import")
            case .deleteAccount:
                return UIImage(systemName: "rectangle.portrait.and.arrow.right")
            case .revealSeedPhrase:
                return UIImage(systemName: "eye")
            case .unshieldAssets:
                return UIImage(systemName: "shield.slash")
        }
    }
    
    var color: UIColor {
        switch self {
            case .deleteAccount: return .systemRed
            default: return .white
        }
    }
}

class MoreMenuFactory {
    class func create(with presenter: MoreMenuPresenter) -> MoreMenuViewController {
        MoreMenuViewController.instantiate(fromStoryboard: "More") { coder in
            return MoreMenuViewController(coder: coder, presenter: presenter)
        }
    }
}

class MoreMenuViewController: BaseViewController, MoreMenuViewProtocol, Storyboarded {
    typealias MoreMenuDataSource = UITableViewDiffableDataSource<SingleSection, MenuCell>
    var presenter: MoreMenuPresenterProtocol

    @IBOutlet weak var tableView: UITableView!
    var dataSource: MoreMenuDataSource?

    init?(coder: NSCoder, presenter: MoreMenuPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.view = self
        presenter.viewDidLoad()

        title = "more_tab_title".localized

        tableView.tableFooterView = UIView(frame: .zero)

        dataSource = MoreMenuDataSource(tableView: tableView, cellProvider: createCell)
        setupUI()

        #if MOCK
        MockedData.addMockButton(in: self)
        #endif
    }
}

extension MoreMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let moreMenuDataSource = tableView.dataSource as? MoreMenuDataSource else {
            return
        }
        let menuCell = moreMenuDataSource.snapshot().itemIdentifiers[indexPath.row]
        switch menuCell {
            case .identities:
                presenter.userSelectedIdentities()
            case .addressBook:
                presenter.userSelectedAddressBook()
            case .update:
                presenter.userSelectedUpdate()
            case .recovery:
                Task { await presenter.userSelectedRecovery() }
            case .analytics:
                presenter.userSelectedAnalytics()
            case .about:
                presenter.userSelectedAbout()
            case .export:
                presenter.userSelectedExport()
            case .import:
                presenter.userSelectedImport()
            case .deleteAccount:
                presenter.logout()
            case .revealSeedPhrase:
                presenter.showRevealSeedPrase()
            case .unshieldAssets:
                presenter.showUnshieldAssetsFlow()
        }
    }
}

extension MoreMenuViewController {
    private func setupUI() {
        var snapshot = NSDiffableDataSourceSnapshot<SingleSection, MenuCell>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.unshieldAssets(title: "more.funds.to.unshield".localized)])
        snapshot.appendItems([.identities(title: "more.identities".localized)])
        snapshot.appendItems([.addressBook(title: "more.addressBook".localized)])
        snapshot.appendItems([.update(title: "more.update".localized)])
        snapshot.appendItems([.about(title: "more.about".localized)])
        if presenter.isLegacyAccount() {
            snapshot.appendItems([.import(title: "more.import".localized)])
            snapshot.appendItems([.export(title: "more.export".localized)])
        } else {
            if presenter.hasSavedSeedPhrase() {
                snapshot.appendItems([.revealSeedPhrase(title: "more.reveal.seed.phrase".localized)])
            }
            snapshot.appendItems([.recovery(title: "more.recovery".localized)])
        }
        
        snapshot.appendItems([.analytics(title: "more.analytics".localized)])
        snapshot.appendItems([.deleteAccount(title: "more.deleteAccount".localized)])
        DispatchQueue.main.async {
            self.dataSource?.apply(snapshot)
        }
    }

    private func createCell(tableView: UITableView, indexPath: IndexPath, viewModel: MenuCell) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemCellView", for: indexPath) as! MenuItemCellView
        cell.bind(viewModel: viewModel)
        return cell
    }
}
