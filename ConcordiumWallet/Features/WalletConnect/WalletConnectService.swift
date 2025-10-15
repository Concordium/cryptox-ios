//
//  WalletConnectService.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 19.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import SwiftUI
import Combine
import BigInt
import ReownWalletKit

private let CONCORDIUM_WALLET_CONNECT_PROJECT_ID = "76324905a70fe5c388bab46d3e0564dc"

protocol WalletConnectServiceProtocol: AnyObject {
    func showSessionProposal(with proposal: Session.Proposal, context: VerifyContext?, redirectURL: String?)
    func showSessionRequest(with request: Request, redirectURL: String?)
}

final class WalletConnectService {
    weak var delegate: WalletConnectServiceProtocol?

    private var publishers = [AnyCancellable]()
    private var redirectURL: String?
    
    init() {
        initialize()
        subscribeEvents()
    }

    func initialize() {
        let metadata = AppMetadata(
            name: "CryptoX",
            description: "CryptoX - Blockchain Wallet",
            url: "https://apps.apple.com/app/cryptox-wallet/id1593386457",
            icons: ["https://is2-ssl.mzstatic.com/image/thumb/Purple122/v4/d2/76/4f/d2764f4a-cb11-2039-7edf-7bb1a7ea36d8/AppIcon-1x_U007emarketing-0-5-0-sRGB-85-220.png/230x0w.png"],
            redirect: try! AppMetadata.Redirect(native: "cryptox://", universal: nil)
        )
                
        Pair.configure(metadata: metadata)
        
#if TESTNET
        var groupIdentifier: String = "group.reown.testnet"
#elseif MAINNET
        var groupIdentifier: String = "group.reown.mainnet"
#else // Staging
        var groupIdentifier: String = "group.reown.testnet"
#endif
        
        Networking.configure(
            groupIdentifier: groupIdentifier,
            projectId: CONCORDIUM_WALLET_CONNECT_PROJECT_ID,
            socketFactory: DefaultSocketFactory()
        )
        Sign.configure(crypto: WC2CryptoProvider())
    }
    
    func subscribeEvents() {
        Sign.instance.sessionRequestPublisher.delay(for: 2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                logger.debugLog("wc: --- sessionRequestPublisher \(session)")
                self?.delegate?.showSessionRequest(with: session.request, redirectURL: self?.redirectURL)
            }.store(in: &publishers)
        
        Sign.instance.sessionProposalPublisher.delay(for: 2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                logger.debugLog("wc: --- sessionProposalPublisher \(session)")
                self?.delegate?.showSessionProposal(with: session.proposal, context: session.context, redirectURL: self?.redirectURL)
            }
            .store(in: &publishers)
    }
    
    public func pair(_ address: String) async {
        redirectURL = extractRedirectFromURL(address)
        
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
    
    private func extractRedirectFromURL(_ urlString: String) -> String? {
        // Parse the URL to extract redirect parameter
        // Example: cryptoxtestnet://wc:302e268a7f80c4d6cc8a77496b082d723ea361142449afd2e660ae285ad09229@2?relay-protocol=irn&symKey=a7857c3b36f5e80403c178e2fce34790d94be58323f5ba94042c65a3da6ad299&redirect=googlechrome://
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return queryItems.first(where: { $0.name == "redirect" })?.value
    }
    
    func getRedirectURL() -> String? {
        return redirectURL
    }
    
    private func subscribeSessionProposals() {
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                LegacyLogger.debug("wc: --- sessionProposalPublisher \(session)")
                self?.delegate?.showSessionProposal(with: session.proposal, context: session.context, redirectURL: self?.redirectURL)
            }
            .store(in: &publishers)
    }
    
    private func subscribeSessionRequest() {
        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                LegacyLogger.debug("wc: --- sessionRequestPublisher \(session)")
                self?.delegate?.showSessionRequest(with: session.request, redirectURL: self?.redirectURL)
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
