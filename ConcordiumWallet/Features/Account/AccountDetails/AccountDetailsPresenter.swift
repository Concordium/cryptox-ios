//
//  AccountDetailsPresenter.swift
//  ConcordiumWallet
//
//  Created by Concordium on 3/30/20.
//  Copyright © 2020 concordium. All rights reserved.
//

import Foundation
import Combine

enum AccountDetailTab {
    case transfers
    case identityData
}

protocol TransactionsFetcher {
    func getNextTransactions()
}

// MARK: View
protocol AccountDetailsViewProtocol: ShowAlert, Loadable {
    func bind(to viewModel: AccountDetailsViewModel)
}

// MARK: -
// MARK: Presenter
protocol AccountDetailsPresenterProtocol: AnyObject {
    var view: AccountDetailsViewProtocol? { get set }
    func viewDidLoad()
    func viewWillAppear()
    
    func getTitle() -> String
    func gtuDropTapped()

    func userSelectedIdentityData()
    func userSelectedGeneral()
    func userSelectedTransfers()

    func showGTUDrop() -> Bool
    func updateTransfersOnChanges()
}

class AccountDetailsPresenter {

    weak var view: AccountDetailsViewProtocol?
    var delegate: (RequestPasswordDelegate)?
    private let storageManager: StorageManagerProtocol

    var account: AccountDataType
    private var balanceType: AccountBalanceTypeEnum = .balance
    private var cancellables: [AnyCancellable] = []
    private var viewModel: AccountDetailsViewModel

    private var accountsService: AccountsServiceProtocol
    private let transactionsLoadingHandler: TransactionsLoadingHandler
    
    private var shouldRefresh: Bool = true
    private var lastRefreshTime: Date = Date()
    
    private var lastTransactionListAll: [TransactionViewModel] = []
    
    init(dependencyProvider: AccountsFlowCoordinatorDependencyProvider,
         account: AccountDataType,
         delegate: (RequestPasswordDelegate)? = nil) {
        self.accountsService = dependencyProvider.accountsService()
        self.storageManager = dependencyProvider.storageManager()
        self.account = account
        self.delegate = delegate
        
        viewModel = AccountDetailsViewModel(account: account, balanceType: balanceType)
        transactionsLoadingHandler = TransactionsLoadingHandler(account: account, balanceType: balanceType, dependencyProvider: dependencyProvider)
    }
}

extension AccountDetailsPresenter: AccountDetailsPresenterProtocol {
    func showGTUDrop() -> Bool {
        return true
    }
    
    func getTitle() -> String {
        return self.account.displayName
    }
    
    func viewDidLoad() {
        view?.bind(to: viewModel)
    }
    
    func setShouldRefresh(_ refresh: Bool) {
        shouldRefresh = refresh
    }
    
    func switchToBalanceType(_ balanceType: AccountBalanceTypeEnum) {
        self.balanceType = balanceType
        viewModel.setAccount(account: account, balanceType: balanceType)
        transactionsLoadingHandler.updateBalanceType(balanceType)
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables = []
        view?.bind(to: viewModel)
    }
    
    func updateTransfersOnChanges() {
        if lastRefreshTime.timeIntervalSinceNow * -1 < 60 { return }
        guard let delegate = delegate else { return }
        if viewModel.selectedTab == .transfers {
            accountsService.updateAccountBalancesAndDecryptIfNeeded(account: account, balanceType: balanceType, requestPasswordDelegate: delegate)
                .mapError(ErrorMapper.toViewError)
                .sink(receiveError: { [weak self] error in
                    self?.view?.showErrorAlert(error)
                    }, receiveValue: { [weak self] account in
                        self?.getTransactionsUpdateOnChanges()
                        if let balanceType = self?.balanceType {
                            self?.viewModel.setAccount(account: account, balanceType: balanceType)
                        }
                        self?.lastRefreshTime = Date()
                }).store(in: &cancellables)
        }
    }
    
    fileprivate func updateTransfers() {
        guard let delegate = delegate else { return }
        accountsService.updateAccountBalancesAndDecryptIfNeeded(account: account, balanceType: balanceType, requestPasswordDelegate: delegate)
            .mapError(ErrorMapper.toViewError)
            .sink(receiveError: { [weak self] error in
                self?.view?.showErrorAlert(error)
                }, receiveValue: { [weak self] account in
                    // We cannot get transactions from server before we have updated our
                    // local store of transactions in the updateAccountsBalances call
                    self?.getTransactions()
                    if let balanceType = self?.balanceType {
                        self?.viewModel.setAccount(account: account, balanceType: balanceType)
                    }
                    self?.lastRefreshTime = Date()
            }).store(in: &cancellables)
    }

    func viewWillAppear() {
        if shouldRefresh {
            updateTransfers()
            shouldRefresh = false
        }
    }

    func userSelectedGeneral() {
        if balanceType != .balance {
            switchToBalanceType(.balance)
            userSelectedTransfers()
        }
    }
    
    func userSelectedIdentityData() {
        viewModel.selectedTab = .identityData
    }

    func userSelectedTransfers() {
        updateTransfers()
        viewModel.selectedTab = .transfers
    }
    
    func gtuDropTapped() {
        accountsService.gtuDrop(for: account.address)
                .mapError(ErrorMapper.toViewError)
                .sink(receiveError: { [weak self] in
                    self?.view?.showErrorAlert($0)
                }, receiveValue: { [weak self] _ in
                    self?.updateTransfers()
                })
                .store(in: &cancellables)
        updateTransfers()
    }

    func getTransactionsUpdateOnChanges() {
        let transactionCall = transactionsLoadingHandler.getTransactions(startingFrom: nil).eraseToAnyPublisher()

        transactionCall
                .mapError(ErrorMapper.toViewError)
                .sink(receiveError: {[weak self] error in
                    self?.view?.showErrorAlert(error)
                }, receiveValue: { [weak self] (transactionsListFiltered, transactionListAll) in
                    guard let self = self else { return }

                    // The old implementation
//                    // Any changes since last auto update?
//                    let equal = zip(transactionListAll, self.lastTransactionListAll)
//                        .enumerated()
//                        .filter { $1.0.details.transactionHash == $1.1.details.transactionHash && $1.0.status == $1.1.status }
//                        .map { $1.0 }
                    
                    // The new implementation
                    // Any changes since last auto update?
                    let equalUnmapped = zip(transactionListAll, self.lastTransactionListAll)
                        .enumerated()
                        .filter { $1.0.details.transactionHash == $1.1.details.transactionHash && $1.0.status == $1.1.status }
                    let equal = equalUnmapped.map { $1.0 }

                    if equal.count != transactionListAll.count {
                        self.lastTransactionListAll = transactionListAll

                        self.viewModel.setTransactions(transactions: transactionsListFiltered)
                        self.viewModel.hasTransfers = self.viewModel.transactionsList.transactions.count > 0
                        self.viewModel.setAllAccountTransactions(transactions: transactionListAll)

                        if transactionsListFiltered.count == 0 &&
                            transactionListAll.count != 0 &&
                            transactionListAll.last?.isLast != true {
                            self.getTransactions(startingFrom: transactionListAll.last)
                        }
                    }
                }).store(in: &cancellables)
    }
    
    func getTransactions(startingFrom transaction: TransactionViewModel? = nil) {
        guard !viewModel.hasInflightTransactionListRequest(startingFrom: transaction) else { return }
        viewModel.transactionListRequestStarted(startingFrom: transaction)
                
        var transactionCall = transactionsLoadingHandler.getTransactions(startingFrom: transaction).eraseToAnyPublisher()

        if transaction == nil {// Only show loading indicator (blocking the view) in the first call
            transactionCall = transactionCall
                .showLoadingIndicator(in: self.view)
                .eraseToAnyPublisher()
        }

        transactionCall
                .mapError(ErrorMapper.toViewError)
                .handleEvents(
                    receiveCompletion: { [weak self] _ in
                        self?.viewModel.transactionListRequestEnded(startingFrom: transaction)
                    }
                )
                .sink(receiveError: {[weak self] error in
                    self?.view?.showErrorAlert(error)
                }, receiveValue: { [weak self] (transactionsListFiltered, transactionListAll) in
                    guard let self = self else { return }
                    if transaction == nil {
                        self.viewModel.setTransactions(transactions: transactionsListFiltered)
                        self.viewModel.setAllAccountTransactions(transactions: transactionListAll)
                    } else {
                        self.viewModel.appendTransactions(transactions: transactionsListFiltered)
                        self.viewModel.appendAllAccountTransactions(transactions: transactionListAll)
                    }
                    self.viewModel.hasTransfers = self.viewModel.transactionsList.transactions.count > 0
                    if transactionsListFiltered.count == 0 &&
                        transactionListAll.count != 0 &&
                        transactionListAll.last?.isLast != true {
                        self.getTransactions(startingFrom: transactionListAll.last)
                    }
                }).store(in: &cancellables)
    }
}

extension AccountDetailsPresenter: TransactionsFetcher {
    func getNextTransactions() {
        guard let lastRemoteTransaction = viewModel.allAccountTransactionsList.transactions.last(where: { $0.source is Transaction }),
                     lastRemoteTransaction.isLast == false else {
                       return
                   }
        let startingFrom = lastRemoteTransaction
        getTransactions(startingFrom: startingFrom)
    }
}

extension AccountDetailsPresenter: BurgerMenuAccountDetailsDismissDelegate {
    func bugerMenuDismissedWithAction(_action action: BurgerMenuAccountDetailsAction) {
        self.viewModel.menuState = .closed
    }
}
