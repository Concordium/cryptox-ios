//
//  SessionRequestViewModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine
import ReownWalletKit


final class SessionRequestViewModel: ObservableObject {
    @Published var account: AccountEntity?
    @Published var isSignButtonEnabled: Bool = false
    @Published var errorText: String?
    @Published var shouldRejectOnDismiss =  true
    @Published var error: SessionRequstError?
    
    @Published var message: String
    @Published var method: String
    
    private let sessionRequest: Request
    private var cancellables = [AnyCancellable]()
    private var requestModel: SessionRequestDataProvidable?
    
    @Published var requestType: SessionRequestDataType?
    
    /// Model will be used for future iteration of UI when we wanted to show more user-friedly request parameters, instead of
    /// showing them as plain json inside message scroll view
    @Published var reownSessionRequest: ReownSessionRequest?
    
    init(
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        storageManager: StorageManagerProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate()
    ) {
        self.sessionRequest = sessionRequest
        self.message = String(describing: sessionRequest.params.value)
        self.method = sessionRequest.method
                
        if let json = try? sessionRequest.params.json(), let jsonData = json.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                let sessionRequest = try decoder.decode(ReownSessionRequest.self, from: jsonData)
                self.reownSessionRequest = sessionRequest
            } catch {
                print("Error decoding session request: \(error)")
            }
        }
                
        Task {
            await MainActor.run {
                do {
                    let (type, account) = try IncomeRequestValidator.validate(sessionRequest, storageManager: storageManager)
                    self.account = account
                    self.requestType = type
                    self.requestModel = SessionRequestDataModelProvider.model(
                        for: type,
                        account: account,
                        sessionRequest: sessionRequest,
                        transactionsService: transactionsService,
                        mobileWallet: mobileWallet,
                        passwordDelegate: passwordDelegate,
                        storageManager: storageManager
                    )
                } catch is SessionRequstError {
                    self.error = error
                } catch {
                    logger.debug("unknown error --- \(error)")
                }
            }
        }
        
        sheckAllSetUp()
    }
    
    private func sheckAllSetUp() {
        Task {
            guard let requestModel = self.requestModel else {
                self.isSignButtonEnabled = true
                return
            }
            
            self.isSignButtonEnabled = try await requestModel.checkAllSatisfy()
        }
    }
    
    @MainActor
    func approveRequest(_ completion: () -> Void) async {
        self.shouldRejectOnDismiss = false
        self.errorText = nil
                
        do {
            try await requestModel?.approveRequest()
            completion()
        } catch is SessionRequstError {
            self.errorText = error?.errorMessage ?? "Can't find apropriate acount to sign"
        } catch {
            self.errorText = "Can't find apropriate acount to sign"
        }
    }
    
    @MainActor
    func rejectRequest(_ completion: () -> Void) async {
        do {
            try await Sign.instance.respond(
                topic: sessionRequest.topic,
                requestId: sessionRequest.id,
                response: .error(.init(code: 0, message: ""))
            )
            completion()
        } catch {
            self.errorText = "Cant reject this tx. Try again later"
        }
    }
}
