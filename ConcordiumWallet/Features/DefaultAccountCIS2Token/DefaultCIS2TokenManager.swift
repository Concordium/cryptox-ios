//
//  DefaultCIS2TokenManager.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 20.07.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import Foundation
import SwiftUI

final class DefaultCIS2TokenManager {
    @AppStorage("isRestoredDefaultCIS2Tokens") private var isRestoredDefaultCIS2Tokens = false
    
#if MAINNET
    static let defaultCI2TokensIds: [SmartContractAddress] = [.wccd, .euroe, .ethArabella, .wbts, .usdcArabella, .usdtArabella]
#else
    static let defaultCI2TokensIds: [SmartContractAddress] = [.wccd, .euroe, .ethArabella, .wbts, .usdcArabella, .usdtArabella]
#endif
    
    private let storageManager: StorageManagerProtocol
    
    init(storageManager: StorageManagerProtocol) {
        self.storageManager = storageManager
    }
    
    public func initializeDefaultValues() {
        Task {
            do {
                try await self.initializeDefaultValues()
            } catch {
                logger.errorLog("error while restoring tokens -- \(error)")
            }
        }
    }
    
    public func initializeDefaultValues() async throws {
        guard isRestoredDefaultCIS2Tokens == false else { return }
        isRestoredDefaultCIS2Tokens = true

        logger.debugLog("started restore default tokens")
        
        for address in Self.defaultCI2TokensIds {
            let tkns = try await CIS2TokenService.getCIS2Tokens(for: address.index)
            self.storeTokenToAccounts(tkns.first)
        }
    
        logger.debugLog("restored default tokens")
    }
    
    public func addDefaultCIS2Token(to account: AccountDataType) async throws {
        for address in Self.defaultCI2TokensIds {
            guard let token = try await CIS2TokenService.getCIS2Tokens(for: address.index).first else { return }
            await MainActor.run {
                storeTokenIfNeeded(token, to: account)
            }
        }
    }
    
    private func storeTokenToAccounts(_ token: CIS2Token?) {
        guard let token = token else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for account in storageManager.getAccounts() {
                self.storeTokenIfNeeded(token, to: account)
            }
        }
    }
    
    private func storeTokenIfNeeded(_ token: CIS2Token, to account: AccountDataType) {
        if self.storageManager.getAccountSavedCIS2Tokens(account.address).contains(token) { return }
        do {
            try self.storageManager.storeCIS2Token(token: token, address: account.address)
        } catch {
            logger.errorLog("error while storeTokenIfNeeded -- \(error)")
        }
    }
}

extension SmartContractAddress {
#if MAINNET
    static let wccd: SmartContractAddress = SmartContractAddress(index: 9354, subindex: 0)
#else
    static let wccd: SmartContractAddress = SmartContractAddress(index: 2059, subindex: 0)
#endif
    
#if MAINNET
    static let ethArabella: SmartContractAddress = SmartContractAddress(index: 9338, subindex: 0)
#else
    static let ethArabella: SmartContractAddress = SmartContractAddress(index: 4514, subindex: 0)
#endif
    
#if MAINNET
    static let wbts: SmartContractAddress = SmartContractAddress(index: 9340, subindex: 0)
#else
    static let wbts: SmartContractAddress = SmartContractAddress(index: 4515, subindex: 0)
#endif
    
#if MAINNET
    static let usdtArabella: SmartContractAddress = SmartContractAddress(index: 9341, subindex: 0)
#else
    static let usdtArabella: SmartContractAddress = SmartContractAddress(index: 4517, subindex: 0)
#endif
    
#if MAINNET
    static let usdcArabella: SmartContractAddress = SmartContractAddress(index: 9339, subindex: 0)
#else
    static let usdcArabella: SmartContractAddress = SmartContractAddress(index: 4516, subindex: 0)
#endif
    
#if MAINNET
    static let euroe: SmartContractAddress = SmartContractAddress(index: 9390, subindex: 0)
#else
    static let euroe: SmartContractAddress = SmartContractAddress(index: 7260, subindex: 0)
#endif
}
