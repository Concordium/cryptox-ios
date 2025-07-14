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
    @Published var reownSessionRequest: ReownSessionRequest?

    private let sessionRequest: Request
    private var cancellables = [AnyCancellable]()

    init(
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        storageManager: StorageManagerProtocol,
        mobileWallet: MobileWalletProtocol,
        concordiumClient: ConcordiumClient,
        identitiesService: SeedIdentitiesService,
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
                        storageManager: storageManager,
                        concordiumClient: concordiumClient,
                        identitiesService: identitiesService
                    )
                    self.title = self.requestModel?.title ?? "Sign Transaction"
                } catch let err as SessionRequstError {
                    self.error = err
                    logger.debug("\(err.errorMessage)")
                } catch {
                    logger.debug("Unknown error: \(error)")
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
        self.error = nil

        do {
            try await requestModel?.approveRequest()
            completion()
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
