//
//  WalletConnectService.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 19.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import WalletConnectPairing
import Web3Wallet
import SwiftUI
import Combine
import BigInt

protocol WalletConnectServiceProtocol: AnyObject {
    func showSessionProposal(with proposal: Session.Proposal, context: VerifyContext?)
    func showSessionRequest(with request: Request)
}

final class WalletConnectService {
    weak var delegate: WalletConnectServiceProtocol?

    private var publishers = [AnyCancellable]()
    
    private var currrentPairingAddress: String?
    
    init() {
        initialize()
    }
    
    init(delegate: WalletConnectServiceProtocol) {
        self.delegate = delegate
        initialize()
    }
    
    func updatePendingRequests() {
        do {
            guard let last = try Web3Wallet.instance.getPendingRequests().last else { return }
            logger.debugLog("\(last.id.description)")
        } catch {
            logger.debugLog(error.localizedDescription)
        }
    }
    
    func initialize() {
        Web3Wallet.instance.sessionRequestPublisher.delay(for: 2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                logger.debugLog("wc: --- sessionRequestPublisher \(session)")
                self?.delegate?.showSessionRequest(with: session.request)
            }.store(in: &publishers)
        
        Web3Wallet.instance.sessionProposalPublisher.delay(for: 2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                logger.debugLog("wc: --- sessionProposalPublisher \(session)")
                self?.delegate?.showSessionProposal(with: session.proposal, context: session.context)
            }
            .store(in: &publishers)
        
        //TODO: - possibly we will add this `sign message` flow also. but for now, there is no such reque
        Web3Wallet.instance.authRequestPublisher.delay(for: 2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { session in
                logger.debugLog("wc: --- authRequestPublisher \(session)")
            }
            .store(in: &publishers)
    }
    
    public func pair(_ address: String) async {
        guard let uri = WalletConnectURI(string: address) else { return }
        guard currrentPairingAddress != address else { return }
        
        self.currrentPairingAddress = address
        
        
        LegacyLogger.debug("wc: `pair.address` -- \(uri)")
        do {
            try await Web3Wallet.instance.pair(uri: uri)
        } catch {
            LegacyLogger.debug("wc: `pair` error -- \(error.localizedDescription)")
            self.currrentPairingAddress = nil
            if let pairing = Web3Wallet.instance.getPairings().first(where: { $0.topic == uri.topic }) {
                do {
                    try await Web3Wallet.instance.disconnectPairing(topic: pairing.topic)
                    LegacyLogger.debug("wc: `cleanup.getPairings` -- \(Web3Wallet.instance.getPairings())")
                } catch {
                    LegacyLogger.debug("wc: `disconnectPairing` error -- \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func pair(_ uri: WalletConnectURI) async {
        LegacyLogger.debug("wc: `pair.address` -- \(uri)")
        do {
            try await Web3Wallet.instance.pair(uri: uri)
        } catch {
            do {
                try await Web3Wallet.instance.cleanup()
            } catch {
                LegacyLogger.debug("wc: `disconnectPairing` error -- \(error.localizedDescription)")
            }
        }
    }
    
    private func subscribeSessionProposals() {
        Web3Wallet.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                LegacyLogger.debug("wc: --- sessionProposalPublisher \(session)")
                self?.delegate?.showSessionProposal(with: session.proposal, context: session.context)
            }
            .store(in: &publishers)
    }
    
    private func subscribeSessionRequest() {
        Web3Wallet.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                LegacyLogger.debug("wc: --- sessionRequestPublisher \(session)")
                self?.delegate?.showSessionRequest(with: session.request)
            }.store(in: &publishers)
    }
}
