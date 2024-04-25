//
//  VerifiablePresentationRequestModel.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 19.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Web3Wallet
import WalletConnectVerify
import Combine

protocol VerifiableStatementsPresentation {
    var credentialStatements: [VerifiablePresentationStatements] { get }
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
    
    @Published var credentialStatements: [VerifiablePresentationStatements]
    
    @Published var error: VerifiableStatementError?
    
    private let transactionsService: TransactionsServiceProtocol
    private let mobileWallet: MobileWalletProtocol
    private let payload: VerifiablePresentationRequestParams
    private let account: AccountEntity
    private let sessionRequest: Request
    private let passwordDelegate: RequestPasswordDelegate
    
    init(
        payload: VerifiablePresentationRequestParams,
        account: AccountEntity,
        sessionRequest: Request,
        transactionsService: TransactionsServiceProtocol,
        mobileWallet: MobileWalletProtocol,
        passwordDelegate: RequestPasswordDelegate
    ) {
        self.sessionRequest = sessionRequest
        self.payload = payload
        self.account = account
        self.transactionsService = transactionsService
        self.mobileWallet = mobileWallet
        self.passwordDelegate = passwordDelegate
        
        self.credentialStatements = payload.credentialStatements
                
        if payload.credentialStatements.map({ Self.isValidIdentity(account.identity, for: $0) }).contains(where: { $0 == true }) == false {
            error = .invalidIdentity
        }
        
        if payload.credentialStatements.flatMap({ $0.statement }).map({ statement in
            Self.isValidStatement(statement, account: account)
        }).contains(where: { $0 == true }) == false {
            error = .invalidStatement
        }
    }
    
    @MainActor
    func checkAllSatisfy() async throws -> Bool {
        return error == nil
    }
    
    @MainActor
    func approveRequest() async throws {
//        let result = try await mobileWallet
//            .signMessage(for: account, message: payload.message, requestPasswordDelegate: passwordDelegate)
//            .async()
//        try await Sign.instance.respond(
//            topic: sessionRequest.topic,
//            requestId: sessionRequest.id,
//            response: .response(AnyCodable(result))
//        )
    }
    
    private static func isValidIdentity(_ identity: (any IdentityDataType)?, for statement: VerifiablePresentationStatements) -> Bool {
        // If no `idQualifier` we assume that identity is valid.
        // and proceed with detailed check for each statement
        guard let quelifier = statement.idQualifier else { return true }
        guard let ipIdentity = identity?.identityProvider?.ipInfo?.ipIdentity else { return false }
        
        if #available(iOS 16.0, *) {
            return quelifier.issuers.contains([ipIdentity])
        } else {
            return quelifier.issuers.contains(where: { $0 == ipIdentity })
        }
    }
}


struct VerifiableStatementListCellModel {
    let title: String
    let value: String
    let description: String
    let isValid: Bool
}


extension VerifiablePresentationRequestModel {
    func getModel(for statement: VerifiablePresentationStatement) -> VerifiableStatementListCellModel {
        VerifiableStatementListCellModel(
            title: AttributeFormatter.format(key: statement.attributeTag),
            value: Self.valueData(for: statement, account: account) ?? "no data",
            description: "reveal_description".localized,
            isValid: Self.isValidStatement(statement, account: account)
        )
    }
    
    static func valueData(for statement: VerifiablePresentationStatement, account: AccountEntity) -> String? {
        switch statement.attributeTag {
            case .dob:
                let currentDateTimeless = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: Date())) ?? Date()
                if statement.upperAsDate > Date() {
                    return "identity_proofs_age_min".localized("\(Self.yearsBetweenDates(startDate: currentDateTimeless, endDate: statement.lowerAsDate))")
                } else {
                    return "identity_proofs_age_max".localized("\(Self.yearsBetweenDates(startDate: currentDateTimeless, endDate: statement.upperAsDate))")
                }
            case .firstName, .lastName:
                return account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue]
            case .sex:
                return "fix me - sex"
            case .countryOfResidence:
                return "fix me - countryOfResidence"
            case .nationality:
                return "fix me - nationality"
            case .idDocType:
                return "fix me - idDocType"
            case .idDocNo:
                return "fix me - idDocNo"
            case .idDocIssuer:
                return account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue]
            case .idDocIssuedAt:
                return "fix me - idDocIssuedAt"
            case .idDocExpiresAt:
                return "fix me - idDocExpiresAt"
            case .nationalIdNo:
                return "fix me - nationalIdNo"
            case .taxIdNo:
                return "fix me - taxIdNo"
        }
    }
    
    static func isValidStatement(_ statement: VerifiablePresentationStatement, account: AccountEntity) -> Bool {
        switch statement.type {
            case .revealAttribute:
                return account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue] != nil
            case .attributeInSet:
                guard let set = statement.set else { return false }
                guard let value = valueData(for: statement, account: account) else { return false }
                return set.contains(where: { $0 == value })
            case .attributeNotInSet: return false
            case .attributeInRange:
                let value = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes[statement.attributeTag.rawValue] ?? ""

                switch statement.attributeTag {
                    case .dob, .idDocExpiresAt, .idDocIssuedAt:
                        // due to api returns value for range min and max values in strange way (ISO 8601) as dates: `"18000101"` in format `"yyyyMMdd"`
                        // we cant simply constract an range
                        return (statement.lowerAsDate...statement.upperAsDate).contains(Date.initWithFormat(with: value) ?? Date())
                    default:
                        return Range(uncheckedBounds: (lower: Decimal(string: statement.lower ?? "") ?? .zero, upper: Decimal(string: statement.upper ?? "") ?? .zero)).contains(Decimal(string: value) ?? .zero)
                }
        }
    }
    
    static func yearsBetweenDates(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        
        guard let startYear = calendar.dateComponents([.year], from: startDate).year,
              let endYear = calendar.dateComponents([.year], from: endDate).year else {
            return 0
        }
        
        let difference = endYear - startYear
        
        // Check if endDate is before startDate, adjust difference accordingly
        return endDate < startDate ? -difference : difference
    }
}

extension Date {
    static func initWithFormat(with dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.date(from: dateString)
    }
}
