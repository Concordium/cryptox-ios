//
//  StakeStatusPresenter.swift
//  ConcordiumWallet
//
//  Created by Ruxandra Nistor on 23/03/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: Presenter
protocol StakeStatusPresenterProtocol: AnyObject {
    func viewDidLoad()
    func pressedButton()
    func pressedStopButton()
    func closeButtonTapped()
    func updateStatus()
}

struct StakeStatusViewModelError: Identifiable {
    let id = UUID()
    let error: Error

    init(_ error: Error) {
        self.error = error
    }
}

class LegacyStakeStatusViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var topText: String = ""
    @Published var topImageName: String = ""
    @Published var placeholderText: String?
    
    @Published var gracePeriodText: String?
    @Published var bottomInfoMessage: String?
    @Published var bottomImportantMessage: String?
    
    @Published var newAmount: String?
    @Published var newAmountLabel: String?
    
    @Published var stopButtonEnabled: Bool = true
    @Published var stopButtonShown: Bool = true
    @Published var stopButtonLabel: String = ""
    
    @Published var updateButtonEnabled: Bool = true
    @Published var buttonLabel: String = ""
    @Published var accountCooldowns: [AccountCooldown] = []
    
    @Published var rows: [StakeRowViewModel] = []
    @Published var error: StakeStatusViewModelError?
    
    private var cancellables = Set<AnyCancellable>()
    private var stakeService: StakeServiceProtocol

    var presenter: StakeStatusPresenterProtocol?

    init(dependencyProvider: StakeCoordinatorDependencyProvider) {
        self.stakeService = dependencyProvider.stakeService()
    }
    
    func setPresenter(_ presenter: StakeStatusPresenterProtocol) {
        self.presenter = presenter
        loadData()
    }
    
    func setup(dataHandler: StakeDataHandler) {
        rows = dataHandler
            .getCurrentOrdered()
            .map { StakeRowViewModel(displayValue: $0) }
    }
    
    func loadData() {
        presenter?.viewDidLoad()
    }
    
    func pressedButton() {
        presenter?.pressedButton()
    }
    
    func pressedStopButton() {
        presenter?.pressedStopButton()
    }
    
    func closeButtonTapped() {
        presenter?.closeButtonTapped()
    }
    
    func updateStatus() {
        presenter?.updateStatus()
    }
}
