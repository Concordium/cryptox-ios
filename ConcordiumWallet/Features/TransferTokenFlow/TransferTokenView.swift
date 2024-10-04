//
//  SendTokenView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 07.06.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import BigInt

struct TransferTokenView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel: TransferTokenViewModel
    @EnvironmentObject var router: TransferTokenRouter
    
    @State var isPickerPresented = false
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimum = .init(integerLiteral: 1)
        formatter.maximum = .init(integerLiteral: Int.max)
        formatter.generatesDecimalNumbers = false
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack {
            List {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading ,spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("send_token_view_available_title".localized)
                                .foregroundColor(Color.greySecondary)
                                .font(.system(size: 15, weight: .medium))
                                .multilineTextAlignment(.leading)
                            HStack(spacing: 8) {
                                Text(viewModel.availableDisplayAmount)
                                    .foregroundColor(.white)
                                    .font(.system(size: 19, weight: .medium))
                                CryptoImage(url: viewModel.thumbnail, size: .small)
                                .aspectRatio(contentMode: .fit)
                                Spacer()
                            }
                        }
                        
                        switch viewModel.tokenTransferModel.tokenType {
                            case .ccd:
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("accounts.overview.atdisposal".localized)
                                        .foregroundColor(Color.greySecondary)
                                        .font(.system(size: 15, weight: .medium))
                                        .multilineTextAlignment(.leading)
                                    HStack(spacing: 8) {
                                        Text(viewModel.atDisposalCCDDisplayAmount)
                                            .foregroundColor(.white)
                                            .font(.system(size: 19, weight: .medium))
                                        CryptoImage(url: viewModel.thumbnail, size: .small)
                                        .aspectRatio(contentMode: .fit)
                                        Spacer()
                                    }
                                    
                                }
                            default: EmptyView()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blackSecondary)
                .cornerRadius(24, corners: .allCorners)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                
                ZStack {
                    Image("blur").resizable()
                    
                    VStack(alignment: .leading) {
                        Text("releaseschedule.amount")
                            .foregroundColor(.blackSecondary)
                            .font(.system(size: 15, weight: .medium))
                        HStack {
                            DecimalNumberTextField(decimalValue: $viewModel.amountTokenSend, fraction: $viewModel.fraction)
                            Spacer()
                            Text("send_all".localized)
                                .underline()
                                .foregroundColor(.blackSecondary)
                                .font(.system(size: 15, weight: .medium))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.sendAll()
                                }
                        }
                        Divider()
                            .padding(.vertical, 8)
                        HStack {
                            Text("send_token_view_token".localized)
                                .foregroundColor(.blackSecondary)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(viewModel.ticker)
                                .foregroundColor(.blackSecondary)
                                .font(.system(size: 15, weight: .medium))
                            Image("icon_disclosure").resizable().frame(width: 24, height: 24)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { isPickerPresented = true }
                    }
                    .padding()
                }
                .frame(height: 145)
                .cornerRadius(24, corners: .allCorners)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                HStack {
                    if viewModel.isInsuficientFundsErrorHidden {
                        Text("sendFund.feeMessageTitle".localized)
                            .foregroundColor(.blackAditional)
                            .font(.system(size: 15, weight: .medium))
                        Text(GTU(intValue: Int(viewModel.transaferCost?.cost ?? "0") ?? 0).displayValueWithCCDStroke())
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .medium))
                    } else {
                        Text("sendFund.insufficientFunds".localized)
                            .foregroundColor(Color(hex: 0xFF163D))
                            .font(.system(size: 15, weight: .medium))
                    }
                    
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.top, 4)
                
                VStack {
                    TextField("sendFund.pasteRecipient".localized, text: $viewModel.recepientAddress)
                        .foregroundColor(Color.init(hex: 0x878787))
                        .font(.system(size: 19, weight: .regular))
                    Divider()
                    Text("or".localized)
                        .foregroundColor(Color.init(hex: 0x878787))
                        .font(.system(size: 15, weight: .medium))
                    HStack {
                        HStack {
                            Spacer()
                            Image("ico_search")
                                .resizable()
                                .renderingMode(.template)
                                .tint(Color.white)
                                .frame(width: 14, height: 14)
                            Text("sendFund.addressBook".localized)
                                .foregroundColor(Color.white)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                        }
                        .padding(.vertical ,12)
                        .padding(.horizontal ,16)
                        .overlay(
                            RoundedCorner(radius: 24, corners: .allCorners)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.viewModel.showRecepientPicker()
                        }
                        
                        HStack {
                            Spacer()
                            Image("ico_scan")
                                .resizable()
                                .renderingMode(.template)
                                .tint(Color.white)
                                .frame(width: 14, height: 14)
                            Text("scanQr.title".localized)
                                .foregroundColor(Color.white)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                        }
                        .padding(.vertical ,12)
                        .padding(.horizontal ,16)
                        .overlay(
                            RoundedCorner(radius: 24, corners: .allCorners)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.showQrScanner()
                        }
                    }
                }
                .padding(.vertical, 26)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .overlay(
                    RoundedCorner(radius: 24, corners: .allCorners)
                        .stroke(Color.blackSecondary, lineWidth: 1)
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            
            Spacer()
            
            
            Button(action: {
                self.router.showAddMemo(memo: viewModel.addedMemo)
            }) {
                if let memo = viewModel.addedMemo {
                    HStack {
                        Text(memo.displayValue)
                            .padding()
                            .tint(.white)
                        Button(action: {
                            viewModel.removeMemo()
                        }) {
                            Image(systemName: "xmark")
                                .tint(.red)
                        }
                    }
                } else {
                    Text("sendFund.addMemo".localized)
                        .padding()
                        .tint(.white)
                }
            }
            
            Button {
                if viewModel.addedMemo == nil || AppSettings.dontShowMemoAlertWarning {
                    self.router.showTransferConfirmFlow(tokenTransferModel: viewModel.tokenTransferModel)
                } else {
                    self.router.showMemoWarningAlert({
                        self.router.showTransferConfirmFlow(tokenTransferModel: viewModel.tokenTransferModel)
                    })
                }
            } label: {
                Text("sendFund.confirmation.buttonTitle".localized)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.vertical, 11)
                    .background(viewModel.canSend == false ? .white.opacity(0.7) : .white)
                    .clipShape(Capsule())
            }
            .disabled(!viewModel.canSend)
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color(hex: 0x242427), Color(hex: 0x09090B)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
        )
        .errorAlert(error: $viewModel.error, action: { error in
            guard let error = error else { return }
            switch error {
                case .noCameraAccess:
                    SettingsHelper.openAppSettings()
                default: break
            }
        })
        .navigationTitle("sendFund.pageTitle.send")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.router.dismissFlow()
                } label: {
                    Image("ico_close")
                }
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            AccountTokensListPicker(viewModel: viewModel.accountTokensListPickerViewModel) { account in
                switch account {
                    case .ccd:
                        viewModel.tokenTransferModel.tokenType = .ccd
                    case .token(let token, _):
                        viewModel.tokenTransferModel.tokenType = .cis2(token)
                }
                isPickerPresented = false
            }
        }
    }
}
