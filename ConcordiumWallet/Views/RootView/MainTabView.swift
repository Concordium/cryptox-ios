import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var router: AppRouter
    let dependencyProvider: ServicesProvider

    var body: some View {

        VStack(spacing: 0) {
            ZStack {

                switch router.selectedTab {

                case .accounts:
                    AccountsFlowView(
                        flow: .init(
                            router: router,
                            services: dependencyProvider,
                            walletConnectService: WalletConnectService()
                        )
                    )

                case .transfer:
                    Text("Transfer")

                case .buy:
                    CCDOnrampView(dependencyProvider: dependencyProvider)

                case .stake:
                    StakeMainView(account: AccountEntity())

                case .activity:
                    TransactionsView(
                        viewModel: TransactionsViewModel(
                            account: AccountEntity(),
                            dependencyProvider: dependencyProvider
                        ),
                        onTxTap: { _ in }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar()
        }
        .sheet(item: $router.presentedSheet) { sheet in
            switch sheet {

            case .sessionRequest(let request, let redirectURL):
                SessionRequestView(
                    viewModel: .init(
                        sessionRequest: request,
                        transactionsService: dependencyProvider.transactionsService(),
                        storageManager: dependencyProvider.storageManager(),
                        mobileWallet: dependencyProvider.mobileWallet(),
                        concordiumClient: try! ConcordiumClient(
                            networkManager: dependencyProvider.networkManager(),
                            storageManager: dependencyProvider.storageManager()
                        ),
                        identitiesService: dependencyProvider.seedIdentitiesService(),
                        redirectURL: redirectURL
                    ),
                    onSuccess: { type, redirectURL in
                        VerificationSuccessfulView(
                            siteName: redirectURL ?? "",
                            type: type
                        )
                    }
                )

            case .sessionProposal(let proposal, let redirectURL):
                SessionProposalView(
                    viewModel: .init(
                        sessionProposal: proposal,
                        wallet: dependencyProvider.mobileWallet(),
                        storageManager: dependencyProvider.storageManager(),
                        redirectURL: redirectURL
                    )
                )
            }
        }

        // MARK: Alerts

        .alert(item: Binding(
            get: {
                router.globalError.map { IdentifiableError(message: $0) }
            },
            set: { _ in router.globalError = nil }
        )) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

