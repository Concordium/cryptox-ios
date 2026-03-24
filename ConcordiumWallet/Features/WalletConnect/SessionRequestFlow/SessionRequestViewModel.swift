import Foundation
import Combine
import ReownWalletKit
import Concordium

struct TransactionDetail {
    let label: String
    let value: String
    let isAddress: Bool
}

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
    @Published var sponsoredTxAmount: CCD?
    @Published var iconName: String = ""
    var sponsor: String?
    
    var formattedTransactionDetails: (type: String, details: [TransactionDetail])? {
        guard let requestType = requestType else { return nil }
        
        switch requestType {
        case .simpleTransfer(let params):
            return formatSimpleTransfer(params: params)
        case .signAndSend(let params):
            return formatContractUpdate(params: params)
        case .signMessage(let payload):
            return formatSignMessage(payload: payload)
        case .tokenUpdate(let params):
            return formatTokenUpdate(params: params)
        case .sponsoredTransaction(let params):
            return formatSponsoredTransaction(params: params)
        case .verifiablePresentation, .verifiablePresentationV1:
            // VerifiablePresentation has its own custom view (VerifiablePresentationRequestParamsView)
            return nil
        }
    }

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

        Task { @MainActor in
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
                if case .verifiablePresentation = type {
                    self.iconName = "identity-scan"
                } else if case .verifiablePresentationV1 = type {
                    self.iconName = "identity-scan"
                } else {
                    self.iconName = "wallet-coin"
                }
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
                            self?.isSignButtonEnabled = isValid
                        }
                        .store(in: &self.cancellables)
                }
                
                // Subscribe to anchor loading state for v1 requests to re-run validation when anchor loads
                if case .verifiablePresentationV1 = type,
                   let v1Model = self.requestModel as? VerifiablePresentationV1RequestModel {
                    v1Model.$isLoadingAnchor
                        .dropFirst()
                        .filter { !$0 }
                        .sink { [weak self] _ in
                            Task { @MainActor in
                                self?.sheckAllSetUp()
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

    private func sheckAllSetUp() {
        Task { @MainActor in
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
            } else if let v1Model = requestModel as? VerifiablePresentationV1RequestModel,
                      let modelError = v1Model.error {
                self.error = .generic(modelError.description)
            } else if requestModel is SponsoredTransactionRequestModel {
                // More specific error message for sponsored transactions
                self.error = .generic("Failed to process sponsored transaction: \(error.localizedDescription)")
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
    
    // MARK: - Formatting Helpers
    
    private func formatSimpleTransfer(params: SimpleTransferRequestParams) -> (type: String, [TransactionDetail]) {
        var details: [TransactionDetail] = []

        // Amount
        if let amount = Int(params.payload.amount) {
            let formattedAmount = TokenFormatter.formatCCD(microCCD: amount, fractionDigits: 2)
            details.append(TransactionDetail(
                label: "Amount",
                value: "\(formattedAmount) CCD",
                isAddress: false
            ))
        } else {
            details.append(TransactionDetail(
                label: "Amount",
                value: params.payload.amount,
                isAddress: false
            ))
        }
        
        // To Address
        let address = params.payload.toAddress
        details.append(TransactionDetail(
            label: "Recipient",
            value: address.prefix(4) + "..." + address.suffix(4),
            isAddress: true
        ))
        
        return ("Transfer", details)
    }
    
    private func formatContractUpdate(params: ContractUpdateRequestParams) -> (type: String, [TransactionDetail]) {
        var details: [TransactionDetail] = []
        
        // Type
        let typeString = params.type.rawValue.capitalized
        
        // Amount
        if let amount = Int(params.payload.amount) {
            let formattedAmount = TokenFormatter.formatCCD(microCCD: amount, fractionDigits: 2)
            details.append(TransactionDetail(
                label: "Amount",
                value: "\(formattedAmount) CCD",
                isAddress: false
            ))
        } else {
            details.append(TransactionDetail(
                label: "Amount",
                value: params.payload.amount,
                isAddress: false
            ))
        }
        
        // From Address
        details.append(TransactionDetail(
            label: "From",
            value: params.sender,
            isAddress: true
        ))
        
        // Contract Address
        let contractAddress = "\(params.payload.address.index ?? 0),\(params.payload.address.subindex ?? 0)"
        details.append(TransactionDetail(
            label: "Contract",
            value: contractAddress,
            isAddress: false
        ))
        
        // Receive Name
        if !params.payload.receiveName.isEmpty {
            details.append(TransactionDetail(
                label: "Function",
                value: params.payload.receiveName,
                isAddress: false
            ))
        }
        
        return (typeString, details)
    }
    
    private func formatSignMessage(payload: SignMessagePayload) -> (type: String, [TransactionDetail]) {
        var details: [TransactionDetail] = []
        
        // Message - show in a scrollable view if long
        let messageText = payload.message.isEmpty ? "Empty message" : payload.message
        details.append(TransactionDetail(
            label: "Message",
            value: messageText,
            isAddress: false
        ))
        
        return ("Sign Message", details)
    }
    
    private func formatTokenUpdate(params: TokenUpdateRequestParams) -> (type: String, [TransactionDetail]) {
        var details: [TransactionDetail] = []
        
        // Token ID
        details.append(TransactionDetail(
            label: "Token",
            value: params.payload.tokenId,
            isAddress: false
        ))
        
        // Try to parse operations to get transfer details
        do {
            let operations = try params.parseOperations()
            if let firstOperation = operations.first,
               case .transfer(let transferPayload) = firstOperation {
                // Amount
                let formattedAmount = TokenFormatter.formatPLTTokenWithDecimals(
                    String(transferPayload.amount.value),
                    decimals: transferPayload.amount.decimals
                )
                details.append(TransactionDetail(
                    label: "Amount",
                    value: formattedAmount,
                    isAddress: false
                ))
                
                // To Address
                let receiverData = transferPayload.receiver.data
                if let receiverAddress = try? AccountAddress(Data(receiverData)) {
                    details.append(TransactionDetail(
                        label: "To",
                        value: receiverAddress.base58Check,
                        isAddress: true
                    ))
                }
                
                // Memo (if present)
                if let memo = transferPayload.memo,
                   memo.content.isEmpty == false,
                   let memoString = memo.asString() {
                    details.append(TransactionDetail(
                        label: "Memo",
                        value: memoString,
                        isAddress: false
                    ))
                }
            }
        } catch {
            // If parsing fails, just show basic info
            logger.debug("Failed to parse token update operations: \(error)")
        }
        
        // From Address
        details.append(TransactionDetail(
            label: "From",
            value: params.sender,
            isAddress: true
        ))
        
        return ("PLT Token Transfer", details)
    }
    
    private func formatSponsoredTransaction(params: SponsoredTransactionRequestParams) -> (type: String, [TransactionDetail]) {
        var details: [TransactionDetail] = []
        
        // Decode header using SDK
        if let header = try? AccountTransactionHeaderV1.decode(from: params.header) {
            // Transaction fee is free (sponsored)
            if let sponsor = header.sponsor {
                details.append(TransactionDetail(
                    label: "Transaction Fee",
                    value: sponsor.base58Check,
                    isAddress: false
                ))
                self.sponsor = sponsor.base58Check
            }
        }
        
        // Decode payload to show transaction details using SDK helper
        if let payload = try? AccountTransaction.decodePayload(from: params.payload) {
            
            switch payload {
            case .transfer(let amount, let receiver, let memo):
                // Amount
                let formattedAmount = TokenFormatter.formatCCD(microCCD: Int(amount.microCCD), fractionDigits: 2)
                details.append(TransactionDetail(
                    label: "Amount",
                    value: "\(formattedAmount) CCD",
                    isAddress: false
                ))
                
                // Recipient
                details.append(TransactionDetail(
                    label: "Recipient",
                    value: receiver.base58Check,
                    isAddress: true
                ))
                
                // Memo (if present)
                if let memo = memo, !memo.value.isEmpty {
                    let memoString = memo.stringValue
                    if !memoString.isEmpty {
                        details.append(TransactionDetail(
                            label: "Memo",
                            value: memoString,
                            isAddress: false
                        ))
                    }
                }
                
            case .updateContract(let amount, let address, let receiveName, _):
                // Amount
                let formattedAmount = TokenFormatter.formatCCD(microCCD: Int(amount.microCCD), fractionDigits: 2)
                details.append(TransactionDetail(
                    label: "Amount",
                    value: "\(formattedAmount) CCD",
                    isAddress: false
                ))
                
                // Contract
                details.append(TransactionDetail(
                    label: "Contract",
                    value: "\(address.index),\(address.subindex)",
                    isAddress: false
                ))
                
                // Function
                details.append(TransactionDetail(
                    label: "Function",
                    value: receiveName.description,
                    isAddress: false
                ))
                
            case .updatePLT(let tokenId, _):
                details.append(TransactionDetail(
                    label: "Token",
                    value: tokenId,
                    isAddress: false
                ))
            case .configureDelegation(let data):
                Task { @MainActor in
                    sponsoredTxAmount = data.capital
                }

                let formattedAmount = TokenFormatter.formatCCD(microCCD: Int(data.capital?.microCCD ?? 0), fractionDigits: 2)

                
                // Target
                let target = data.delegationTarget == .passive ? "Passive delegation" : "Validator pool"
                details.append(TransactionDetail(label: "Target", value: target, isAddress: false))
                
                // Amount
                details.append(TransactionDetail(label: "Amount", value: formattedAmount, isAddress: false))
                
                // Delegation
                if let delegationAmount = account?.delegation?.stakedAmount {
                    let formattedDelegationAmount = TokenFormatter.formatCCD(microCCD: Int(delegationAmount), fractionDigits: 2)
                    details.append(TransactionDetail(label: "Delegation", value: formattedDelegationAmount, isAddress: false))
                }
                
                // Delegation Cooldown
                if let isInCooldown = account?.delegation?.isInCooldown, isInCooldown {
                    let dependencyProvider = ServicesProvider.defaultProvider()
                    let chainParams = dependencyProvider.storageManager().getChainParams()
                    let cooldown = chainParams?.delegatorCooldown
                    if let cooldown {
                        let cooldownDays = cooldown == 1 ? "1 day" : "\(cooldown) days"
                        details.append(TransactionDetail(label: "Delegation Cooldown", value: cooldownDays, isAddress: false))
                    }
                }
                
                // Rewards
                let reward = (data.restakeEarnings ?? false) ? "Added to delegation amount" : "At disposal"
                details.append(TransactionDetail(label: "Rewards", value: reward, isAddress: false))
            default:
                // For other types, just show basic info
                details.append(TransactionDetail(
                    label: "Transaction Type",
                    value: String(describing: payload).components(separatedBy: "(").first ?? "Unknown",
                    isAddress: false
                ))
            }
        }
        
        return ("", details)
    }
}
