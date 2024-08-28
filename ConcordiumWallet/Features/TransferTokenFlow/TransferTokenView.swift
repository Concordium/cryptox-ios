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

enum GeneralAppError: LocalizedError {
    case noCameraAccess
    case somethingWentWrong
    
    var errorDescription: String? {
        switch self {
            case .noCameraAccess:
                return "errorAlert.title".localized
            case .somethingWentWrong:
                return "something_went_wrong".localized
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
            case .noCameraAccess:
                return "view.error.cameraAccessDenied".localized
            case .somethingWentWrong: return "Oops"
        }
    }
    
    var actionButtontitle: String? {
        switch self {
            case .noCameraAccess:
                return "errorAlert.open.settings".localized
            case .somethingWentWrong:
                return "Ok"
        }
    }
}

enum CXTokenType {
    case cis2(CIS2Token), ccd
    
    var isCIS2Token: Bool {
        switch self {
            case .ccd: return false
            default: return true
        }
    }
    
    var name: String {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.name ?? ""
            case .ccd:
                return "ccd"
        }
    }
    
    var fraction: Int {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.decimals ?? 0
            case .ccd:
                return 6
        }
    }
}

final class TransferTokenViewModel: ObservableObject {
    @Published var amount: Decimal = .zero
    
    @Published var availableDisplayAmount: String = ""
    @Published var atDisposalCCDDisplayAmount: String = ""
    @Published var amountTokenSend: BigDecimal = .zero
    
    @Published var recepientAddress: String = ""
    
    @Published var thumbnail: URL? = nil
    @Published var canSend: Bool = false
    @Published var ticker: String = ""
    
    @Published var error: GeneralAppError?
    @Published var isInsuficientFundsErrorHidden: Bool = true
    
    @Published var transaferCost: TransferCost?
    @Published var fraction: Int = 6
    
    var tokenTransferModel: CIS2TokenTransferModel
    
    lazy var accountTokensListPickerViewModel: AccountTokensListPickerViewModel = {
        AccountTokensListPickerViewModel(account: account, storageManager: dependencyProvider.storageManager(), networkManager: dependencyProvider.networkManager(), selectedToken: tokenTransferModel.tokenType)
    }()
    
    private var cancellables = [AnyCancellable]()
    let account: AccountDataType
    private let dependencyProvider: AccountsFlowCoordinatorDependencyProvider
    private let proxy: TransferTokenRouter
    
    init(
        tokenType: CXTokenType,
        account: AccountDataType,
        proxy: TransferTokenRouter,
        dependencyProvider: AccountsFlowCoordinatorDependencyProvider,
        tokenTransferModel: CIS2TokenTransferModel,
        onRecipientPicked: AnyPublisher<String, Never>
    ) {
        self.tokenTransferModel = tokenTransferModel
        self.proxy = proxy
        self.dependencyProvider = dependencyProvider
        self.account = account
        
        $recepientAddress.assign(to: \.recipient, on: tokenTransferModel).store(in: &cancellables)
        $amountTokenSend.assign(to: \.amountTokenSend, on: tokenTransferModel).store(in: &cancellables)
        tokenTransferModel.$transaferCost.assign(to: \.transaferCost, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.map(\.fraction).assign(to: \.fraction, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.map(\.ticker).assign(to: \.ticker, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.map(\.tokenThumbnail).assign(to: \.thumbnail, on: self).store(in: &cancellables)
        tokenTransferModel.$tokenType.assign(to: \.selectedToken, on: accountTokensListPickerViewModel).store(in: &cancellables)
        
        onRecipientPicked.assign(to: \.recepientAddress, on: self).store(in: &cancellables)
        
        tokenTransferModel.$tokenType.sink { type in
            self.amount = .zero
        }.store(in: &cancellables)
        
        Publishers.CombineLatest3($amountTokenSend, tokenTransferModel.$tokenGeneralBalance, $transaferCost)
            .map { (amount, maxAmount, cost) -> Bool in
                guard let cost = cost else { return true }
                return amount.value <= maxAmount.value && BigInt(stringLiteral: cost.cost) <= BigInt(account.forecastBalance)
            }
            .assign(to: \.isInsuficientFundsErrorHidden, on: self)
            .store(in: &cancellables)
        
        Publishers.CombineLatest4($amountTokenSend, tokenTransferModel.$tokenGeneralBalance, $transaferCost, $recepientAddress)
            .map { (s, a, txCost, recepient) -> Bool in
                guard let txCost = txCost else { return false }
                guard recepient != account.address else  { return false }
                guard !recepient.isEmpty && self.dependencyProvider.mobileWallet().check(accountAddress: recepient) else  { return false }
                
                if BigInt(stringLiteral: txCost.cost) >= BigInt(account.forecastBalance) { return false }
                
                return (s.value <= a.value) && s.value > .zero
            }
            .assign(to: \.canSend, on: self)
            .store(in: &cancellables)
        
        
        tokenTransferModel.$tokenGeneralBalance
            .map { TokenFormatter().string(from: $0) }
            .assign(to: \.availableDisplayAmount, on: self)
            .store(in: &cancellables)
        
        tokenTransferModel.$ccdTokenDisposalBalance
            .map { TokenFormatter().string(from: $0) }
            .assign(to: \.atDisposalCCDDisplayAmount, on: self)
            .store(in: &cancellables)
        
        self.$amount.map {
            TokenFormatter().number(from: $0.toString(), precision: tokenTransferModel.tokenType.decimals) ?? .zero
        }
        .assign(to: \.amountTokenSend, on: self)
        .store(in: &cancellables)
        
        $recepientAddress.sink { address in
            if self.dependencyProvider.mobileWallet().check(accountAddress: address) == false {
                
            }
        }.store(in: &cancellables)
    }
    
    public func showQrScanner() {
        PermissionHelper.requestAccess(for: .camera) { [weak self] permissionGranted in
            guard let self = self else { return }
            
            guard permissionGranted else {
                self.error = GeneralAppError.noCameraAccess
                return
            }
            self.proxy.showQrAddressPicker { address in
                self.recepientAddress = address
            }
        }
    }
    
    public func showRecepientPicker() {
        self.proxy.showRecepientPicker { address in
            self.recepientAddress = address
        }
    }
    
    public func sendAll() {
        Task {
            await tokenTransferModel.updateMaxAmount()
            DispatchQueue.main.async {
                self.amountTokenSend = self.tokenTransferModel.maxAmountTokenSend
            }
        }
    }
}

extension CXTokenType {
    var tokenThumbnail: URL? {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.thumbnail?.url.toURL
            case .ccd:
                return AssetExtractor.createLocalUrl(forImageNamed: "icon_ccd")
        }
    }
    
    var ticker: String {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.name  ?? ""
            case .ccd:
                return "CCD"
        }
    }
    var decimals: Int {
        switch self {
            case .cis2(let cIS2Token):
                return cIS2Token.metadata.decimals ?? 0
            case .ccd:
                return 6
        }
    }
}

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
            Button {
                self.router.showTransferConfirmFlow(tokenTransferModel: viewModel.tokenTransferModel)
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


extension View {
    func errorAlert(error: Binding<GeneralAppError?>, cancelTitle: String = "errorAlert.cancelButton".localized, action: ((GeneralAppError?) -> Void)?) -> some View {
        return alert(isPresented: .constant(error.wrappedValue != nil), error: error.wrappedValue) { _ in
            switch error.wrappedValue {
                case .noCameraAccess:
                    Button(error.wrappedValue?.actionButtontitle ?? "") {
                        action?(error.wrappedValue)
                    }
                case .none: EmptyView()
                default: EmptyView()
            }
            Button(cancelTitle, role: .cancel) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}

extension Publisher where Self.Failure == Never {
    func sink(receiveValue: @escaping ((Self.Output) async -> Void)) -> AnyCancellable {
        sink { value in
            Task {
                await receiveValue(value)
            }
        }
    }
}
