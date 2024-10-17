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

private let CONCORDIUM_WALLET_CONNECT_PROJECT_ID = "76324905a70fe5c388bab46d3e0564dc"

protocol WalletConnectServiceProtocol: AnyObject {
    func showSessionProposal(with proposal: Session.Proposal, context: VerifyContext?)
    func showSessionRequest(with request: Request)
}

final class WalletConnectService {
    weak var delegate: WalletConnectServiceProtocol?

    private var publishers = [AnyCancellable]()
    
    init() {
        let metadata = AppMetadata(
            name: "CryptoX",
            description: "CryptoX - Blockchain Wallet",
            url: "https://apps.apple.com/app/cryptox-wallet/id1593386457",
            icons: ["https://is2-ssl.mzstatic.com/image/thumb/Purple122/v4/d2/76/4f/d2764f4a-cb11-2039-7edf-7bb1a7ea36d8/AppIcon-1x_U007emarketing-0-5-0-sRGB-85-220.png/230x0w.png"]
        )
        
//        Pair.configure(metadata: metadata, crypto: WC2CryptoProvider(), environment: APNSEnvironment.sandbox)
        
        Pair.configure(metadata: metadata)
        Networking.configure(
            projectId: CONCORDIUM_WALLET_CONNECT_PROJECT_ID,
            socketFactory: DefaultSocketFactory()
        )
        initialize()
    }
    
    init(delegate: WalletConnectServiceProtocol) {
        self.delegate = delegate
        initialize()
    }
    
    func initialize() {
//        Sign.configure(crypto: WC2CryptoProvider())
        Sign.instance.sessionRequestPublisher.delay(for: 2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                logger.debugLog("wc: --- sessionRequestPublisher \(session)")
                self?.delegate?.showSessionRequest(with: session.request)
            }.store(in: &publishers)
        
        Sign.instance.sessionProposalPublisher.delay(for: 2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                logger.debugLog("wc: --- sessionProposalPublisher \(session)")
                self?.delegate?.showSessionProposal(with: session.proposal, context: session.context)
            }
            .store(in: &publishers)
    }
    
    public func pair(_ address: String) async {
        guard let uri = WalletConnectURI(string: address) else { return }
        LegacyLogger.debug("wc: `pair.address` -- \(uri)")
        
        do {
            try await Pair.instance.pair(uri: uri)
        } catch {
            LegacyLogger.debug("wc: `pair` error -- \(error.localizedDescription)")
            if let pairing = Pair.instance.getPairings().first(where: { $0.topic == uri.topic }) {
                do {
                    try await Pair.instance.disconnect(topic: pairing.topic)
                    LegacyLogger.debug("wc: `cleanup.getPairings` -- \(Pair.instance.getPairings())")
                } catch {
                    LegacyLogger.debug("wc: `disconnectPairing` error -- \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func subscribeSessionProposals() {
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                LegacyLogger.debug("wc: --- sessionProposalPublisher \(session)")
                self?.delegate?.showSessionProposal(with: session.proposal, context: session.context)
            }
            .store(in: &publishers)
    }
    
    private func subscribeSessionRequest() {
        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                LegacyLogger.debug("wc: --- sessionRequestPublisher \(session)")
                self?.delegate?.showSessionRequest(with: session.request)
            }.store(in: &publishers)
    }
}

enum CryptoError: Error {
    case notImplemented
}

struct WC2CryptoProvider: CryptoProvider {
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        throw CryptoError.notImplemented
    }

    public func keccak256(_ data: Data) -> Data { data }
}
