//
//  ValidatorGenerateKeysViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 27.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import SwiftUICore

class ValidatorGenerateKeysViewModel: ObservableObject {
    @Published private(set) var title: String
    @Published private(set) var info = "baking.generatekeys.info".localized
    @Published private(set) var electionKeyTitle = "baking.generatekeys.electionkey".localized
    @Published private(set) var electionKeyContent: String
    @Published private(set) var signatureKeyTitle = "baking.generatekeys.signaturekey".localized
    @Published private(set) var signatureKeyContent: String
    @Published private(set) var aggregationKeyTitle = "baking.generatekeys.aggregationkey".localized
    @Published private(set) var aggregationKeyContent: String
    @Published var fileToShare: URL?
    @Published var showShareSheet = false
    
    @Published var dataHandler: BakerDataHandler
    let keyResult: Result<GeneratedBakerKeys, Error>
    private let transactionService: TransactionsServiceProtocol
    private let stakeService: StakeServiceProtocol
    private let exportService: ExportService
    private let account: AccountDataType
    
    init(dataHandler: BakerDataHandler,
         account: AccountDataType,
         dependencyProvider: StakeCoordinatorDependencyProvider) {
        self.keyResult = dependencyProvider.stakeService().generateBakerKeys()
        self.dataHandler = dataHandler
        self.transactionService = dependencyProvider.transactionsService()
        self.stakeService = dependencyProvider.stakeService()
        self.exportService = dependencyProvider.exportService()
        self.account = account
        if dataHandler.transferType == .updateBakerKeys {
            title = "baking.updatekeys.title".localized
        } else {
            title = "baking.generatekeys.title".localized
        }
        
        if case let .success(keys) = keyResult {
            electionKeyContent = keys.electionVerifyKey
            signatureKeyContent = keys.signatureVerifyKey
            aggregationKeyContent = keys.aggregationVerifyKey
        } else {
            electionKeyContent = ""
            signatureKeyContent = ""
            aggregationKeyContent = ""
        }
    }
    
    func handleExport() {
        if case let .success(keys) = keyResult {
            do {
                let exportedKeys = ExportedBakerKeys(bakerId: account.accountIndex, generatedKeys: keys)
                let fileUrl = try exportService.export(bakerKeys: exportedKeys)
                DispatchQueue.main.async {
                    self.fileToShare = fileUrl
                    self.showShareSheet = true
                }
            } catch {
//                Logger.error(error)
            }
        }
    }
    
    func handleExportEnded(completed: Bool, completion: (() -> Void)) {
        if completed, case let .success(keys) = keyResult {
            do {
                self.dataHandler.add(entry: BakerKeyData(keys: keys))
                try self.exportService.deleteBakerKeys()
                completion()
            } catch {
//                self.view?.showErrorAlert(ErrorMapper.toViewError(error: error))
            }
        }
        showShareSheet = false
        fileToShare = nil
    }
}

extension ValidatorGenerateKeysViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorGenerateKeysViewModel, rhs: ValidatorGenerateKeysViewModel) -> Bool {
        lhs.showShareSheet == rhs.showShareSheet &&
        lhs.title == rhs.title &&
        lhs.electionKeyContent == rhs.electionKeyContent &&
        lhs.signatureKeyContent == rhs.signatureKeyContent &&
        lhs.aggregationKeyContent == rhs.aggregationKeyContent &&
        lhs.fileToShare == rhs.fileToShare
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(showShareSheet)
        hasher.combine(title)
        hasher.combine(electionKeyContent)
        hasher.combine(signatureKeyContent)
        hasher.combine(aggregationKeyContent)
        hasher.combine(fileToShare)
    }
}
