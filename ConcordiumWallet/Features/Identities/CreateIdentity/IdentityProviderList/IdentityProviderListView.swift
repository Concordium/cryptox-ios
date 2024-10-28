//
//  IdentityProviderListView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 28.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

enum IdentityProviderListError: Identifiable {
    case error(Error)
    case cameraAccessDenied
    
    var id: String {
        switch self {
        case .error(let error):
            return "error-\(error.localizedDescription)"
        case .cameraAccessDenied:
            return "cameraAccessDenied"
        }
    }
}

struct IdentityProviderListView: View {
    @ObservedObject var viewModel: SelectIdentityProviderViewModel
    
    var body: some View {
        ZStack {
            Image("new_bg")
                .resizable()
                .ignoresSafeArea()
            VStack(alignment: .center) {
                VStack(spacing: 8) {
                    Text("identityVerification.title".localized)
                        .font(.satoshi(size: 24, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.Neutral.tint1)
                    Text("identity.selectProvider.subtitle".localized)
                }
                
                VStack(alignment: .leading) {
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        Text("Personal Identity")
                            .font(.satoshi(size: 12, weight: .regular))
                            .foregroundStyle(.greySecondary)
                        ForEach(
                            viewModel.identityProviders,
                            id: \.ipInfo.ipIdentity
                        ) { provider in
                            providerCell(provider)
                                .onTapGesture {
                                    viewModel.selectIdentityProvider(provider)
                                }
                            if provider.displayName != viewModel.identityProviders.last?.displayName {
                                Divider().background(Color.greyAdditional)
                            }
                        }
                    }
                }
                .padding(.top, 122)
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.trailing, 15)
        }
        .alert(item: $viewModel.error) { error in
            switch error {
            case .cameraAccessDenied:
                Alert(
                    title: Text("Camera Access Denied"),
                    message: Text("Please grant camera access in Settings."),
                    primaryButton: .default(Text("Continue")) {
                        SettingsHelper.openAppSettings()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            case .error(let error):
                Alert(
                    title: Text("Error"),
                    message: Text(ErrorMapper
                        .toViewError(error: error).localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    @ViewBuilder
    private func providerCell(_ provider: IPInfoResponseElement) -> some View {
        HStack {
            (Image.init(base64String: provider.metadata.icon) ?? Image("ccd_logo_dark"))
                .resizable()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            
            Text(provider.displayName)
                .foregroundColor(.text)
                .font(.satoshi(size: 15, weight: .medium))
            
            Spacer()
            
            Image("ico_side_arrow")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 7)
    }
}
