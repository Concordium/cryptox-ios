//
//  SelectRecipientViewController.swift
//  ConcordiumWallet
//
//  Created by Concordium on 4/7/20.
//  Copyright © 2020 concordium. All rights reserved.
//

import UIKit
import Combine

class SelectRecipientFactory {
    class func create(with presenter: SelectRecipientPresenter) -> SelectRecipientViewController {
        SelectRecipientViewController.instantiate(fromStoryboard: "SendFund") {coder in
            return SelectRecipientViewController(coder: coder, presenter: presenter)
        }
    }
}

class SelectRecipientViewController: BaseViewController, SelectRecipientViewProtocol, Storyboarded {
    
    var presenter: SelectRecipientPresenterProtocol

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: RecipientDiffibleDataSource?
    
    private var cancellables: [AnyCancellable] = []
    
    init?(coder: NSCoder, presenter: SelectRecipientPresenterProtocol) {
        self.presenter = presenter
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        presenter.viewWillAppear()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove border of search field to match design
        let searchField = searchBar.searchTextField
        searchField.borderStyle = .none

        searchBar.placeholder = "selectRecipient.searchRecipients".localized
        
        let rightButtonImage = UIImage(named: "add")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightButtonImage,
                style: .plain,
                target: self, action: #selector(createRecipientTapped))

        dataSource = RecipientDiffibleDataSource(tableView: tableView, cellProvider: createCell)
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.clipsToBounds = true
        tableView.layer.masksToBounds = true
        tableView.layer.cornerRadius = 24
        
        searchBar.searchTextField.textPublisher.receive(on: DispatchQueue.main)
            .sink(receiveValue: { (value) in
                self.presenter.searchTextDidChange(newValue: value)
            })
            .store(in: &cancellables)
        
        presenter.view = self
        presenter.viewDidLoad()
    }
    
    func bind(to viewModel: RecipientListViewModel) {
//        viewModel.$recipients.sink {
//            var snapshot = NSDiffableDataSourceSnapshot<String, RecipientViewModel>()
//            snapshot.appendSections(["me", "others"])
////            snapshot.appendItems($0, toSection: "others")
//            self.dataSource?.apply(snapshot)
//            self.tableView.reloadData()
//        }.store(in: &cancellables)
        
        viewModel.$mode.sink {
            self.dataSource?.mode = $0
            switch $0 {
            case .selectRecipientFromPublic:
                self.title = "selectRecipient.title".localized
            case .addressBook:
                self.title = "more.addressBook".localized
            }
        }.store(in: &cancellables)
        
    }
}

extension SelectRecipientViewController {
    @IBAction func scanQRTapped(_ sender: Any) {
        presenter.scanQrTapped()
    }
    
    @objc func createRecipientTapped() {
        presenter.createRecipient()
    }
    
    private func createCell(tableView: UITableView, indexPath: IndexPath, viewModel: RecipientViewModel) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipientViewCell", for: indexPath)
        cell.textLabel?.text = viewModel.name
        cell.detailTextLabel?.text = viewModel.address
        return cell
    }
}

extension SelectRecipientViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
        } else {
            presenter.userSelectRecipient(with: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "", handler: { _, _, _  in
            if let recipient = self.dataSource?.itemIdentifier(for: indexPath) {
                self.presenter.userDelete(recipientVM: recipient)
            }
        })

        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

class RecipientDiffibleDataSource: UITableViewDiffableDataSource<String, RecipientViewModel> {
    
    var mode: SelectRecipientMode?
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch mode! {
            case .addressBook:
                return true
            case .selectRecipientFromPublic:
                return false
        }
    }
}
