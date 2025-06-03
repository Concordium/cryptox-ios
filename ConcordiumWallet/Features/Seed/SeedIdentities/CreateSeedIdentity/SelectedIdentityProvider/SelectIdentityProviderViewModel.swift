//
//  SelectIdentityProviderViewModel.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 04/08/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import Foundation

enum SelectIdentityProviderEvent {
    case showInfo(url: URL)
    case selectIdentityProvider(identityProvider: IPInfoResponseElement)
}

protocol SelectIdentityProviderPresenterDelegate: RequestPasswordDelegate {
    func showIdentityProviderInfo(url: URL)
    func createIdentityRequestCreated(_ request: IDPIdentityRequest, isNewIdentityAfterSettingUpTheWallet: Bool)
}

//class SelectIdentityProviderViewModel2: PageViewModel<SelectIdentityProviderEvent> {
//    @Published var identityProviders: [IPInfoResponseElement]
//    @Published var isNewIdentityAfterSettingUpTheWallet: Bool
//    
//    init(
//        identityProviders: [IPInfoResponseElement], isNewIdentityAfterSettingUpTheWallet: Bool
//    ) {
//        self.identityProviders = identityProviders
//        self.isNewIdentityAfterSettingUpTheWallet = isNewIdentityAfterSettingUpTheWallet
//        
//        super.init()
//    }
//}


final class SelectIdentityProviderViewModel: ObservableObject {
    @Published var identityProviders: [IPInfoResponseElement] = []
    @Published var isLoading: Bool = false
    @Published var error: IdentityProviderListError? = nil
    @Published var isNewIdentityAfterSettingUpTheWallet: Bool
    private var ignoreInput = false
    
    private var identitiesService: SeedIdentitiesService
    private weak var delegate: SelectIdentityProviderPresenterDelegate?
    
    init(
        identitiesService: SeedIdentitiesService,
        delegate: SelectIdentityProviderPresenterDelegate,
        isNewIdentityAfterSettingUpTheWallet: Bool = false
    ) {
        self.identitiesService = identitiesService
        self.delegate = delegate
        self.isNewIdentityAfterSettingUpTheWallet = isNewIdentityAfterSettingUpTheWallet
        
        loadIdentityProviders()
    }
    
    func loadIdentityProviders() {
        isLoading = true
        Task {
            do {
                let ipInfo = try await identitiesService.getIpInfo()
                await MainActor.run {
                    self.identityProviders = ipInfo
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = .error(error)
                }
            }
        }
    }
    
    func selectIdentityProvider(_ ipData: IPInfoResponseElement) {
        ignoreInput = true
        PermissionHelper
            .requestAccess(for: .camera) { [weak self] permissionGranted in
                guard let self = self else { return }
                guard let delegate = self.delegate else {
                    self.ignoreInput = false
                    return
                }
                
                if !permissionGranted {
                    self.ignoreInput = false
                    self.error = .cameraAccessDenied
                    return
                }
                
                DispatchQueue.main.async {
                    self.isLoading = true
                }
                Task {
                    do {
                        let request = try await self.identitiesService.requestNextIdentity(
                            from: ipData,
                            requestPasswordDelegate: delegate
                        )
                        DispatchQueue.main.async {
                            self.delegate?.createIdentityRequestCreated(
                                request,
                                isNewIdentityAfterSettingUpTheWallet: self.isNewIdentityAfterSettingUpTheWallet
                            )
                        }
                    } catch {
                        switch error {
                        case ViewError.userCancelled:
                            break
                        default:
                            self.error = .error(error)
                        }
                    }
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
    }
    
    func showInfo(url: URL) {
        delegate?.showIdentityProviderInfo(url: url)
    }
}
