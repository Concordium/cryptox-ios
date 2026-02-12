import Foundation
import ConcordiumWalletCrypto

extension VerifiablePresentationV1RequestModel {
    func getGroupedStatements() -> [String: [VerifiableStatementListCellModel]] {
        var grouped: [String: [VerifiableStatementListCellModel]] = [:]

        let statements = extractStatements()
        for statement in statements {
            let model = getModel(statement)
            let key = statement.groupTitle
            grouped[key, default: []].append(model)
        }

        return grouped
    }

    private func getModel(_ statement: AtomicStatementV1) -> VerifiableStatementListCellModel {
        let attributeTag = getAttributeTag(from: statement)
        let value = Self.valueData(for: statement, account: account) ?? "No Data"
        let description = Self.description(for: statement)
        let isValid = Self.isValidStatement(statement, account: account)

        return VerifiableStatementListCellModel(
            title: attributeTag.localizedKey,
            value: value,
            description: description,
            isValid: isValid
        )
    }

    private func getAttributeTag(from statement: AtomicStatementV1) -> AttributeTag {
        switch statement {
        case .attributeValue(let s):
            return s.attributeTag
        case .attributeInRange(let s):
            return s.attributeTag
        case .attributeInSet(let s):
            return s.attributeTag
        case .attributeNotInSet(let s):
            return s.attributeTag
        }
    }

    static func description(for statement: AtomicStatementV1) -> String {
        switch statement {
        case .attributeValue(let s):
            return "This will reveal your \(s.attributeTag.localizedKey)."
        case .attributeInRange(let s):
            switch s.attributeTag {
            case .dateOfBirth:
                let lowerStr = web3IdAttributeToString(s.lower)
                let upperStr = web3IdAttributeToString(s.upper)
                if let lowerDate = Date.initWithFormat(with: lowerStr),
                   let upperDate = Date.initWithFormat(with: upperStr) {
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
                let lowerStr = web3IdAttributeToString(s.lower)
                if let lower = Date.initWithFormat(with: lowerStr) {
                    return "This will prove that your ID document is valid at least until \(lower.formatted(date: .long, time: .omitted))."
                }
                return "This will prove your ID document is valid."
            default:
                return "This will prove your \(s.attributeTag.localizedKey) is within an expected range."
            }
        case .attributeInSet(let s):
            let setStrings = s.set.map { web3IdAttributeToString($0) }
            let countryNames = setStrings
                .map { ISO3166CountryCodes.countryName(for: $0) }
                .joined(separator: ", ")
            return "This will prove that your \(s.attributeTag.localizedKey) is one of the following: \(countryNames)."
        case .attributeNotInSet(let s):
            let setStrings = s.set.map { web3IdAttributeToString($0) }
            let countryNames = setStrings
                .map { ISO3166CountryCodes.countryName(for: $0) }
                .joined(separator: ", ")
            return "This will prove that your \(s.attributeTag.localizedKey) is *not* one of the following: \(countryNames)."
        }
    }

    static func valueData(for statement: AtomicStatementV1, account: AccountEntity) -> String? {
        let attributes = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes ?? [:]
        let attributeTag = getAttributeTag(from: statement)

        switch statement {
        case .attributeValue,
             .attributeInRange,
             .attributeInSet,
             .attributeNotInSet:
            let raw = attributes[attributeTag.description] ?? ""
            return attributeTag.formattedValue(raw)
        }
    }

    static func isValidStatement(_ statement: AtomicStatementV1, account: AccountEntity) -> Bool {
        let attributes = account.identityEntity?.seedIdentityObject?.attributeList.chosenAttributes ?? [:]
        let attributeTag = getAttributeTag(from: statement)
        let rawValue = attributes[attributeTag.description] ?? ""

        switch statement {
        case .attributeValue:
            return !rawValue.isEmpty
        case .attributeInRange(let s):
            let lowerStr = web3IdAttributeToString(s.lower)
            let upperStr = web3IdAttributeToString(s.upper)

            switch attributeTag {
            case .dateOfBirth, .idDocIssuedAt, .idDocExpiresAt:
                guard let valueDate = Date.initWithFormat(with: rawValue),
                      let lowerDate = Date.initWithFormat(with: lowerStr),
                      let upperDate = Date.initWithFormat(with: upperStr) else {
                    return false
                }
                let isValid = (lowerDate...upperDate).contains(valueDate)
                return isValid
            default:
                let valueDecimal = Decimal(string: rawValue) ?? .zero
                let lower = Decimal(string: lowerStr) ?? .zero
                let upper = Decimal(string: upperStr) ?? .zero
                return (lower...upper).contains(valueDecimal)
            }
        case .attributeInSet(let s):
            let setStrings = s.set.map { web3IdAttributeToString($0) }
            let isValid = setStrings.contains(rawValue)
            return isValid
        case .attributeNotInSet(let s):
            let setStrings = s.set.map { web3IdAttributeToString($0) }
            let isValid = !setStrings.contains(rawValue)
            return isValid
        }
    }

    private static func getAttributeTag(from statement: AtomicStatementV1) -> AttributeTag {
        switch statement {
        case .attributeValue(let s):
            return s.attributeTag
        case .attributeInRange(let s):
            return s.attributeTag
        case .attributeInSet(let s):
            return s.attributeTag
        case .attributeNotInSet(let s):
            return s.attributeTag
        }
    }

    private static func web3IdAttributeToString(_ attr: Web3IdAttribute) -> String {
        switch attr {
        case .string(let value):
            return value
        case .numeric(let value):
            return String(value)
        case .timestamp(let value):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            return formatter.string(from: value)
        }
    }
}

extension AtomicStatementV1 {
    var groupTitle: String {
        switch self {
        case .attributeValue:
            return "Information to reveal"
        case .attributeInRange, .attributeInSet, .attributeNotInSet:
            return "Zero-knowledge proof"
        }
    }
}

