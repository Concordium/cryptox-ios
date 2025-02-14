//
//  SendTokenView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 22.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import BigInt
import Combine

struct SendTokenView: View {
    
    @Binding var path: [NavigationPaths]
    @StateObject var viewModel: TransferTokenViewModel
    @StateObject var addMemoViewModel = AddMemoViewModel()
    @State var showConfirmationAlertForMemo: Bool = false
    @State private var isContinueDisabled: Bool = true
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .bottom) {
                        DecimalNumberTextField(decimalValue: $viewModel.amountTokenSend, fraction: $viewModel.fraction)
                            .tint(.white)
                        
                        Button {
                            viewModel.sendAll()
                        } label: {
                            Text("Max")
                                .underline(true, pattern: .solid)
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(.greyAdditional)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    HStack {
                        if viewModel.tokenTransferModel.tokenType == .ccd  {
                            Text("~ \(viewModel.euroEquivalentForCCD) EUR")
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        }
                        Spacer()
                        Text("Transaction fee")
                            .font(.satoshi(size: 12, weight: .medium))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        Text(GTU(intValue: Int(viewModel.transaferCost?.cost ?? "0") ?? 0).displayValueWithCCDStroke())
                            .font(.satoshi(size: 12, weight: .medium))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                    }
                    
                    if !viewModel.isInsuficientFundsErrorHidden {
                        Text("sendFund.insufficientFunds".localized)
                            .foregroundColor(Color(hex: 0xFF163D))
                            .font(.satoshi(size: 15, weight: .medium))
                    }
                    
                    switch viewModel.tokenTransferModel.tokenType {
                    case .ccd:
                        SendTokenCell(tokenType: .ccd(displayAmount: viewModel.atDisposalCCDDisplayAmount))
                            .modifier(TappedCellEffect(onTap: {
                                path.append(.chooseTokenToSend(transferTokenVM: viewModel, AccountDetailViewModel(account: viewModel.account)))
                            }))
                    case .cis2(let token):
                        SendTokenCell(tokenType: .cis2(token: token, availableAmount: viewModel.availableDisplayAmount))
                            .modifier(TappedCellEffect(onTap: {
                                path.append(.chooseTokenToSend(transferTokenVM: viewModel, AccountDetailViewModel(account: viewModel.account)))
                            }))
                    }
                    
                    selectRecipient()
                    if !viewModel.tokenTransferModel.tokenType.isCIS2Token {
                        AddMemoView(viewModel: addMemoViewModel) { memo in
                            viewModel.setMemo(memo: memo)
                        }
                    }
                }
                .padding(.vertical, 40)
            }
            Spacer()
            Button(action: {
                if viewModel.addedMemo != nil {
                    showConfirmationAlertForMemo = true
                } else {
                    path.append(.confirmTransaction(viewModel))
                }
                Tracker.trackContentInteraction(name: "Send token", interaction: .clicked, piece: "Continue")
            }, label: {
                Text("errorAlert.continueButton".localized)
                    .font(Font.satoshi(size: 15, weight: .medium))
                    .foregroundColor(isContinueDisabled ? .grey4 : .blackMain)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isContinueDisabled ? 18.5 : 0)
                    .background(.clear)
            })
            .if(!isContinueDisabled) { button in
                button.buttonStyle(PressedButtonStyle())
            }
            .disabled(isContinueDisabled)
            .overlay(
                RoundedRectangle(cornerRadius: 48)
                    .inset(by: 0.5)
                    .stroke(isContinueDisabled ? .grey4 : .clear)
            )
        }
        .alert(isPresented: $showConfirmationAlertForMemo) {
            Alert(
                title: Text("warningAlert.transactionMemo.title".localized),
                message: Text("warningAlert.transactionMemo.text".localized),
                primaryButton: .default(Text("errorAlert.okButton".localized)) {
                    // Completion for OK button
                    showConfirmationAlertForMemo = false
                    path.append(.confirmTransaction(viewModel))
                },
                secondaryButton: .default(Text("warningAlert.dontShowAgainButton".localized)) {
                    // Dont show again logic
                    AppSettings.dontShowMemoAlertWarning = true
                    showConfirmationAlertForMemo = false
                    path.append(.confirmTransaction(viewModel))
                }
            )
        }
        .onAppear {
            setupBinding()
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(AppBackgroundModifier())
    }
    
    func selectRecipient() -> some View {
        HStack(alignment: .center, spacing: 17) {
            Text(viewModel.recepientAddress.isEmpty ? "Select a recipient" : viewModel.recepientAddress)
                .font(.satoshi(size: 14, weight: .medium))
                .foregroundStyle(viewModel.recepientAddress.isEmpty ? Color.MineralBlue.blueish3.opacity(0.5) : .white)
            Spacer()
            Image("caretRight")
                .renderingMode(.template)
                .foregroundStyle(.grey4)
                .frame(width: 30, height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .modifier(TappedCellEffect(onTap: {
            if let account = viewModel.account as? AccountEntity {
                path.append(.selectRecipient(account, mode: .selectRecipientFromPublic))
            }
        }))
    }
    
    private func setupBinding() {
        Publishers.CombineLatest(
            viewModel.$canSend,
            addMemoViewModel.$enableAddMemoToTransferButton
        )
        .map { [weak viewModel] canSend, enableMemoButton in
            guard let viewModel = viewModel else { return true }
            return !canSend || (viewModel.addedMemo != nil && !enableMemoButton)
        }
        .receive(on: RunLoop.main)
        .sink { newValue in
            self.isContinueDisabled = newValue
        }
        .store(in: &cancellables)
    }
}
