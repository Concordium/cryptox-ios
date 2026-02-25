import SwiftUI
import Combine
import ReownWalletKit

@MainActor
final class AccountsFlowViewModel: ObservableObject {

    let router: AppRouter
    private let services: ServicesProvider
    private let walletConnectService: WalletConnectService
    let accountsViewModel: AccountsMainViewModel
    
    init(
        router: AppRouter,
        services: ServicesProvider,
        walletConnectService: WalletConnectService
    ) {
        self.router = router
        self.services = services
        self.walletConnectService = walletConnectService
        self.accountsViewModel = .init(dependencyProvider: ServicesProvider.defaultProvider(), onReload: .empty(), walletConnectService: walletConnectService)
    }

    // MARK: Navigation

    func createAccount() {
        router.selectedTab = .accounts
//        router.accountsPath.append(.createAccount)
    }

    func createIdentity() {
        router.selectedTab = .accounts
//        router.accountsPath.append(.createIdentity)
    }

    func openAccount(
        _ account: AccountDataType,
        entryPoint: AccountDetailsFlowEntryPoint
    ) {
        router.selectedTab = .accounts
//        router.accountsPath.append(.accountDetails(account, entryPoint))
    }

    func showExport() {
//        router.accountsPath.append(.export)
    }

    func scanQR() {
        router.accountsPath.append(.scanQR)
    }

    func closeCurrentRoute() {
        if !router.accountsPath.isEmpty {
            router.accountsPath.removeLast()
        }
    }

    // MARK: WalletConnect

    func handleWalletConnect(_ uri: String) {
        Task {
            let result = await walletConnectService.pair(uri)

            switch result {
            case .success:
                closeCurrentRoute()

            case .failure(let error):
                router.globalError = mapWalletError(error)
            }
        }
    }

    private func mapWalletError(_ error: Error) -> String {
        let text = error.localizedDescription.lowercased()

        if text.contains("expired") {
            return "WalletConnect pairing URI expired."
        } else if text.contains("invalid") {
            return "Invalid WalletConnect URI."
        } else {
            return "Failed to connect."
        }
    }

    // MARK: Session Presentation

    func showSessionRequest(
        request: WalletConnectSign.Request,
        redirectURL: String?
    ) {
        router.presentedSheet = .sessionRequest(request, redirectURL)
    }

    func showSessionProposal(
        proposal: Session.Proposal,
        redirectURL: String?
    ) {
        router.presentedSheet = .sessionProposal(proposal, redirectURL)
    }
}

//////////////////////////////////////////////////////////////

// MARK: - Accounts Flow View

struct AccountsFlowView: View {

    @EnvironmentObject var router: AppRouter
    @ObservedObject var flow: AccountsFlowViewModel

    var body: some View {
        NavigationStack(path: $router.accountsPath) {

            HomeScreenView(
                viewModel: flow.accountsViewModel,
                keychain: KeychainWrapper(),
                identitiesService: ServicesProvider.defaultProvider().seedIdentitiesService(),
                router: AccountsHomeRouterAdapter(flow: flow)
            )
            .environmentObject(NavigationManager())
            .environmentObject(UpdateTimer())

                .navigationDestination(for: AppRouter.AccountsRoute.self) { route in

                    switch route {

                    case .scanQR:
                        ScanQRView(flow: flow)

//                    case .createAccount:
//                        CreateAccountView(flow: flow)
//
//                    case .createIdentity:
//                        CreateIdentityView(flow: flow)
//
//                    case .accountDetails(let account, let entryPoint):
////                        AccountDetailsView(
//                            account: account,
//                            entryPoint: entryPoint,
//                            flow: flow
//                        )
//
//                    case .export:
////                        ExportView(flow: flow)
                    }
                }
        }
    }
}


@MainActor
final class AccountsHomeRouterAdapter: AccountsMainViewDelegate {
    func showBackupSeedPhraseFlow(pwHash: String, identitiesService: SeedIdentitiesService, completion: @escaping ([String]) -> Void) {
        flow.createIdentity()
    }
    
    func showCreateAccountFlow() {
        
    }
    
    func showSettings(_ account: any AccountDataType) {
        
    }
    

    private let flow: AccountsFlowViewModel

    init(flow: AccountsFlowViewModel) {
        self.flow = flow
    }

    func showScanQRFlow() {
        flow.scanQR()
    }

    func showCreateIdentityFlow() {
        flow.createIdentity()
    }

    func showExportFlow() {
        flow.showExport()
    }

    func createAccountFromOnboarding(isCreatingAccount: Binding<Bool>) {
        flow.createAccount()
    }

    func showBackupSeedPhraseFlow(
        pwHash: Data,
        identitiesService: SeedIdentitiesService,
        completion: @escaping ([String]?) -> Void
    ) {
        // You can either:
        // 1️⃣ add new route in AppRouter
        // 2️⃣ present sheet
        // 3️⃣ push navigation destination

        // Example:
        flow.createIdentity()
    }

    func showNotConfiguredAccountPopup() {
        flow.router.globalError = "Account not configured."
    }
}
