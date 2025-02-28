//
//  ValidatorPoolSettingsViewModel.swift
//  CryptoX
//
//  Created by Zhanna Komar on 18.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import SwiftUICore

final class ValidatorPoolSettingsViewModel: ObservableObject {
    @Published var showsCloseForNew: Bool = false
    @Published var currentSettings: BakerPoolSetting
    @Published var isOpened: Bool = false
    @Published var dataHandler: BakerDataHandler
    private var cancellables = Set<AnyCancellable>()
    private let navigationManager: NavigationManager
    
    init(dataHandler: BakerDataHandler, navigationManager: NavigationManager) {
        self.dataHandler = dataHandler
        self.navigationManager = navigationManager
        let poolSettingsData: BakerPoolSettingsData? = dataHandler.getCurrentEntry()
        self.currentSettings = poolSettingsData?.poolSettings ?? .open
        setupSettings()
        
        self.$isOpened.sink(receiveCompletion: { _ in
        }, receiveValue: { [weak self] selectedOption in
            guard let self = self else { return }
            switch selectedOption {
            case true:
                self.currentSettings = .open
//            case 1:
//                if self.viewModel.showsCloseForNew {
//                    self.poolSettings = .closedForNew
//                } else {
//                    self.poolSettings = .closed
//                }
            case false:
                self.currentSettings = .closed
            }
            
        }).store(in: &cancellables)
    }
    
    private func setupSettings() {
        switch currentSettings {
        case .open:
            showsCloseForNew = true
            isOpened = true
        case .closedForNew:
            showsCloseForNew = true
            isOpened = false
        case .closed:
            isOpened = false
        }
    }
    
    func pressedContinue() {
        self.dataHandler.add(entry: BakerPoolSettingsData(poolSettings: currentSettings))
        switch dataHandler.transferType {
        case .registerBaker:
            if case .open = dataHandler.getNewEntry(BakerPoolSettingsData.self)?.poolSettings {
                navigationManager.navigate(to: .commissionSettings(
                    ValidatorCommissionSettingsViewModel(
                        service: ServicesProvider.defaultProvider().stakeService(),
                        handler: dataHandler
                        )))
            } else {
                navigationManager.navigate(to: .generateKey(ValidatorGenerateKeysViewModel(dataHandler: dataHandler,
                                                                                           account: dataHandler.account,
                                                                                           dependencyProvider: ServicesProvider.defaultProvider())))
            }
        case .updateBakerPool:
            break
        default:
            break // Should never happen
        }
    }
}

extension ValidatorPoolSettingsViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorPoolSettingsViewModel, rhs: ValidatorPoolSettingsViewModel) -> Bool {
        lhs.isOpened == rhs.isOpened &&
        lhs.showsCloseForNew == rhs.showsCloseForNew &&
        lhs.currentSettings == rhs.currentSettings &&
        lhs.dataHandler == rhs.dataHandler
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(isOpened)
        hasher.combine(showsCloseForNew)
        hasher.combine(currentSettings)
        hasher.combine(dataHandler)
    }
}
