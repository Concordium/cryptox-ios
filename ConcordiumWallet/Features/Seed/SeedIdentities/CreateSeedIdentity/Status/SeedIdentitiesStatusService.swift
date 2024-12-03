//
//  SeedIdentitiesStatusService.swift
//  CryptoX
//
//  Created by Zhanna Komar on 05.11.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation

protocol SeedIdentityStatusPresenterDelegate: AnyObject {
    func seedIdentityStatusDidFinish(with identity: IdentityDataType)
    func seedNewIdentityStatusDidFinish(with identity: IdentityDataType)
    func seedIdentityStatusDidFail(with error: IdentityRejectionError)
    func makeNewIdentityRequestAfterSettingUpWallet()
    func makeNewAccount(with identity: IdentityDataType)
}

class SeedIdentityStatusService {
    private let identitiesService: SeedIdentitiesService
    private var identity: IdentityDataType
    private var isNewIdentityAfterSettingUpTheWallet: Bool
    weak var delegate: SeedIdentityStatusPresenterDelegate?
    
    init(
        identity: IdentityDataType,
        identitiesService: SeedIdentitiesService,
        isNewIdentityAfterSettingUpTheWallet: Bool,
        delegate: SeedIdentityStatusPresenterDelegate
    ) {
        self.identity = identity
        self.identitiesService = identitiesService
        self.isNewIdentityAfterSettingUpTheWallet = isNewIdentityAfterSettingUpTheWallet
        self.delegate = delegate
        
        updatePendingIdentity(identity: identity)
    }
    
    private func updatePendingIdentity(
        identity: IdentityDataType,
        after delay: TimeInterval = 0.0
    ) {
        guard identity.state == .pending else {
            receiveUpdatedIdentity(identity: identity)
            return
        }
        
        Task.init {
            try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            
            let updatedIdentity = try await self.identitiesService
                .updatePendingSeedIdentity(identity)
            
            DispatchQueue.main.async {
                self.receiveUpdatedIdentity(identity: updatedIdentity)
            }
        }
    }
    
    private func receiveUpdatedIdentity(identity: IdentityDataType) {
        self.identity = identity
        
        switch identity.state {
        case .pending:
            updatePendingIdentity(identity: identity, after: 5)
        case .confirmed:
            if isNewIdentityAfterSettingUpTheWallet {
                delegate?.seedNewIdentityStatusDidFinish(with: identity)
            } else {
                delegate?.seedIdentityStatusDidFinish(with: identity)
            }
        case .failed:
            if isNewIdentityAfterSettingUpTheWallet {
                let error = IdentityRejectionError(description: identity.identityCreationError)
                delegate?.seedIdentityStatusDidFail(with: error)
            }
        }
    }
}
