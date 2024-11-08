//
//  PasscodeView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 22.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine
import LocalAuthentication
import MatomoTracker

class PasscodeViewModel: ObservableObject {
    enum State: Equatable {
        case createPasscode, repeatPasscode([Int]), enterPasscode, biometry
        
        var title: String {
            switch self {
                case .createPasscode: return "passcode.view.create.passcode.title".localized
                case .repeatPasscode(_): return "passcode.view.repeate.passcode.title".localized
                case .enterPasscode: return "passcode.view.enter.passcode.title".localized
                case .biometry: return "passcode.view.biometry.passcode.title".localized
            }
        }
        
        var subtitle: String {
            switch self {
                case .createPasscode: return "passcode.view.create.passcode.subtitle".localized
                case .repeatPasscode(_): return "passcode.view.repeate.passcode.subtitle".localized
                case .enterPasscode: return "passcode.view.enter.passcode.subtitle".localized
                case .biometry: return "passcode.view.biometry.passcode.subtitle".localized
            }
        }
    }
    
    var state: PasscodeViewModel.State
    var pinLength: Int { 6/*passcodeManager.pinLength*/ }
    
    @Published var pin: [Int] = []
    @Published var isRequestFaceIDViewShown = false
    @Published var error: GeneralAppError?
    @Published var isWrongPassword: Bool = false
    
    private let keychain: KeychainWrapperProtocol
    private let onSuccess: (String) -> Void
    private let sanityChecker: SanityChecker
    private var cancellables = Set<AnyCancellable>()
    private var pwHash: String?

    init(keychain: KeychainWrapperProtocol, sanityChecker: SanityChecker, onSuccess: @escaping (String) -> Void) {
        self.keychain = keychain
        self.onSuccess = onSuccess
        self.sanityChecker = sanityChecker
        state = self.keychain.passwordCreated() ? .enterPasscode : .createPasscode
    }
    
    func addNumberToPin(_ number: Int) {
        pin.append(number)
        
        if pin.count == pinLength {
            switch state {
                case .createPasscode:
                    state = .repeatPasscode(pin)
                    clearPin()
                case .repeatPasscode(let array):
                    if array == pin {
                        Tracker.trackContentInteraction(name: "Create passcode", interaction: .entered, piece: "Successful 6 digit passcode")
                        keychain.storePassword(password: convertPinToString(array))
                            .onSuccess { [weak self] pwHash in
                                self?.pwHash = pwHash
                                self?.isRequestFaceIDViewShown = true
                            }.onFailure { error in
                                self.error = .somethingWentWrong
                            }
                        clearPin()
                    } else {
                        showErrorPasswordAnimation()
                        clearPin()
                        state = .createPasscode
                    }
                case .enterPasscode:
                    passwordEntered(password: convertPinToString(pin))
                default:
                    clearPin()
            }
        }
    }
    
    func passwordEntered(password: String) {
        let passwordCheck = keychain.checkPassword(password: password)
        let pwHash = keychain.hashPassword(password)
        handlePasswordCheck(checkPassword: passwordCheck, pwHash: pwHash)
    }

    private func handlePasswordCheck(checkPassword: Result<Bool, KeychainError>, pwHash: String) {
        checkPassword
            .onSuccess { [weak self] hash in
                self?.onSuccess(pwHash)
            }
            .onFailure { [weak self] error in
                guard let self = self else { return }
                self.showErrorPasswordAnimation()
                self.clearPin()
            }
    }
    
    func clearPin() {
        pin.removeAll()
    }
    
    private func convertPinToString(_ pin: [Int]) -> String {
        pin.map {String($0)}.joined()
    }
    
    func loginWithBiometric() {
        if AppSettings.biometricsEnabled && biometricsEnabled() {
            keychain.getPasswordWithBiometrics()
                .receive(on: DispatchQueue.main)
                .sink(receiveError: { _ in }, receiveValue: { [weak self] pwHash in
                    self?.handlePWHash(pwHash)
                })
                .store(in: &cancellables)
        }
    }
    
    private func handlePWHash(_ pwHash: String) {
        let passwordCheck = keychain.checkPasswordHash(pwHash: pwHash)
        _ = sanityChecker.generateSanityReport(pwHash: pwHash) // we just make the sanitary report
        handlePasswordCheck(checkPassword: passwordCheck, pwHash: pwHash)
    }
    
    func erasePasscode() {
        keychain.deleteKeychainItem(withKey: KeychainKeys.loginPassword.rawValue)
        AppSettings.biometricsEnabled = false
        state = .createPasscode
    }
    
    private func showErrorPasswordAnimation() {
        isWrongPassword = true
        withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
            isWrongPassword = false
        }
    }
}

/// Biometric
extension PasscodeViewModel {
    func enablebiometric() {
        if biometricsEnabled() {
            let myContext = LAContext()
            let myLocalizedReasonString: String
            switch getBiometricType() {
            case .faceID:
                myLocalizedReasonString = "selectPassword.biometrics.infoText.faceIdText".localized
            case .touchID:
                myLocalizedReasonString = "selectPassword.biometrics.infoText.touchIdText".localized
            default:
                myLocalizedReasonString = ""
            }

            // Hide "Enter Password" button
            myContext.localizedFallbackTitle = ""

            myContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: myLocalizedReasonString) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        Tracker.trackContentInteraction(name: "Dialog: enable biometrics", interaction: .clicked, piece: "success")
                        self.keychain.storePasswordBehindBiometrics(pwHash: self.pwHash ?? "")
                            .receive(on: DispatchQueue.main)
                            .sink(receiveError: { _ in }, receiveValue: { [weak self] _ in
                                AppSettings.biometricsEnabled = true
                                self?.onSuccess(self?.pwHash ?? "")
                            })
                            .store(in: &self.cancellables)
                    } else {
                        Tracker.trackContentInteraction(name: "Dialog: enable biometrics", interaction: .clicked, piece: "not allowed")
                    }
                }
            }
        } else {
            error = .noCameraAccess
            Tracker.trackContentInteraction(name: "Dialog: enable biometrics", interaction: .clicked, piece: "error")
        }
    }
    
    ///
    /// User skips using biometric auth
    ///
    func continueWithoutBiometrics() {
        AppSettings.biometricsEnabled = false
        self.onSuccess(self.pwHash ?? "")
    }
    
    func biometricsEnabled() -> Bool {
        let myContext = LAContext()
        var authError: NSError?
        return myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
    }
    
    func getBiometricType() -> LABiometryType {
        let myContext = LAContext()
        var authError: NSError?
        if myContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            return myContext.biometryType
        } else {
            return .none
        }
    }
}

struct PasscodeView: View {
    @StateObject var viewModel: PasscodeViewModel
    @AppStorage("isFaceIDUnlockEnabled") var isFaceIDUnlockEnabled: Bool = false
    
    @State var animatePasscodeIn: Bool = false
    
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    init(keychain: KeychainWrapperProtocol, sanityChecker: SanityChecker, onSuccess: @escaping (String) -> Void) {
        _viewModel = .init(wrappedValue: .init(keychain: keychain, sanityChecker: sanityChecker, onSuccess: onSuccess))
    }
    
    var body: some View {
        ZStack {
            Image("new_bg").resizable().aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
            passcodeView()
                .padding(.bottom, 100)
                .overlay {
                    if viewModel.isRequestFaceIDViewShown {
                        enableFaceIdView()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.isRequestFaceIDViewShown)
                    }
                }
        }
        .opacity(animatePasscodeIn ? 1.0 : 0)
        .onAppear {
            viewModel.loginWithBiometric()
            withAnimation(.easeInOut.delay(0.2)) {
                self.animatePasscodeIn = true
            }
        }
        .errorAlert(error: $viewModel.error) { appError in
            switch appError {
                case .noCameraAccess: SettingsHelper.openAppSettings()
                default: break
            }
        }
    }
    
    @ViewBuilder
    private func enableFaceIdView() -> some View {
        
        PopupContainer(icon: "enable)face_id_icon",
                       title: "enable_face_id_title".localized,
                       subtitle: "enable_face_id_subtitle".localized,
                       content: enableFaceIdViewButtons(),
                       dismissAction: {
            viewModel.continueWithoutBiometrics()
        })
        .onAppear { Tracker.track(view: ["enable biometrics"]) }
    }

    
    @ViewBuilder
    private func enableFaceIdViewButtons() -> some View {
        Button(action: { viewModel.enablebiometric() }, label: {
            HStack {
                Text("enable_face_id_button_title".localized)
                    .font(Font.satoshi(size: 16, weight: .medium))
                    .lineSpacing(24)
                    .foregroundColor(Color.Neutral.tint1)
            }
            .padding(.horizontal, 24)
        })
        .frame(height: 44)
        .background(Color.Neutral.tint7)
        .cornerRadius(22, corners: .allCorners)
        .padding(.horizontal, 16)
        
        Button(action: { viewModel.continueWithoutBiometrics() }, label: {
            HStack {
                Text("enable_face_id_later_button_title".localized)
                    .font(Font.satoshi(size: 14, weight: .medium))
                    .foregroundColor(Color.Neutral.tint7)
            }
            .padding(.horizontal, 24)
        })
        .padding(.top, 20)
        .padding(.bottom, 36)
    }

    @ViewBuilder
    private func passcodeView() -> some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Text(viewModel.state.title)
                    .font(.satoshi(size: 24, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                    .frame(maxWidth: .infinity)
                
                Text(viewModel.state.subtitle)
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(Color.Neutral.tint2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 16) {
                    ForEach(0..<viewModel.pinLength) { idx in
                        if viewModel.pin.count > idx {
                            Circle()
                                .foregroundStyle(Color.EggShell.tint1)
                                .frame(width: 8, height: 8)
                        } else {
                            Circle()
                                .stroke(style: .init(lineWidth: 1))
                                .foregroundStyle(Color.Neutral.tint4)
                                .frame(width: 8, height: 8)
                        }
                        
                    }
                }
                .offset(x: viewModel.isWrongPassword ? 30 : 0)

            }
            .padding(16)
            Spacer()
            
            numpadView()
        }
        .animation(.easeInOut, value: viewModel.state)
    }
    
    @ViewBuilder
    private func numpadView() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(68+24)), count: 3), spacing: 16, content: {
            ForEach((1...9), id: \.self) { num in
                Button(action: {
                    viewModel.addNumberToPin(num)
                }, label: {
                    Text("\(num)")
                        .font(.satoshi(size: 28, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint7)
                        .padding(.vertical, 20)
                        .contentShape(.rect)
                        .background { Circle().tint(Color.Neutral.tint1).frame(width: 68, height: 68) }
                })
                .frame(width: 68, height: 68)
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.addNumberToPin(0)
            }, label: {
                Text("0")
                    .font(.satoshi(size: 28, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint7)
                    .padding(.vertical, 20)
                    .contentShape(.rect)
                    .background { Circle().tint(Color.Neutral.tint1).frame(width: 68, height: 68) }
            })
            .frame(width: 68, height: 68)
            
            Button(action: {
                if !viewModel.pin.isEmpty {
                    viewModel.pin.removeLast()
                }
            }, label: {
                Image("passcode_clear")
                    .padding(.vertical, 20)
                    .contentShape(.rect)
                
            })
            .frame(width: 68, height: 68)
        })
        .frame(alignment: .bottom)
    }
}
