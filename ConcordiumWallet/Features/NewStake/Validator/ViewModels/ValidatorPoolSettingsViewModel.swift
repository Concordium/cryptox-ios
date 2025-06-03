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

enum ValidatorPoolSetting: String {
    case open = "openForAll"
    case closedForNew = "closedForNew"
    case closed = "closedForAll"
    
    func getDisplayValue() -> String {
        switch self {
        case .open:
            return "baking.open".localized
        case .closedForNew:
            return "baking.closedfornew".localized
        case .closed:
            return "baking.closed".localized
        }
    }
}

final class ValidatorPoolSettingsViewModel: ObservableObject {
    @Published var showsCloseForNew: Bool = false
    @Published var currentSettings: ValidatorPoolSetting?
    @Published var selectedPoolSettingIndex: Int = 0
    @Published var dataHandler: BakerDataHandler
    private var cancellables = Set<AnyCancellable>()
    private let navigationManager: NavigationManager
    
    init(dataHandler: BakerDataHandler, navigationManager: NavigationManager) {
        self.dataHandler = dataHandler
        self.navigationManager = navigationManager
        let poolSettingsData: BakerPoolSettingsData? = dataHandler.getCurrentEntry()
        self.currentSettings = poolSettingsData?.poolSettings
        setupSettings()
        
        self.$selectedPoolSettingIndex.sink(receiveCompletion: { _ in
        }, receiveValue: { [weak self] selectedOption in
            guard let self = self else { return }
            switch selectedOption {
            case 0:
                self.currentSettings = .open
            case 1:
                if self.showsCloseForNew {
                    self.currentSettings = .closedForNew
                } else {
                    self.currentSettings = .closed
                }
            case 2:
                self.currentSettings = .closed
            default:
                break
            }
            
        }).store(in: &cancellables)
    }
    
    private func setupSettings() {
        guard let currentSettings else { return }
        switch currentSettings {
        case .open:
            showsCloseForNew = true
            selectedPoolSettingIndex = 0
        case .closedForNew:
            showsCloseForNew = true
            selectedPoolSettingIndex = 1
        case .closed:
            selectedPoolSettingIndex = 1 // if the current state of the pool is closed, we don't show closed for new so the index is 1
        }
    }
    
    func pressedContinue() {
        guard let currentSettings else { return }
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
            navigationManager.navigate(to: .commissionSettings(
                ValidatorCommissionSettingsViewModel(
                    service: ServicesProvider.defaultProvider().stakeService(),
                    handler: dataHandler
                    )))
        default:
            break // Should never happen
        }
    }
}

extension ValidatorPoolSettingsViewModel: Equatable, Hashable {
    static func == (lhs: ValidatorPoolSettingsViewModel, rhs: ValidatorPoolSettingsViewModel) -> Bool {
        lhs.selectedPoolSettingIndex == rhs.selectedPoolSettingIndex &&
        lhs.showsCloseForNew == rhs.showsCloseForNew &&
        lhs.currentSettings == rhs.currentSettings &&
        lhs.dataHandler == rhs.dataHandler
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(selectedPoolSettingIndex)
        hasher.combine(showsCloseForNew)
        hasher.combine(currentSettings)
        hasher.combine(dataHandler)
    }
}
