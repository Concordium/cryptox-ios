//
//  ShieldedAccountsView.swift
//  CryptoX
//
//  Created by Max on 20.05.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt

struct AccountViewData: Identifiable {
    enum Balance {
        case encrypted(BigDecimal)
        case decrypted
        
        var title: String {
            switch self {
            case .encrypted(let gTU):
                return TokenFormatter().plainString(from: gTU) + " CCD"
            case .decrypted:
                return "*** ***"
            }
        }
        
        var isZero: Bool {
            switch self {
            case .encrypted(let gTU):
                return gTU.value.isZero
            case .decrypted:
                return true
            }
        }
    }
    
    let id: String
    let displayname: String
    let address: String
    var balance: Balance
    let isUncrypted: Bool // means that balance is visible
    let isUnshielded: Bool // just visually shows, that in current view session user is unshielded all assets
    
    init(account: AccountDataType, storageManager: any StorageManagerProtocol) {
        self.id = account.address
        self.displayname = account.displayName
        self.address = account.address
        self.balance = .decrypted
        self.isUncrypted = false
        self.isUnshielded = false
        
        if let selfAmount = account.encryptedBalance?.selfAmount,
           let decryptedSelfAmount = storageManager.getShieldedAmount(encryptedValue: selfAmount,
                                                                      account: account)?.decryptedValue {
            self.balance = .encrypted(BigDecimal(BigInt(stringLiteral: decryptedSelfAmount), 6))
        }
    }
}

final class ShieldedAccountsViewModel: ObservableObject {
    @Published var accounts = [AccountViewData]()
    
    let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    
    init(dependencyProvider: AccountsFlowCoordinatorDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.accounts = dependencyProvider.storageManager().getAccounts()
            .filter { $0.encryptedBalanceStatus == ShieldedAccountEncryptionStatus.decrypted }
            .sorted(by: { t1, t2 in
                if (t1.forecastBalance == t2.forecastBalance) {
                    return t1.createdTime > t2.createdTime
                }
                return t1.forecastBalance > t2.forecastBalance
            })
            .map { AccountViewData(account: $0, storageManager: dependencyProvider.storageManager()) }
    }
    
    func decryptBalances(_ seed: String) {
        
    }
    
    func unshield(_ account: AccountViewData) {
        guard let accountDataType = dependencyProvider.storageManager().getAccounts().first(where: { $0.address == account.address }) else { return }
    }
    
    func getUnshieldAccount(_ account: AccountViewData) -> AccountEntity? {
        dependencyProvider.storageManager().getAccounts().first(where: { $0.address == account.address }) as? AccountEntity
    }
    
    private func update() {
        dependencyProvider.storageManager().getAccounts().forEach { account in
            let shieldedAmount = dependencyProvider.storageManager().getShieldedAmountsForAccount(account)
            print("shieldedAmount --- \(shieldedAmount)")
            print("shieldedAmount --- \(account.displayName)")
            print("account.encryptedBalanceStatus != ShieldedAccountEncryptionStatus.decrypted -- \(account.encryptedBalanceStatus == ShieldedAccountEncryptionStatus.decrypted)")
        }
    }
}

struct ShieldedAccountsView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ShieldedAccountsViewModel
    @State var isPasscodeViewShow: Bool = false
    
    @State var unshieldFlowShown: AccountEntity?
    
    var body: some View {
        NavigationView {
            ZStack {
                NavigationLink(
                    destination: UnshieldAssetsView(viewModel: .init(account: unshieldFlowShown, dependencyProvider: viewModel.dependencyProvider)),
                    isActive: Binding<Bool>(
                        get: { unshieldFlowShown != nil },
                        set: { _ in unshieldFlowShown = nil }
                    ),
                    label: { EmptyView() }
                )
                .hidden()
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color(red: 0.14, green: 0.14, blue: 0.15), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.03, green: 0.03, blue: 0.04), location: 1.00),
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
                .ignoresSafeArea(.all)
                
                List(viewModel.accounts) { account in
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(account.displayname)
                                .font(.satoshi(size: 14, weight: .medium))
                                .foregroundStyle(Color.blackAditional)
                            Text(account.balance.title)
                                .font(.satoshi(size: 20, weight: .medium))
                                .foregroundStyle(Color.white)
                        }
                        
                        Spacer()
                        Button {
                            Vibration.vibrate(with: .light)
                            switch account.balance {
                            case .decrypted:
                                isPasscodeViewShow.toggle()
                            case .encrypted:
                                self.unshieldFlowShown = viewModel.getUnshieldAccount(account)
                            }
                        } label: {
                            Text(account.balance.isZero ? "Unshielded" : "Unshield")
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(Color.black)
                                .padding(.vertical, 13)
                                .padding(.horizontal, 28)
                                .contentShape(.rect)
                        }
                        .background(.white)
                        .cornerRadius(48)
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 16)
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image("ico_close")
                            .foregroundColor(Color.Neutral.tint1)
                            .frame(width: 35, height: 35)
                            .contentShape(.circle)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Accounts")
                            .font(.satoshi(size: 17, weight: .medium))
                            .foregroundStyle(Color.white)
                        Text("with shielded assets")
                            .font(.satoshi(size: 11, weight: .medium))
                            .foregroundStyle(Color.blackAditional)
                    }
                }
            }
            .passcodeInput(isPresented: $isPasscodeViewShow) { seed in
                viewModel.decryptBalances(seed)
            }
        }
    }
}
