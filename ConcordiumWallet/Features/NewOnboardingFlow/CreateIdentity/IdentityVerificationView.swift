//
//  IdentityVerificationView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 03.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

struct NewIdentityRequest: Identifiable {
    var id: String { identityRequest.id }
    var identityRequest: IDPIdentityRequest
    var ipData: IPInfoResponseElement
}

final class IdentityVerificationViewModel: ObservableObject {
    @Published var identityProviders = [IPInfoResponseElement]()
    @Published var isLoading: Bool = true
    @Published var error: GeneralAppError?
    
    @Published var identityRequest: NewIdentityRequest?
    
    var selectedidentity: IPInfoResponseElement?
    
    private let identitiesService: SeedIdentitiesService
    private var cancellables: [AnyCancellable] = []
    private var onIdentityCreated: (IdentityDataType) -> Void
    
    init(identitiesService: SeedIdentitiesService, onIdentityCreated: @escaping (IdentityDataType) -> Void) {
        self.identitiesService = identitiesService
        self.onIdentityCreated = onIdentityCreated
        
        updateIdentityProviders()
    }
    
    func updateIdentityProviders() {
        Task {
            do {
                let ipInfo = try await identitiesService.getIpInfo()
                DispatchQueue.main.async {
                    self.identityProviders = ipInfo
                    self.isLoading = false
                }
            } catch {
                self.isLoading = false
            }
        }
    }
    
    func selectIdentityProvider(_ ipData: IPInfoResponseElement, pwHash: String) {
        self.selectedidentity = ipData
        PermissionHelper.requestAccess(for: .camera) { [weak self] permissionGranted in
            guard let self = self else { return }
            
            guard permissionGranted else {
                self.error = .noCameraAccess
                return
            }

            
            Task {
                do {
                    let request = try await self.identitiesService.requestNextIdentity(from: ipData, pwHash: pwHash)
                    DispatchQueue.main.async {
                        self.identityRequest = NewIdentityRequest(identityRequest: request, ipData: ipData)
                    }
                } catch {
                    switch error {
                    case ViewError.userCancelled:
                        break
                    default:
                        self.error = .somethingWentWrong
                    }
                }
            }
        }
    }
    
    
    func handleCallback(_ callback: String, request: NewIdentityRequest) {
        guard let url = URL(string: callback) else {
            return
        }
        
        if let (identityCreationId, pollUrl) = ApiConstants.parseCallbackUri(uri: url) {
            handleIdentitySubmitted(identityCreationId: identityCreationId, pollUrl: pollUrl, request: request)
        } else {
            handleErrorCallback(url: url)
        }
    }
    
    private func handleIdentitySubmitted(identityCreationId: String, pollUrl: String, request: NewIdentityRequest) {
        guard identityCreationId == request.id else { return }
        
        do {
            let identity = try identitiesService.createPendingIdentity(
                identityProvider: request.identityRequest.identityProvider,
                pollURL: pollUrl,
                index: request.identityRequest.index
            )
            self.onIdentityCreated(identity)
        } catch {
            self.error = .somethingWentWrong
        }
    }
    
    private func handleErrorCallback(url: URL) {
        guard let errorString = url.queryFragments?["error"]?.removingPercentEncoding else {
            return
        }
        
        do {
            let error = try IdentityProviderErrorWrapper(errorString)
            
            if error.error.code == "USER_CANCEL" {
//                delegate?.cancelCreateIdentity()
            } else {
                let serverError = ViewError.simpleError(localizedReason: error.error.detail)
//                delegate?.createIdentityView(failedToLoad: serverError)
            }
        } catch {
            self.error = .somethingWentWrong
        }
    }
}

struct IdentityVerificationView: View {
    @StateObject var viewModel: IdentityVerificationViewModel
    
    @State var selectedProvider: IPInfoResponseElement?
    
    @State var isAuthShown: Bool = false
    
    @EnvironmentObject var sanityChecker: SanityChecker
    
    enum IdentityVerificationViewState {
        case pickIdentity, pickedIdentity(IPInfoResponseElement)
    }
    
    var body: some View {
        ZStack {
            VStack {
                VStack(spacing: 8) {
                    Text("identity_verification_title".localized)
                        .font(.satoshi(size: 24, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint1)
                    Text("indentity_verification_subtitle".localized)
                        .font(.satoshi(size: 14, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint2)
                }
                .padding(.top, 64)
                
                if viewModel.isLoading {
                    Spacer()
                    LoadingIndicator()
                    Spacer()
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], content: {
                        ForEach(viewModel.identityProviders, id: \.ipInfo.ipIdentity) { provider in
                            identityView(provider)
                                .contentShape(.rect)
                                .onTapGesture {
                                    self.selectedProvider = provider
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isAuthShown.toggle()
                                    }
                                }
                        }
                    })
                }
                .padding(16)
            }
            
            if isAuthShown {
                PasscodeView(keychain: KeychainWrapper(), sanityChecker: sanityChecker) { pwHash in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAuthShown = false
                    }
                    guard let provider = self.selectedProvider else { return }
                    viewModel.selectIdentityProvider(provider, pwHash: pwHash)
                }
            }
        }
        .modifier(AppBackgroundModifier())
        .errorAlert(error: $viewModel.error) { appError in
            switch appError {
                case .noCameraAccess: SettingsHelper.openAppSettings()
                default: break
            }
        }
        .fullScreenCover(item: $viewModel.identityRequest) { request in
            IdentityCreateWebView(request: request.identityRequest.resourceRequest.request!) { some in
                viewModel.handleCallback(some, request: request)
            } onError: { error in }
            .overlay(alignment: .topTrailing) {
                Button(action: { viewModel.identityRequest = nil }, label: {
                    Image(systemName: "xmark")
                        .font(.callout)
                        .frame(width: 35, height: 35)
                        .foregroundStyle(Color.primary)
                        .background(.ultraThinMaterial, in: .circle)
                        .contentShape(.circle)
                })
                .padding(.top, 12)
                .padding(.trailing, 15)
            }
        }
    }
    
    @ViewBuilder
    func identityView(_ provider: IPInfoResponseElement) -> some View {
        VStack {
            VStack(alignment: .center, spacing: 16) {
                Image.init(base64String: provider.metadata.icon)?
                    .resizable()
                    .frame(width: 60, height: 60)
                Text(provider.displayName)
                    .font(.satoshi(size: 16, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color.Neutral.tint6)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
        )
    }
}

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        let insertion = AnyTransition.fade
            .combined(with: .opacity)
        let removal = AnyTransition.fade.combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}
