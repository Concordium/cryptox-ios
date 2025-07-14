//
//  VerifiablePresentationRequestModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 19.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import ReownWalletKit
import WalletConnectVerify
import Combine
import Concordium

protocol VerifiableStatementsPresentation {
    var credentialStatements: [WalletConnectRequestVerifiablePresentationParam.CredentialStatement] { get }
}

enum VerifiableStatementError {
    case invalidIdentity
    case invalidStatement

    var description: String {
        switch self {
        case .invalidIdentity:
            return "unable_to_prove_request".localized
        case .invalidStatement:
            return "unable_to_prove_request".localized
        }
    }
}

final class VerifiablePresentationRequestModel: ObservableObject, SessionRequestDataProvidable, VerifiableStatementsPresentation {
    @Published var title: String = "Proof Request"
    @Published var credentialStatements: [WalletConnectRequestVerifiablePresentationParam.CredentialStatement]
    @Published var error: VerifiableStatementError?

    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let payload: WalletConnectRequestVerifiablePresentationParam
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    private let concordiumClient: ConcordiumClient
    private let identitiesService: SeedIdentitiesService

    private var verifiablePresentationBuilder: VerifiablePresentationBuilder

    init(
        payload: WalletConnectRequestVerifiablePresentationParam,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate,
        concordiumClient: ConcordiumClient,
        identitiesService: SeedIdentitiesService
    ) {
        self.sessionRequest = sessionRequest
        self.payload = payload
        self.account = account
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
        self.credentialStatements = payload.credentialStatements
        self.identitiesService = identitiesService
        self.concordiumClient = concordiumClient

        self.verifiablePresentationBuilder = VerifiablePresentationBuilder(
            challenge: payload.challenge,
            network: ConcordiumClient.network
        )

        if !Self.validateIdentity(from: payload, account: account) {
            error = .invalidIdentity
        } else if !Self.validateCredentialStatements(payload.credentialStatements, account: account) {
            error = .invalidStatement
        }
    }
    
    static func validateIdentity(from payload: WalletConnectRequestVerifiablePresentationParam, account: AccountEntity) -> Bool {
        payload.credentialStatements
            .compactMap { credentialStatement -> [UInt32] in
                switch credentialStatement {
                case .account(let issuers, statement: _): return issuers
                case .web3id: return []
                }
            }
            .contains { issuers -> Bool in
                guard let ipIdentity = account.identity?.identityProvider?.ipInfo?.ipIdentity else { return false }
                return issuers.contains(where: { $0 == ipIdentity })
            }
    }
    
    static func validateCredentialStatements(
        _ credentialStatements: [WalletConnectRequestVerifiablePresentationParam.CredentialStatement],
        account: AccountEntity
    ) -> Bool {
        let statements = credentialStatements.flatMap {
            switch $0 {
            case .account(_, let statements): return statements
            case .web3id: return []
            }
        }

        let allValid = statements.allSatisfy { isValidStatement($0, account: account) }

        if !allValid {
            print("❌ Invalid statement detected. Statements:")
            statements.forEach { st in
                print("→ \(st): valid = \(isValidStatement(st, account: account))")
            }
        }

        return allValid
    }

    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        return error == nil && statements().allSatisfy { Self.isValidStatement($0, account: account) }
    }

    @MainActor
    func approveRequest() async throws {
        guard error == nil else {
            throw GeneralAppError.somethingWentWrong
        }

        guard statements().isEmpty == false else {
            throw GeneralAppError.somethingWentWrong
        }

        guard statements().allSatisfy({ Self.isValidStatement($0, account: account) }) else {
            throw GeneralAppError.somethingWentWrong
        }

        let pass = try await passwordDelegate.requestUserPassword(keychain: KeychainWrapper())
        let phrase = try await identitiesService.mobileWallet.getRecoveryPhrase(pwHash: pass)
        let seed = phrase.joined(separator: " ")

        let walletSeed = try Helper.decodeSeed(seed, ConcordiumClient.network)
        let cryptoParams = try await concordiumClient.nodeClient.cryptographicParameters(block: .lastFinal)
        let credentialIndices = AccountCredentialSeedIndexes(
            identity: IdentitySeedIndexes(
                providerID: IdentityProviderID(account.identity?.identityProvider?.ipInfo?.ipIdentity ?? 0),
                index: IdentityIndex(account.identity?.index ?? 0)),
            counter: CredentialCounter(account.identityEntity?.accountsCreated ?? 0)
        )

        guard let identityObjectApp = account.identityEntity?.seedIdentityObject else { throw GeneralAppError.somethingWentWrong }
        guard let data = try identityObjectApp.json().data(using: .utf8) else { throw GeneralAppError.somethingWentWrong }

        let identityObject = try JSONDecoder().decode(Concordium.IdentityObject.self, from: data)

        try verifiablePresentationBuilder
            .verify(statements(),
                    for: identityObject.attributeList.chosenAttributes,
                    wallet: walletSeed,
                    credIndices: credentialIndices,
                    global: cryptoParams
            )

        let finalized: VerifiablePresentation = try verifiablePresentationBuilder.finalize(global: cryptoParams)
        let wrapped = try VerifiableJSON(verifiablePresentationJson: finalized).wrappedAsDictionary()

        try await Sign.instance.respond(
            topic: sessionRequest.topic,
            requestId: sessionRequest.id,
            response: .response(AnyCodable(wrapped))
        )
    }

    private func statements() -> [AtomicIdentityStatement] {
        credentialStatements
            .flatMap {
                switch $0 {
                case let .account(_, statement): return statement
                case .web3id: return []
                }
            }
            .compactMap { $0 }
    }
}

extension VerifiablePresentationRequestModel {
    func getStatementCellModels() -> [VerifiableStatementListCellModel] {
        credentialStatements.flatMap { credentialStatement in
            switch credentialStatement {
            case .account(_, let statements):
                return statements.map(getModel(_:))
            case .web3id:
                return []
            }
        }
    }
    
    private func getModel(_ statement: AtomicIdentityStatement) -> VerifiableStatementListCellModel {
        VerifiableStatementListCellModel(
            title: statement.attributeTag.localizedKey,
            value: Self.valueData(for: statement, account: account) ?? "No Data",
            description: description(for: statement),
            isValid: Self.isValidStatement(statement, account: account)
        )
    }
    
    private func description(for statement: AtomicIdentityStatement) -> String {
        switch statement {
        case .revealAttribute(let s):
            return "This will reveal your \(s.attributeTag.localizedKey)."
        case .attributeInRange(let s):
            switch s.attributeTag {
            case .dateOfBirth:
                if let lowerDate = Date.initWithFormat(with: s.lower),
                   let upperDate = Date.initWithFormat(with: s.upper) {
                    let today = Calendar.current.startOfDay(for: Date())
                    if upperDate < today {
                        let age = VerifiablePresentationRequestModel.yearsBetweenDates(startDate: today, endDate: upperDate)
                        return "This will prove that your Date of birth is before \(upperDate.formatted(date: .long, time: .omitted)) (i.e., you are at least \(age) years old)."
                    } else if lowerDate < today {
                        let age = VerifiablePresentationRequestModel.yearsBetweenDates(startDate: today, endDate: lowerDate)
                        return "This will prove that your Date of birth is after \(lowerDate.formatted(date: .long, time: .omitted)) (i.e., you are younger than \(age))."
                    }
                }
                return "This will prove your age is within a valid range."

            case .idDocExpiresAt:
                if let lower = Date.initWithFormat(with: s.lower) {
                    return "This will prove that your ID document is valid at least until \(lower.formatted(date: .long, time: .omitted))."
                }
                return "This will prove your ID document is valid."

            default:
                return "This will prove your \(s.attributeTag.localizedKey) is within an expected range."

            }

        case .attributeInSet(let s):
            let countryNames = s.set
                .map { ISO3166CountryCodes.countryName(for: $0) }
                .joined(separator: ", ")
            return "This will prove that your \(s.attributeTag.localizedKey) is one of the following: \(countryNames)."

        case .attributeNotInSet(let s):
            let countryNames = s.set
                .map { ISO3166CountryCodes.countryName(for: $0) }
                .joined(separator: ", ")
            return "This will prove that your \(s.attributeTag.localizedKey) is *not* one of the following: \(countryNames)."
        }
    }

    
    static func valueData(for statement: AtomicIdentityStatement, account: AccountEntity) -> String? {
        let attributes = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes ?? [:]

        switch statement {
        case .revealAttribute(let inner):
            let raw = attributes["\(inner.attributeTag.rawValue)"] ?? ""
            return inner.attributeTag.formattedValue(raw)

        case .attributeInSet(let inner):
            let raw = attributes["\(inner.attributeTag.rawValue)"] ?? ""
            return inner.attributeTag.formattedValue(raw)

        case .attributeNotInSet(let inner):
            let raw = attributes["\(inner.attributeTag.rawValue)"] ?? ""
            return inner.attributeTag.formattedValue(raw)

        case .attributeInRange(let inner):
            let tag = inner.attributeTag
            let today = Calendar.current.startOfDay(for: Date())

            guard let lowerDate = Date.initWithFormat(with: inner.lower),
                  let upperDate = Date.initWithFormat(with: inner.upper) else {
                return nil
            }

            if tag == .dateOfBirth {
                return upperDate > today
                    ? "identity_proofs_age_min".localized("\(yearsBetweenDates(startDate: today, endDate: lowerDate))")
                    : "identity_proofs_age_max".localized("\(yearsBetweenDates(startDate: today, endDate: upperDate))")
            } else {
                let raw = attributes["\(tag.rawValue)"] ?? ""
                return tag.formattedValue(raw)
            }
        }
    }


    static func isValidStatement(_ statement: AtomicIdentityStatement, account: AccountEntity) -> Bool {
        let attributes = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes ?? [:]

        switch statement {
        case .revealAttribute(let inner):
            return attributes["\(inner.attributeTag)"] != nil

        case .attributeInSet(let inner):
            let value = attributes["\(inner.attributeTag)"] ?? ""
            return inner.set.contains(value)

        case .attributeNotInSet(let inner):
            let value = attributes["\(inner.attributeTag)"] ?? ""
            return !inner.set.contains(value)

        case .attributeInRange(let inner):
            let tag = inner.attributeTag
            let rawValue = attributes["\(tag)"] ?? ""

            switch tag {
            case .dateOfBirth, .idDocIssuedAt, .idDocExpiresAt:
                guard let valueDate = Date.initWithFormat(with: rawValue),
                      let lowerDate = Date.initWithFormat(with: inner.lower),
                      let upperDate = Date.initWithFormat(with: inner.upper)
                else {
                    return false
                }
                return (lowerDate...upperDate).contains(valueDate)

            default:
                let valueDecimal = Decimal(string: rawValue) ?? .zero
                let lower = Decimal(string: inner.lower) ?? .zero
                let upper = Decimal(string: inner.upper) ?? .zero
                return (lower...upper).contains(valueDecimal)
            }
        }
    }
}

extension VerifiablePresentationRequestModel {
    static func yearsBetweenDates(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        return max(0, startYear - endYear)
    }
}

extension VerifiablePresentationRequestModel {
    func getGroupedStatements() -> [String: [VerifiableStatementListCellModel]] {
        var grouped: [String: [VerifiableStatementListCellModel]] = [:]

        credentialStatements.forEach { credentialStatement in
            switch credentialStatement {
            case .account(_, let statements):
                for statement in statements {
                    let model = getModel(statement)
                    let key = statement.groupTitle
                    grouped[key, default: []].append(model)
                }
            case .web3id: break
            }
        }

        return grouped
    }
}

enum ISO3166CountryCodes {
    static func countryName(for code: String) -> String {
        let locale = Locale.current
        return locale.localizedString(forRegionCode: code) ?? code
    }
}
