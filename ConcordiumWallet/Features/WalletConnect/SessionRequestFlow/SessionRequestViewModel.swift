import Foundation
import Combine
import ReownWalletKit

final class SessionRequestViewModel: ObservableObject {
    @Published var account: AccountEntity?
    @Published var isSignButtonEnabled: Bool = false
    @Published var shouldRejectOnDismiss = true
    @Published var error: SessionRequstError?

    @Published var message: String
    @Published var method: String
    @Published var title: String = "Sign Transaction"

    @Published var requestModel: SessionRequestDataProvidable?
    @Published var requestType: SessionRequestDataType?
    
    @Published var pltTokenBalance: String?
    @Published var pltValidationError: String?

    private let sessionRequest: Request
    private var cancellables = [AnyCancellable]()
    private let redirectURL: String?

    init(
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        storageManager: StorageManagerProtocol,
        mobileWallet: MobileWalletProtocol,
        concordiumClient: ConcordiumClient,
        identitiesService: SeedIdentitiesService,
        passwordDelegate: RequestPasswordDelegate = DummyRequestPasswordDelegate(),
        redirectURL: String? = nil
    ) {
        self.sessionRequest = sessionRequest
        self.redirectURL = redirectURL
        self.message = String(describing: sessionRequest.params.value)
        self.method = sessionRequest.method

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
                        storageManager: storageManager,
                        concordiumClient: concordiumClient,
                        identitiesService: identitiesService
                    )
                    self.title = self.requestModel?.title ?? "Sign Transaction"
                    
                    // Update message with formatted payload for tokenUpdate requests
                    if case .tokenUpdate = type,
                       let tokenUpdateModel = self.requestModel as? TokenUpdateRequestModel {
                        self.message = tokenUpdateModel.getFormattedMessage()
                        
                        // Subscribe to token balance and validation error updates
                        tokenUpdateModel.$tokenBalance
                            .assign(to: \.pltTokenBalance, on: self)
                            .store(in: &self.cancellables)
                        
                        tokenUpdateModel.$validationError
                            .assign(to: \.pltValidationError, on: self)
                            .store(in: &self.cancellables)
                        
                        // Subscribe to validation state to update button when validation completes
                        // Validation runs automatically after balance is loaded in the model's init
                        tokenUpdateModel.$isTokenValid
                            .sink { [weak self] isValid in
                                Task { @MainActor in
                                    self?.isSignButtonEnabled = isValid
                                }
                            }
                            .store(in: &self.cancellables)
                    }
                    
                    // Run initial validation for all request types
                    // For tokenUpdate, full validation will run after balance is loaded (in model's init)
                    sheckAllSetUp()
                } catch let err as SessionRequstError {
                    self.error = err
                    logger.debug("\(err.errorMessage)")
                } catch {
                    logger.debug("Unknown error: \(error)")
                }
            }
        }
    }

    private func sheckAllSetUp() {
        Task {
            guard let requestModel = self.requestModel else {
                self.isSignButtonEnabled = true
                return
            }

            do {
                self.isSignButtonEnabled = try await requestModel.checkAllSatisfy()
            } catch {
                // If validation fails, disable the button
                self.isSignButtonEnabled = false
            }
        }
    }

    @MainActor
    func approveRequest(_ completion: ((_ redirectURL: String?) -> Void)? = nil) async {
        self.shouldRejectOnDismiss = false
        self.error = nil

        do {
            try await requestModel?.approveRequest()
            completion?(redirectURL)
        } catch let modelError as SessionRequstError {
            self.error = modelError
        } catch {
            if let verifiableModel = requestModel as? VerifiablePresentationRequestModel,
               let modelError = verifiableModel.error {
                self.error = .generic(modelError.description)
            } else {
                self.error = .generic("Unable to fulfill the request. Please check your identity details.")
            }
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
            self.error = .generic("Can't reject this transaction. Try again later.")
        }
    }
}
