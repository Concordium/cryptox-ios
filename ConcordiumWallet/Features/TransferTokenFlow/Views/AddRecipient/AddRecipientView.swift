//
//  AddRecipientView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AddRecipientView: View {
    @ObservedObject var viewModel: AddRecipientViewModel
    @State private var isPresentingScanner = false
    @State var error: GeneralAppError?
    var onBackTapped: () -> Void
    @State var showErrorAlert: Bool = false
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isAddressFieldFocused: Bool

    var body: some View {
        VStack(spacing: 15) {
            
            VStack(alignment: .leading, spacing: 5) {
                Text("addRecipient.recipientName".localized)
                    .font(.satoshi(size: 12, weight: .medium))
                    .foregroundStyle(Color.MineralBlue.blueish3)
                    .opacity(0.5)
                    .multilineTextAlignment(.leading)
                TextField("", text: $viewModel.name)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .focused($isNameFieldFocused)
                    .tint(.white)
                    .onChange(of: viewModel.name) { _ in
                        viewModel.calculateSaveButtonState()
                    }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isNameFieldFocused ? Color.MineralBlue.blueish3 : Color.grey3, lineWidth: 1)
                    .background(.clear)
                    .cornerRadius(12)
            )
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("addRecipient.recipientAddress".localized)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish3)
                        .opacity(0.5)
                        .multilineTextAlignment(.leading)
                    TextEditor(text: $viewModel.address)
                        .foregroundColor(.white)
                        .font(.system(size: 16)).background(.clear)
                        .scrollContentBackground(.hidden)
                        .tint(.white)
                        .focused($isAddressFieldFocused)
                        .frame(minHeight: 50, maxHeight: 120)
                        .fixedSize(horizontal: false, vertical: true)
                        .onChange(of: viewModel.address) { _ in
                            viewModel.calculateSaveButtonState()
                        }
                }
                if viewModel.address.isEmpty {
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
                if !viewModel.address.isEmpty {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.MineralBlue.blueish3)
                        .frame(width: 18, height: 18)
                        .onTapGesture {
                            if !viewModel.address.isEmpty {
                                withAnimation {
                                    viewModel.address = ""
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAddressFieldFocused ? Color.MineralBlue.blueish3 : Color.grey3, lineWidth: 1)
                    .background(.clear)
                    .cornerRadius(12)
            )
            Spacer()
            Button(action: {
                viewModel.saveTapped()
                if viewModel.error == nil {
                    onBackTapped()
                }
            }, label: {
                Text("Save".localized)
                    .font(Font.satoshi(size: 15, weight: .medium))
                    .foregroundColor(viewModel.enableSave ? .blackMain : .grey4)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.enableSave ? .white : .blackMain)
                    .cornerRadius(48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 48)
                            .inset(by: 0.5)
                            .stroke(Color(red: 0.44, green: 0.47, blue: 0.49), lineWidth: viewModel.enableSave ? 0 : 1)
                        
                    )
            })
            .disabled(!viewModel.enableSave)
        }
        .padding(.horizontal, 18)
        .padding(.top, 40)
        .padding(.bottom, 20)
        .errorAlert(error: $error, action: { error in
            guard let error = error else { return }
            switch error {
            case .noCameraAccess:
                SettingsHelper.openAppSettings()
            default: break
            }
        })
        .onAppear {
            viewModel.calculateSaveButtonState()
        }
        .onChange(of: viewModel.shouldShowErrorAlert, perform: { _ in
            showErrorAlert = viewModel.shouldShowErrorAlert
        })
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text(viewModel.error?.errorDescription ?? ""), dismissButton: .default(Text("errorAlert.okButton".localized), action: {
                showErrorAlert = false
                viewModel.calculateSaveButtonState()
            }))
        }
        .sheet(isPresented: $isPresentingScanner) {
            ScanAddressQRView(onPicked: { address in
                viewModel.address = address
                viewModel.name = address.prefix(4) + "..." + address.suffix(4)
                isPresentingScanner = false
            })
        }
        .modifier(AppBackgroundModifier())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(NavigationViewModifier(title: viewModel.title, backAction: {
            onBackTapped()
        }))
    }
}
