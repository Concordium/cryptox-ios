//
//  TransferTokenViewModel.swift
//  StagingNet
//
//  Created by Zhanna Komar on 03.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import BigInt

enum GeneralAppError: LocalizedError {
    case noCameraAccess
    case somethingWentWrong
    
    var errorDescription: String? {
        switch self {
            case .noCameraAccess:
                return "errorAlert.title".localized
            case .somethingWentWrong:
                return "something_went_wrong".localized
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
            case .noCameraAccess:
                return "view.error.cameraAccessDenied".localized
            case .somethingWentWrong: return "Oops"
        }
    }
    
    var actionButtontitle: String? {
        switch self {
            case .noCameraAccess:
                return "errorAlert.open.settings".localized
            case .somethingWentWrong:
                return "Ok"
        }
    }
}

enum CXTokenType {
    case cis2(CIS2Token), ccd
    
    var isCIS2Token: Bool {
        switch self {
            case .ccd: return false
            default: return true
        }
    }
    
    var name: String {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.name ?? ""
            case .ccd:
                return "ccd"
        }
    }
    
    var fraction: Int {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.decimals ?? 0
            case .ccd:
                return 6
        }
    }
}


protocol TransferTokenViewProtocol {
    func setMemo(memo: Memo?)
}

final class TransferTokenViewModel: ObservableObject {
    @Published var amount: Decimal = .zero
    
    @Published var availableDisplayAmount: String = ""
    @Published var atDisposalCCDDisplayAmount: String = ""
    @Published var amountTokenSend: BigDecimal = .zero
    
    @Published var recepientAddress: String = ""
    
    @Published var thumbnail: URL? = nil
    @Published var canSend: Bool = false
    @Published var ticker: String = ""
    
    @Published var error: GeneralAppError?
    @Published var isInsuficientFundsErrorHidden: Bool = true
    
    @Published var transaferCost: TransferCost?
    @Published var fraction: Int = 6
    
    @Published var addedMemo: Memo?
    @Published var showMemoRemoveButton: Bool = false
    @Published var addMemoText: String = ""
    
    var tokenTransferModel: CIS2TokenTransferModel
    private var cost: GTU?
    
    lazy var accountTokensListPickerViewModel: AccountTokensListPickerViewModel = {
        AccountTokensListPickerViewModel(account: account, storageManager: dependencyProvider.storageManager(), networkManager: dependencyProvider.networkManager(), selectedToken: tokenTransferModel.tokenType)
    }()
    
    private var cancellables = [AnyCancellable]()
    let account: AccountDataType
    private let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    private let proxy: TransferTokenRouter
    
    init(
        tokenType: CXTokenType,
        account: AccountDataType,
        proxy: TransferTokenRouter,
        dependencyProvider: AccountsFlowCoordinatorDependencyProvider,
        tokenTransferModel: CIS2TokenTransferModel,
        onRecipientPicked: AnyPublisher<String, Never>
    ) {
        self.tokenTransferModel = tokenTransferModel
        self.proxy = proxy
        self.dependencyProvider = dependencyProvider
        self.account = account
        
        $recepientAddress.assign(to: \.recipient, on: tokenTransferModel).store(in: &cancellables)
        $amountTokenSend.assign(to: \.amountTokenSend, on: tokenTransferModel).store(in: &cancellables)
        $addedMemo.assign(to: \.memo, on: tokenTransferModel).store(in: &cancellables)
        tokenTransferModel.$transaferCost.assign(to: \.transaferCost, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.map(\.fraction).assign(to: \.fraction, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.map(\.ticker).assign(to: \.ticker, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.map(\.tokenThumbnail).assign(to: \.thumbnail, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.assign(to: \.selectedToken, on: accountTokensListPickerViewModel).store(in: &cancellables)
        
        onRecipientPicked.assign(to: \.recepientAddress, on: self).store(in: &cancellables)
        
        tokenTransferModel.$tokenType.sink { type in
            self.amount = .zero
        }.store(in: &cancellables)
        
        Publishers.CombineLatest3($amountTokenSend, tokenTransferModel.$tokenGeneralBalance, $transaferCost)
            .map { (amount, maxAmount, cost) -> Bool in
                guard let cost = cost else { return true }
                let costInt = BigInt(stringLiteral: cost.cost)
                let generalAmount: BigDecimal = BigDecimal((costInt + amount.value), 6)
                return generalAmount.value <= maxAmount.value && costInt <= BigInt(account.forecastBalance)
            }
            .assign(to: \.isInsuficientFundsErrorHidden, on: self)
            .store(in: &cancellables)
        
        Publishers.CombineLatest4($amountTokenSend, tokenTransferModel.$tokenGeneralBalance, $transaferCost, $recepientAddress)
            .map { (s, a, txCost, recepient) -> Bool in
                guard let txCost = txCost else { return false }
                guard recepient != account.address else  { return false }
                guard !recepient.isEmpty && self.dependencyProvider.mobileWallet().check(accountAddress: recepient) else  { return false }
                
                let costInt = BigInt(stringLiteral: txCost.cost)
                let generalAmount: BigDecimal = BigDecimal((costInt + s.value), 6)
                
                if costInt >= BigInt(account.forecastBalance) { return false }
                
                return (generalAmount.value <= a.value) && s.value > .zero
            }
            .assign(to: \.canSend, on: self)
            .store(in: &cancellables)
        
        
        tokenTransferModel.$tokenGeneralBalance
            .map { TokenFormatter().string(from: $0) }
            .assign(to: \.availableDisplayAmount, on: self)
            .store(in: &cancellables)
        
        tokenTransferModel.$ccdTokenDisposalBalance
            .map { TokenFormatter().string(from: $0) }
            .assign(to: \.atDisposalCCDDisplayAmount, on: self)
            .store(in: &cancellables)
        
        self.$amount.map {
            TokenFormatter().number(from: $0.toString(), precision: tokenTransferModel.tokenType.decimals) ?? .zero
        }
        .assign(to: \.amountTokenSend, on: self)
        .store(in: &cancellables)
        
        $recepientAddress.sink { address in
            if self.dependencyProvider.mobileWallet().check(accountAddress: address) == false {
                
            }
        }.store(in: &cancellables)
        
        proxy.transferTokenViewDelegate = self
    }
    
    public func showQrScanner() {
        PermissionHelper.requestAccess(for: .camera) { [weak self] permissionGranted in
            guard let self = self else { return }
            
            guard permissionGranted else {
                self.error = GeneralAppError.noCameraAccess
                return
            }
            self.proxy.showQrAddressPicker { address in
                self.recepientAddress = address
            }
        }
    }
    
    public func showRecepientPicker() {
        self.proxy.showRecepientPicker { address in
            self.recepientAddress = address
        }
    }
    
    public func sendAll() {
        refreshMaxAmountTokenSend()
    }
    
    private func refreshMaxAmountTokenSend() {
        Task {
            await tokenTransferModel.updateMaxAmount()
            DispatchQueue.main.async {
                self.amountTokenSend = self.tokenTransferModel.maxAmountTokenSend
            }
        }
    }
}

extension TransferTokenViewModel: TransferTokenViewProtocol {
    func setMemo(memo: Memo?) {
        self.addedMemo = memo
        if self.tokenTransferModel.maxAmountTokenSend == self.amountTokenSend {
            refreshMaxAmountTokenSend()
        }
    }
    
    func removeMemo() {
        self.addedMemo = nil
    }
}

extension CXTokenType {
    var tokenThumbnail: URL? {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.thumbnail?.url.toURL
            case .ccd:
                return AssetExtractor.createLocalUrl(forImageNamed: "icon_ccd")
        }
    }
    
    var ticker: String {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.name  ?? ""
            case .ccd:
                return "CCD"
        }
    }
    var decimals: Int {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.decimals ?? 0
            case .ccd:
                return 6
        }
    }
}
