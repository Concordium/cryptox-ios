//
//  AttributeTag+Ext.swift
//  CryptoX
//
//  Created by Max on 07.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import Concordium

extension Concordium.AttributeTag {
    public var localizedKey: String {
        switch self {
            case .firstName: return "attributes.firstName".localized
            case .lastName: return "attributes.lastName".localized
            case .sex: return "attributes.sex".localized
            case .dateOfBirth: return "attributes.dob".localized
            case .countryOfResidence: return "attributes.countryOfResidence".localized
            case .nationality: return "attributes.nationality".localized
            case .idDocType: return "attributes.idDocType".localized
            case .idDocNo: return "attributes.idDocNo".localized
            case .idDocIssuer: return "attributes.idDocIssuer".localized
            case .idDocIssuedAt: return "attributes.idDocIssuedAt".localized
            case .idDocExpiresAt: return "attributes.idDocExpiresAt".localized
            case .nationalIdNo: return "attributes.nationalIDNo".localized
            case .taxIdNo: return "attributes.taxIDNo".localized
            case .legalEntityId: return "attributes.lei".localized
            case .legalName: return "attributes.legalName".localized
            case .legalCountry: return "attributes.legalCountry".localized
            case .businessNumber: return "attributes.businessNumber".localized
            case .registrationAuth: return "attributes.registrationAuth".localized
        }
    }

    public func formattedValue(_ value: String) -> String {
        let formatter = VerifiablePresentationDataFormatter()

        switch self {
            case .firstName, .lastName, .legalName, .registrationAuth:
                return formatter.format(name: value)

            case .idDocNo, .nationalIdNo, .taxIdNo, .businessNumber:
                return formatter.format(plainNumber: value)

            case .dateOfBirth:
                return formatter.format(dateOfBirth: value)

            case .idDocIssuedAt, .idDocExpiresAt:
                return formatter.format(date: value)

            case .countryOfResidence, .nationality, .idDocIssuer, .legalCountry:
                return formatter.format(countryCode: value)

            case .sex:
                return formatter.format(sex: value)

            case .idDocType:
                return formatter.format(documentType: value)

            case .legalEntityId:
            return formatter.formatLei(value)
        }
    }
}
