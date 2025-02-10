//
//  AddRecipientViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 30.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation

enum AddRecipientError: LocalizedError {
    case addressNotValid
    case addressAlreadyExists(_ address: String)
    case somethingWentWrong(_ description: String)
    
    var errorDescription: String? {
        switch self {
            case .addressNotValid:
                return "addRecipient.addressInvalid".localized
            case .addressAlreadyExists(let address):
            return "viewError.duplicateRecipient".localized + address
            case .somethingWentWrong(let description):
                return description
        }
    }
}

enum EditRecipientMode: Equatable, Hashable {
    case add
    case edit(address: String)
}

class AddRecipientViewModel: ObservableObject {
    @Published var address: String = ""
    @Published var name: String = ""
    @Published var title: String = ""
    @Published var enableSave = false
    @Published var error: AddRecipientError?
    var shouldShowErrorAlert: Bool {
        return error != nil
    }
    private var storageManager: StorageManagerProtocol
    private var mode: EditRecipientMode
    private var wallet: MobileWalletProtocol

    init(dependencyProvider: WalletAndStorageDependencyProvider, mode: EditRecipientMode) {
        self.storageManager = dependencyProvider.storageManager()
        self.mode = mode
        self.wallet = dependencyProvider.mobileWallet()
        switch mode {
        case .add:
            title = "addRecipient.title".localized
        case .edit(let address):
            title = "editAddress.title".localized
            if let recipient = storageManager.getRecipient(withAddress: address) {
                name = recipient.name
                self.address = recipient.address
            }
        }
    }
    
    func addRecipient(name: String, address: String) {
        let recipient = RecipientEntity()
        recipient.name = name
        recipient.address = address
        _ = try? storageManager.storeRecipient(recipient)
    }
    
    func calculateSaveButtonState() {
        switch mode {
        case .add:
            enableSave = !name.isEmpty && !address.isEmpty && error == nil
        case .edit(let address):
            if let recipient = storageManager.getRecipient(withAddress: address) {
                enableSave = (name != recipient.name) || (address != recipient.address)
                && (!name.isEmpty && !address.isEmpty) && error == nil
            }
        }
    }
    
    func saveTapped() async {
        let qrValid = await wallet.check(accountAddress: address)
        await MainActor.run {
            if !qrValid {
                error = .addressNotValid
                return
            }

            var newRecipient = RecipientDataTypeFactory.create()
            newRecipient.name = name
            newRecipient.address = address
            
            switch mode {
            case .add:
                if let existingRecipient = storageManager.getRecipient(withAddress: address) {
                    error = .addressAlreadyExists(existingRecipient.name)
                    self.name = ""
                    self.address = ""
                    return
                }
            default: break
            }

            switch mode {
                case .add:
                    do {
                        try storageManager.storeRecipient(newRecipient)
                    } catch let error {
                        self.error = .somethingWentWrong(error.localizedDescription)
                }
                case .edit(let address):
                    do {
                        if let recipient = storageManager.getRecipient(withAddress: address) {
                            try storageManager.editRecipient(oldRecipient: recipient, newRecipient: newRecipient)
                        }
                    } catch let error {
                        self.error = .somethingWentWrong(error.localizedDescription)
                }
            }
        }
    }
}
