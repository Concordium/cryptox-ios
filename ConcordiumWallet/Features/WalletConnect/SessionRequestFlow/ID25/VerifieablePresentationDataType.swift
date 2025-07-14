//
//  VerifiablePresentationDataFormatter.swift
//  CryptoX
//
//  Created by Max on 07.07.2025.
//

import Foundation

final class VerifiablePresentationDataFormatter {

    func format(name: String) -> String {
        name
    }

    func format(plainNumber: String) -> String {
        plainNumber
    }

    func format(dateOfBirth: String) -> String {
        GeneralFormatter.formatISO8601Date(date: dateOfBirth, hasDay: true, outputFormat: "dd MMMM, yyyy")
    }

    func format(date: String) -> String {
        GeneralFormatter.formatISO8601Date(date: date, hasDay: true)
    }

    func format(countryCode: String) -> String {
        Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }

    func format(sex: String) -> String {
        switch Sex(rawValue: sex) {
        case .male: return "Male".localized
        case .female: return "Female".localized
        case .unknown: return "sex.notKnown".localized
        case .notApplicable: return "sex.notApplicable".localized
        case .none: return "sex.notKnown".localized
        }
    }

    func format(documentType: String) -> String {
        guard let type = DocumentType(rawValue: documentType) else { return "" }
        switch type {
        case .na: return "Not applicable".localized
        case .passport: return "Passport".localized
        case .nationalIDCard: return "National ID".localized
        case .drivingLicense: return "Driving License".localized
        case .ImmigrationCard: return "Immigration Card".localized
        }
    }

    func formatLei(_ lei: String) -> String {
        lei.isEmpty ? "unavailable".localized : lei
    }
}
