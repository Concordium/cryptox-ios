//
//  MainPromoView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 21.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct MainPromoView: View {
    let keychain: KeychainWrapperProtocol
    let identitiesService: SeedIdentitiesService
    let defaultProvider: ServicesProvider
    
    @State var isCreateAccountSheetShown = false
    @State var isCreateWalletFlowShown = false
    @State var isImportWalletFlowShown = false
    @State var isCreateSeedPhraseFlowShown = false
    
    @State var isCreateIdentityFlowShown = false
    
    @EnvironmentObject var sanityChecker: SanityChecker
    
    private var onIdentityCreated: () -> Void
    private var onAccountInported: () -> Void
    private var onLogout: () -> Void
    
    init(defaultProvider: ServicesProvider, onIdentityCreated: @escaping () -> Void, onAccountInported: @escaping () -> Void, onLogout: @escaping () -> Void) {
        self.defaultProvider = defaultProvider
        self.keychain = defaultProvider.keychainWrapper()
        self.identitiesService = defaultProvider.seedIdentitiesService()
        self.onIdentityCreated = onIdentityCreated
        self.onAccountInported = onAccountInported
        self.onLogout = onLogout
        UITabBar.appearance().unselectedItemTintColor = UIColor.Neutral.tint4
    }
    
    var body: some View {
        WelcomeView(isCreateAccountSheetShown: $isCreateAccountSheetShown)
        .overlay(alignment: .bottom, content: {
            BottomSheet(isShowing: $isCreateAccountSheetShown) {
                ActivateAccountSheet()
                    .onAppear { Tracker.track(view: ["Activate account dialog"]) }
            }
        })
        .fullScreenCover(isPresented: $isCreateIdentityFlowShown) {
            CreateIdentityRootView(keychain: keychain, identitiesService: identitiesService, onIdentityCreated: onIdentityCreated)
            .environmentObject(sanityChecker)
            .transition(.fade)
        }
        .fullScreenCover(isPresented: $isImportWalletFlowShown) {
            ImportWalletView(defaultProvider: defaultProvider, onAccountInported: onAccountInported)
        }
    }
    
    @ViewBuilder
    func ActivateAccountSheet() -> some View {
        VStack(spacing: 16) {
            Text("setup_wallet_title".localized)
                .font(Font.satoshi(size: 24, weight: .medium))
                .foregroundColor(Color.Neutral.tint7)
            
            sheetView(content: accountViewSheet(), title: "create_wallet_sheet".localized)
            Image("create_wallet_divider")
            Text("create_wallet_sheet_import_wallet".localized)
                .font(.satoshi(size: 14, weight: .regular))
                .foregroundStyle(Color.Neutral.tint5)
                .multilineTextAlignment(.center)
            Button {
                isImportWalletFlowShown.toggle()
                Tracker.trackContentInteraction(name: "Activate account dialog", interaction: .clicked, piece: "Import Wallet")
            } label: {
                VStack(spacing: 2) {
                    Text("import_wallet".localized)
                        .font(.satoshi(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(Color.Neutral.tint7),
                            alignment: .bottom
                        )
                        .padding(.bottom, 3)
                }
                
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func sheetView(content: some View, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4){
                Text(title)
                    .font(Font.plexMono(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.17, green: 0.38, blue: 0.41))
                Image("Burst-pucker-2")
            }
            
            content
        }
        .padding(16)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.92, green: 0.98, blue: 0.91), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.77, green: 0.84, blue: 0.89), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.75, y: 0.72)
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.06, green: 0.08, blue: 0.08).opacity(0.05), lineWidth: 1)
            
        )
    }
        
    @ViewBuilder
    func accountViewSheet() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("create_wallet_steps_title".localized)
                .font(Font.satoshi(size: 14, weight: .medium))
                .foregroundColor(Color.Neutral.tint5)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("1")
                        .font(Font.plexSans(size: 12, weight: .regular))
                        .foregroundColor(Color.MineralBlue.tint2)
                    Text("create_wallet_step_1_title".localized)
                        .font(Font.satoshi(size: 14, weight: .medium))
                        .foregroundColor(Color.Neutral.tint5)
                    Spacer()
                }
                HStack(spacing: 6) {
                    Text("2")
                        .font(Font.plexSans(size: 12, weight: .regular))
                        .foregroundColor(Color.MineralBlue.tint2)
                    Text("create_wallet_step_2_title".localized)
                        .font(Font.satoshi(size: 14, weight: .medium))
                        .foregroundColor(Color.Neutral.tint5)
                    Spacer()
                }
                HStack(spacing: 6) {
                    Text("3")
                        .font(Font.plexSans(size: 12, weight: .regular))
                        .foregroundColor(Color.MineralBlue.tint2)
                    Text("create_wallet_step_3_title".localized)
                        .font(Font.satoshi(size: 14, weight: .medium))
                        .foregroundColor(Color.Neutral.tint5)
                    Spacer()
                }
            }
            Button(action: {
                isCreateIdentityFlowShown.toggle()
                Tracker.trackContentInteraction(name: "Activate account dialog", interaction: .clicked, piece: "Create Wallet")
            }, label: {
                HStack {
                    Text("continue_btn_title".localized)
                        .font(Font.satoshi(size: 16, weight: .medium))
                        .foregroundColor(Color.Neutral.tint1)
                    Spacer()
                    Image(systemName: "arrow.right").tint(Color.Neutral.tint1)
                }
                .padding(.horizontal, 24)
            })
            .frame(height: 56)
            .background(Color.Neutral.tint7)
            .cornerRadius(28, corners: .allCorners)
            .padding(.top, 16)
        }
    }
}
