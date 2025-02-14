//
//  RecipientListViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine

enum SelectRecipientMode {
    case selectRecipientFromPublic
    case addressBook
}

class RecipientListViewModel: ObservableObject {
    @Published var recipients = [RecipientDataType]()
    @Published var mode: SelectRecipientMode = .selectRecipientFromPublic
    @Published var originalRecipientsViewModels = [RecipientViewModel]() // Full list of recipients
    @Published var filteredRecipientsViewModels = [RecipientViewModel]() // Filtered list displayed in the UI
    @Published var isNewValidAddress: Bool = false
    
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
            isNewValidAddress = false
        } else {
            self.filteredRecipientsViewModels = originalRecipientsViewModels.filter { viewModel in
                viewModel.address.lowercased().contains(searchText.lowercased())
            }
            if filteredRecipientsViewModels.isEmpty && !searchText.isEmpty {
                if dependencyProvider.mobileWallet().check(accountAddress: searchText) {
                    self.isNewValidAddress = true
                }
            }
        }
    }
    
    func addRecipient(name: String, address: String) {
        let recipient = RecipientEntity()
        recipient.name = name
        recipient.address = address
        _ = try? storageManager.storeRecipient(recipient)
        self.refreshData()
    }
    
    func deleteRecipient(at index: IndexSet) {
        let recipientVM = self.filteredRecipientsViewModels[index.first!]
        let recipient = recipients.first(where: {recipientVM.address == $0.address})
        storageManager.removeRecipient(recipient)
        self.refreshData()
    }
}
