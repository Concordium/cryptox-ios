//
//  SelectRecipientView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 23.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct SelectRecipientView: View {
    @State var accountAddressText: String = ""
    @ObservedObject var viewModel: RecipientListViewModel
    var onRecipientSelected: ((String) -> Void)
    @State private var isPresentingScanner = false
    @State var error: GeneralAppError?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Recipient Address")
                            .font(.satoshi(size: 12, weight: .medium))
                            .foregroundStyle(Color.MineralBlue.blueish3)
                            .opacity(0.5)
                            .multilineTextAlignment(.leading)
                        TextField("", text: $accountAddressText)
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .onChange(of: accountAddressText) { value in
                                viewModel.filterRecipients(searchText: accountAddressText)
                            }
                    }
                    if accountAddressText.isEmpty {
                        Image("scan")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(Color.MineralBlue.blueish3)
                            .frame(width: 24, height: 24)
                            .onTapGesture {
                                PermissionHelper.requestAccess(for: .camera) { permissionGranted in
                                    
                                    guard permissionGranted else {
                                        self.error = GeneralAppError.noCameraAccess
                                        return
                                    }
                                    isPresentingScanner = true
                                }
                            }
                    }
                    Image(systemName: !accountAddressText.isEmpty ? "xmark" : "magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.MineralBlue.blueish3)
                        .frame(width: 18, height: 18)
                        .onTapGesture {
                            if !accountAddressText.isEmpty {
                                withAnimation {
                                    accountAddressText = ""
                                }
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.grey3, lineWidth: 1)
                        .background(.clear)
                        .cornerRadius(12)
                )
                
                Text("Recents")
                    .font(.satoshi(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 20)
                
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.filteredRecipientsViewModels, id: \.address) { recipient in
                        HStack(alignment: .center, spacing: 7) {
                            Text(recipient.address)
                                .font(.satoshi(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(recipient.name)
                                .font(.satoshi(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                            Image("caretRight")
                                .renderingMode(.template)
                                .foregroundStyle(.grey4)
                                .frame(width: 30, height: 40)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background(Color(red: 0.09, green: 0.1, blue: 0.1))
                        .cornerRadius(12)
                        .onTapGesture {
                            onRecipientSelected(recipient.address)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.refreshData()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 40)
            .sheet(isPresented: $isPresentingScanner) {
                ScanAddressQRView(onPicked: { address in
                    onRecipientSelected(address)
                    isPresentingScanner = false
                }
                )
            }
        }
        .errorAlert(error: $error, action: { error in
            guard let error = error else { return }
            switch error {
            case .noCameraAccess:
                SettingsHelper.openAppSettings()
            default: break
            }
        })
        .modifier(AppBackgroundModifier())
    }
}

#Preview {
    SelectRecipientView(viewModel: RecipientListViewModel(storageManager: ServicesProvider.defaultProvider().storageManager(), mode: .addressBook), onRecipientSelected: { _ in })
}
