//
//  SelectRecipientPresenter.swift
//  ConcordiumWallet
//
//  Created by Concordium on 4/7/20.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation
import Combine

enum SelectRecipientMode {
    case selectRecipientFromPublic
    case addressBook
}

class RecipientViewModel: Hashable {
    var name: String = ""
    var address: String = ""
    // To know the original index of the item, beause I change the list with searching
    var realIndex = 0
    var isEncrypted: Bool = false
    
    init(name: String, address: String, isEncrypted: Bool = false) {
        self.name = name
        self.address = address
        self.isEncrypted = isEncrypted
    }
    
    init(recipient: RecipientDataType, realIndex: Int, isEncrypted: Bool = false) {
        self.name = recipient.name
        self.address = recipient.address
        self.realIndex = realIndex
        self.isEncrypted = isEncrypted
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(address)
    }

    static func == (lhs: RecipientViewModel, rhs: RecipientViewModel) -> Bool {
        lhs.address == rhs.address
    }
}

class RecipientListViewModel: ObservableObject {
    @Published var recipients = [RecipientDataType]()
    @Published var mode: SelectRecipientMode = .selectRecipientFromPublic
    @Published var originalRecipientsViewModels = [RecipientViewModel]() // Full list of recipients
    @Published var filteredRecipientsViewModels = [RecipientViewModel]() // Filtered list displayed in the UI

    private var storageManager: StorageManagerProtocol
    private var ownAccount: AccountDataType?
    private var cancellables: [AnyCancellable] = []
    private var dependencyProvider = ServicesProvider.defaultProvider()
    
    init(storageManager: StorageManagerProtocol,
         mode: SelectRecipientMode,
         ownAccount: AccountDataType? = nil) {
        self.storageManager = storageManager
        self.mode = mode
        self.ownAccount = ownAccount
        
        $recipients.sink { (recipients) in
            self.originalRecipientsViewModels.removeAll()
                        
            for (index, recipient) in recipients.enumerated() {
                self.originalRecipientsViewModels.append(RecipientViewModel(recipient: recipient, realIndex: index, isEncrypted: false))
            }

            self.originalRecipientsViewModels = Array((NSOrderedSet(array: (self.originalRecipientsViewModels)).array as? [RecipientViewModel]) ?? [])
            
            // Filter out own account.
            self.originalRecipientsViewModels = self.originalRecipientsViewModels
                .filter {$0.address != ownAccount?.address}
                .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            self.filteredRecipientsViewModels = self.originalRecipientsViewModels
            
        }.store(in: &cancellables)
    }

    func refreshData() {
        recipients = storageManager.getRecipients()
    }

    func filterRecipients(searchText: String) {
        if searchText.isEmpty {
            self.filteredRecipientsViewModels = self.originalRecipientsViewModels
        } else {
            self.filteredRecipientsViewModels = originalRecipientsViewModels.filter { viewModel in
                viewModel.address.lowercased().contains(searchText.lowercased())
            }
            if filteredRecipientsViewModels.isEmpty && !searchText.isEmpty {
                if dependencyProvider.mobileWallet().check(accountAddress: searchText) {
                    self.filteredRecipientsViewModels.append(RecipientViewModel(name: searchText, address: searchText))
                }
            }
        }
    }
}

// MARK: View
protocol SelectRecipientViewProtocol: ShowAlert {
    func bind(to viewModel: RecipientListViewModel)
}

// MARK: -
// MARK: Delegate
protocol SelectRecipientPresenterDelegate: AnyObject {
    func didSelect(recipient: RecipientDataType)
    func createRecipient()
    func selectRecipientDidSelectQR()
}

// MARK: -
// MARK: Presenter
protocol SelectRecipientPresenterProtocol: AnyObject {
	var view: SelectRecipientViewProtocol? { get set }
    func viewDidLoad()
    func viewWillAppear()
    
    func searchTextDidChange(newValue: String)
    func userSelectRecipient(with index: Int)
    
    func createRecipient()
    func scanQrTapped()
    
    func userDelete(recipientVM: RecipientViewModel)
}

class SelectRecipientPresenter {

    weak var view: SelectRecipientViewProtocol?
    weak var delegate: SelectRecipientPresenterDelegate?
    
    var closure: ((RecipientDataType) -> Void)?
    
    private var storageManger: StorageManagerProtocol

    private var cancellables: [AnyCancellable] = []
    
    private var viewModel: RecipientListViewModel
    
    @Published private var recipients = [RecipientDataType]()
    @Published var originalRecipientsViewModels = [RecipientViewModel]()

    var searchText = ""
    
    init(delegate: SelectRecipientPresenterDelegate? = nil,
         closure: ((RecipientDataType) -> Void)? = nil,
         storageManager: StorageManagerProtocol,
         mode: SelectRecipientMode,
         ownAccount: AccountDataType? = nil) {
        self.delegate = delegate
        self.closure = closure
        self.storageManger = storageManager
        
        viewModel = RecipientListViewModel(storageManager: storageManager, mode: mode)
//        viewModel.mode = mode
        
        $recipients.sink { (recipients) in
            self.originalRecipientsViewModels.removeAll()
                        
            for (index, recipient) in recipients.enumerated() {
                self.originalRecipientsViewModels.append(RecipientViewModel(recipient: recipient, realIndex: index, isEncrypted: false))
            }

            self.originalRecipientsViewModels = Array((NSOrderedSet(array: (self.originalRecipientsViewModels)).array as? [RecipientViewModel]) ?? [])
            
            // Filter out own account.
            self.originalRecipientsViewModels = self.originalRecipientsViewModels
                .filter {$0.address != ownAccount?.address}
                .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            
        }.store(in: &cancellables)
    }

    init(delegate: SelectRecipientPresenterDelegate? = nil,
         storageManager: StorageManagerProtocol,
         mode: SelectRecipientMode,
         ownAccount: AccountDataType? = nil) {
        self.delegate = delegate
        self.storageManger = storageManager
        viewModel = RecipientListViewModel(storageManager: storageManager, mode: mode)

//        viewModel.mode = mode
//        
//        $recipients.sink { (recipients) in
//            self.originalRecipientsViewModels.removeAll()
//                        
//            for (index, recipient) in recipients.enumerated() {
//                self.originalRecipientsViewModels.append(RecipientViewModel(recipient: recipient, realIndex: index, isEncrypted: false))
//            }
//
//            self.originalRecipientsViewModels = Array((NSOrderedSet(array: (self.originalRecipientsViewModels)).array as? [RecipientViewModel]) ?? [])
//            
//            // Filter out own account.
//            self.originalRecipientsViewModels = self.originalRecipientsViewModels
//                .filter {$0.address != ownAccount?.address}
//                .sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
//            
//        }.store(in: &cancellables)
    }

    func viewDidLoad() {
        view?.bind(to: viewModel)
    }
    
    fileprivate func refreshData() {
        recipients = storageManger.getRecipients()
        filterRecipients(searchText: self.searchText)
    }
    
    func viewWillAppear() {
        refreshData()
    }

    private func filterRecipients(searchText: String) {
//        if searchText.isEmpty {
////            viewModel.recipients = originalRecipientsViewModels
//        } else {
//            viewModel.recipients = originalRecipientsViewModels.filter({ (viewModel) -> Bool in
//                viewModel.name.lowercased().contains(searchText.lowercased())
//            })
//        }
    }
}

extension SelectRecipientPresenter: SelectRecipientPresenterProtocol {
    func searchTextDidChange(newValue: String) {
        self.searchText = newValue
        filterRecipients(searchText: newValue)
    }

    func userSelectRecipient(with index: Int) {
//        let realIndex = viewModel.recipients[index].realIndex
//        delegate?.didSelect(recipient: recipients[realIndex])
//        closure?(recipients[realIndex])
    }

    func createRecipient() {
        delegate?.createRecipient()
    }

    func scanQrTapped() {
        PermissionHelper.requestAccess(for: .camera) { [weak self] permissionGranted in
            guard let self = self else { return }
            
            guard permissionGranted else {
                self.view?.showRecoverableErrorAlert(
                    .cameraAccessDeniedError,
                    recoverActionTitle: "errorAlert.continueButton".localized,
                    hasCancel: true
                ) {
                    SettingsHelper.openAppSettings()
                }
                return
            }

            self.delegate?.selectRecipientDidSelectQR()
        }
    }
    
    func userDelete(recipientVM: RecipientViewModel) {
        let realIndex = recipientVM.realIndex
        storageManger.removeRecipient(recipients[realIndex])
        self.refreshData()
    }
}
