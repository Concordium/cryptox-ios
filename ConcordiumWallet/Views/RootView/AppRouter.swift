import SwiftUI
import Foundation
import ReownWalletKit

@MainActor
final class AppRouter: ObservableObject {

    enum Tab: Hashable {
        case accounts
        case transfer
        case buy
        case stake
        case activity
    }

    enum AccountsRoute: Hashable {
        case scanQR
//        case createAccount
//        case createIdentity
//        case accountDetails(AccountDataType, AccountDetailsFlowEntryPoint)
//        case export
    }

    enum PresentedSheet: Identifiable {
        case sessionRequest(WalletConnectSign.Request, String?)
        case sessionProposal(Session.Proposal, String?)

        var id: String {
            switch self {
            case .sessionRequest: return "sessionRequest"
            case .sessionProposal: return "sessionProposal"
            }
        }
    }

    @Published var selectedTab: Tab = .accounts
    @Published var accountsPath: [AccountsRoute] = []
    @Published var presentedSheet: PresentedSheet?
    @Published var globalError: String?
}
