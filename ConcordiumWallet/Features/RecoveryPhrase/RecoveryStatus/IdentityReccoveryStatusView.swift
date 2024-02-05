//
//  IdentityReccoveryStatusView.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 01/08/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct IdentityReccoveryStatusView: Page {
    @ObservedObject var viewModel: IdentityRecoveryStatusViewModel
    
    var pageBody: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.title)
                        .font(Font.system(size: 19, weight: .medium))
                        .foregroundColor(.white)
                    Text(viewModel.message)
                        .font(Font.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(24)
            .padding(.bottom, 24)

            if case let .success(identities, accounts) = viewModel.status {
                IdentityList(
                    identities: identities,
                    accounts: accounts
                )
            } else if case let .partial(identities, accounts, failedIdentityProviders) = viewModel.status {
                IdentityList(
                    identities: identities,
                    accounts: accounts
                )
            }
            Spacer()
            buttons
        }
        .padding(.init(top: 10, leading: 16, bottom: 30, trailing: 16))
        .modifier(AppBackgroundModifier())
    }
    
    @ViewBuilder
    private var buttons: some View {
        switch viewModel.status {
        case .fetching:
            EmptyView()
//        case .emptyResponse:
//            Button(viewModel.tryAgain) {
//                viewModel.send(.fetchIdentities)
//            }
//            .applyStandardButtonStyle()
//            .padding([.bottom], 16)
//            Button(viewModel.changeRecoveryPhrase) {
//                viewModel.send(.changeRecoveryPhrase)
//            }.applyStandardButtonStyle()
        case .success, .emptyResponse:
            Button(viewModel.continueLongLabel) {
                viewModel.send(.finish)
            }.applyStandardButtonStyle()
        case .partial:
            HStack(spacing: 16.0) {
                Button(viewModel.tryAgain) {
                    viewModel.send(.fetchIdentities)
                }
                .applyStandardButtonStyle()
                Button(viewModel.continueLabel) {
                    viewModel.send(.finish)
                }
                .applyStandardButtonStyle()
            }
        }
    }
    
//    private var titleColor: Color {
//        if viewModel.status == .emptyResponse {
//            return Pallette.error
//        } else {
//            return Pallette.primary
//        }
//    }
    
//    private var messageColor: Color {
//        if viewModel.status == .fetching {
//            return Pallette.fadedText
//        } else {
//            return Pallette.text
//        }
//    }
    
    private var imageName: String {
        switch viewModel.status {
        case .fetching:
            return "import_pending"
        case .success, .emptyResponse:
            return "confirm"
        case .partial:
            return "partial"
        }
    }
}

private struct IdentityList: View {
    let identities: [IdentityDataType]
    let accounts: [AccountDataType]
    
    var body: some View {
        List {
            ForEach(identities, id: \.id) { identity in
                VStack {
                    HStack{
                        Text(identity.nickname)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Accounts: \(accounts.filter { $0.identity?.id == identity.id }.count)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.83, green: 0.84, blue: 0.86))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .overlay(
                                Capsule()
                                    .inset(by: 0.5)
                                    .stroke(Color.blackAditional.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .padding(20)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))

                    
                    ForEach(accounts, id: \.address) { account in
                        if account.identity!.id == identity.id {
                            HStack {
                                Text(account.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.73, green: 0.75, blue: 0.78))
                                Spacer()
                                Text(GTU(intValue: account.finalizedBalance).displayValueWithCCDStroke())
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(20)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(SwiftUI.EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .inset(by: 0.5)
                        .stroke(Color.blackAditional.opacity(0.4), lineWidth: 1)
                )
                .padding(.bottom, 16)
            }
        }
        .listRowBackground(Color.clear)
        .listStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct IdentityReccoveryStatusView_Previews: PreviewProvider {
    static var previews: some View {
        IdentityReccoveryStatusView(
            viewModel: .init(
                status: .success([TestIdentity.test, TestIdentity.test], [TestAccountDataType.test, TestAccountDataType.test]),//.success([IdentityEntity()], [AccountEntity()]),
                title: "Recovering IDs and accounts",
                message: "Scanning the Concordium blockchain. Hang on while we find your account and identities.",
                continueLongLabel: "Continue to wallet",
                continueLabel: "Continue",
                tryAgain: "Try again"
//                changeRecoveryPhrase: "Enter another recovery phrase"
            )
        )
        
//        IdentityReccoveryStatusView(
//            viewModel: .init(
//                status: .emptyResponse,
//                title: "We found nothing to recover.",
//                message: """
//There was no accounts to be found for the secret recovery phrase. Did you maybe enter a wrong recovery phrase?
//
//If you only have an identity and no accounts, this can also be the reason. In this case please specify which identity provider you used to get your identity, so we can send them a request.
//""",
//                continueLabel: "Continue to wallet",
//                tryAgain: "Try again"
////                changeRecoveryPhrase: "Enter another recovery phrase")
//        )
        
//        IdentityReccoveryStatusView(
//            viewModel: .init(
//                status: .success([IdentityEntity()], [AccountEntity()]),
//                title: "Recovery finished",
//                message: "You have successfully recovered:",
//                continueLabel: "Continue to wallet",
//                tryAgain: "Try again"
////                changeRecoveryPhrase: "Enter another recovery phrase"
//            )
//        )
    }
}


private extension TestIdentity {
    static let test: TestIdentity = TestIdentity(
        accountsCreated: 0,
        nickname: "test",
        index: 0,
        state: .confirmed,
        ipStatusUrl: "",
        identityCreationError: ""
    )
}

private final class TestIdentity: IdentityDataType {
    func write(code: (TestIdentity) -> Void) -> Result<Void, Error> {
        .success(())
    }
    
    var id: String = UUID().uuidString
    var accountsCreated: Int = 1
    var nickname: String = "test"
    var index: Int = 0
    var state: IdentityState = .confirmed
    var ipStatusUrl: String = "never"
    var identityCreationError: String = "never"
    
    var identityProvider: IdentityProviderDataType?
    var identityObject: IdentityObject?
    var seedIdentityObject: SeedIdentityObject?
    var encryptedPrivateIdObjectData: String?
    var identityProviderName: String?
    var hashedIpStatusUrl: String?
    
    init(
        accountsCreated: Int,
        nickname: String,
        index: Int,
        state: IdentityState,
        ipStatusUrl: String,
        identityCreationError: String
    ) {
        self.accountsCreated = accountsCreated
        self.nickname = nickname
        self.index = index
        self.state = state
        self.ipStatusUrl = ipStatusUrl
        self.identityCreationError = identityCreationError
    }
}

private extension TestAccountDataType {
    static var test = TestAccountDataType.init(
        displayName: "test data type",
        address: "some addres",
        accountIndex: 1,
        identity: TestIdentity.test,
        revealedAttributes: [:],
        finalizedBalance: 2,
        forecastBalance: 3,
        finalizedEncryptedBalance: 4,
        forecastEncryptedBalance: 5,
        totalForecastBalance: 6,
        accountNonce: 7,
        createdTime: Date(),
        usedIncomingAmountIndex: 0,
        isReadOnly: false,
        showsShieldedBalance: true,
        hasShieldedTransactions: false
    )
}
private final class TestAccountDataType: AccountDataType {
    internal init(name: String? = nil, displayName: String, address: String, accountIndex: Int, submissionId: String? = nil, transactionStatus: SubmissionStatusEnum? = nil, encryptedAccountData: String? = nil, encryptedPrivateKey: String? = nil, encryptedCommitmentsRandomness: String? = nil, identity: IdentityDataType? = nil, revealedAttributes: [String : String], finalizedBalance: Int, forecastBalance: Int, finalizedEncryptedBalance: Int, forecastEncryptedBalance: Int, totalForecastBalance: Int, encryptedBalance: EncryptedBalanceDataType? = nil, encryptedBalanceStatus: ShieldedAccountEncryptionStatus? = nil, accountNonce: Int, credential: Credential? = nil, createdTime: Date, usedIncomingAmountIndex: Int, isReadOnly: Bool, baker: BakerDataType? = nil, delegation: DelegationDataType? = nil, releaseSchedule: ReleaseScheduleDataType? = nil, transferFilters: TransferFilter? = nil, showsShieldedBalance: Bool, hasShieldedTransactions: Bool) {
        self.name = name
        self.displayName = displayName
        self.address = address
        self.accountIndex = accountIndex
        self.submissionId = submissionId
        self.transactionStatus = transactionStatus
        self.encryptedAccountData = encryptedAccountData
        self.encryptedPrivateKey = encryptedPrivateKey
        self.encryptedCommitmentsRandomness = encryptedCommitmentsRandomness
        self.identity = identity
        self.revealedAttributes = revealedAttributes
        self.finalizedBalance = finalizedBalance
        self.forecastBalance = forecastBalance
        self.finalizedEncryptedBalance = finalizedEncryptedBalance
        self.forecastEncryptedBalance = forecastEncryptedBalance
        self.totalForecastBalance = totalForecastBalance
        self.encryptedBalance = encryptedBalance
        self.encryptedBalanceStatus = encryptedBalanceStatus
        self.accountNonce = accountNonce
        self.credential = credential
        self.createdTime = createdTime
        self.usedIncomingAmountIndex = usedIncomingAmountIndex
        self.isReadOnly = isReadOnly
        self.baker = baker
        self.delegation = delegation
        self.releaseSchedule = releaseSchedule
        self.transferFilters = transferFilters
        self.showsShieldedBalance = showsShieldedBalance
        self.hasShieldedTransactions = hasShieldedTransactions
    }
    
    var name: String?
    
    var displayName: String
    
    var address: String
    
    var accountIndex: Int
    
    var submissionId: String?
    
    var transactionStatus: SubmissionStatusEnum?
    
    var encryptedAccountData: String?
    
    var encryptedPrivateKey: String?
    
    var encryptedCommitmentsRandomness: String?
    
    var identity: IdentityDataType?
    
    var revealedAttributes: [String : String]
    
    var finalizedBalance: Int
    
    var forecastBalance: Int
    
    var finalizedEncryptedBalance: Int
    
    var forecastEncryptedBalance: Int
    
    var totalForecastBalance: Int
    
    var encryptedBalance: EncryptedBalanceDataType?
    
    var encryptedBalanceStatus: ShieldedAccountEncryptionStatus?
    
    var accountNonce: Int
    
    var credential: Credential?
    
    var createdTime: Date
    
    var usedIncomingAmountIndex: Int
    
    var isReadOnly: Bool
    
    var baker: BakerDataType?
    
    var delegation: DelegationDataType?
    
    var releaseSchedule: ReleaseScheduleDataType?
    
    var transferFilters: TransferFilter?
    
    var showsShieldedBalance: Bool
    
    var hasShieldedTransactions: Bool
    
    func write(code: (TestAccountDataType) -> Void) -> Result<Void, Error> {
        .success(())
    }
}
