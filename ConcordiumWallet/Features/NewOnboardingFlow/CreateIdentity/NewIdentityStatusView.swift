//
//  NewIdentityStatusView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 05.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import Combine

extension NewIdentityStatusViewModel.State {
    var titleKey: String {
        switch self {
            case .approved: return "entity_status_approved_title"
            case .pending: return "entity_status_pending_title"
            case .rejected: return "entity_status_rejected_title"
        }
    }
    
    var color: Color {
        switch self {
            case .approved: return Color.Status.success
            case .pending: return Color.Status.warning
            case .rejected: return Color.Status.error
        }
    }
}
extension NewIdentityStatusViewModel.StateAlertType {
    var title: String {
        switch self {
            case .submitted: return "submitted_verification_request_title".localized
            case .approved: return "approved_verification_request_title".localized
                
        }
    }
    var subtitle: String {
        switch self {
            case .submitted: return "submitted_verification_request_subtitle".localized
            case .approved: return "approved_verification_request_subtitle".localized
                
        }
    }
    var img: String {
        switch self {
            case .submitted:
                return "alert_submitted_ico"
            case .approved:
                return "alert_approved_ico"
        }
    }
}

final class NewIdentityStatusViewModel: ObservableObject {
    enum State {
        case approved, pending, rejected
    }
    
    enum StateAlertType {
        case submitted, approved
    }
    
    var identity: IdentityDataType
    let identitiesService: SeedIdentitiesService
    
    @Published var state: State = .pending
    @Published var identityName: String
    @Published var expiresOn: String?
    @Published var stateAlertType: StateAlertType?
    
    private var bag = Set<AnyCancellable>()

    init(identity: IdentityDataType, identitiesService: SeedIdentitiesService) {
        self.identity = identity
        self.identitiesService = identitiesService
        self.identityName = identity.nickname
        
        updatePendingIdentity(identity: identity)
        
        $state.removeDuplicates().sink { stateUpdate in
            switch stateUpdate {
                case .approved:
                    self.stateAlertType = .approved
                case .pending:
                    self.stateAlertType = .submitted
                case .rejected:
                    self.stateAlertType = nil
            }
        }.store(in: &bag)
    }
    
    func dismissFlow() {
        
    }
    
    private func updatePendingIdentity(
        identity: IdentityDataType,
        after delay: TimeInterval = 1.0
    ) {
        guard identity.state == .pending else {
            receiveUpdatedIdentity(identity: identity)
            return
        }
        
        Task.init {
            try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            
            let updatedIdentity = try await self.identitiesService
                .updatePendingSeedIdentity(identity)
            
            DispatchQueue.main.async {
                self.receiveUpdatedIdentity(identity: updatedIdentity)
            }
        }
    }
    
    private func receiveUpdatedIdentity(identity: IdentityDataType) {
        self.identity = identity
        
        switch identity.state {
            case .pending:
                updatePendingIdentity(identity: identity, after: 5)
                self.state = .pending
            case .confirmed:
                self.state = .approved
            case .failed:
                state = .rejected
        }
    }
}

struct NewIdentityStatusView: View {
    @StateObject var viewModel: NewIdentityStatusViewModel
    var onIdentityCreated: () -> Void
    var onIdentityCreationFailed: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Text("identity_verification_title".localized)
                    .font(.satoshi(size: 24, weight: .medium))
                    .foregroundStyle(Color.Neutral.tint1)
                .padding(.top, 64)
                
                identityCard()
                
                Spacer()
                
                if viewModel.state == .approved {
                    Button(action: {
                        self.onIdentityCreated()
                    }, label: {
                        HStack {
                            Text("create_account_btn_title".localized)
                                .font(Font.satoshi(size: 16, weight: .medium))
                                .lineSpacing(24)
                                .foregroundColor(Color.Neutral.tint7)
                            Spacer()
                            Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                        }
                        .padding(.horizontal, 24)
                    })
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28, corners: .allCorners)
                    .padding(16)
                } else if viewModel.state == .rejected {
                    Button(action: {
                        self.onIdentityCreationFailed()
                    }, label: {
                        HStack {
                            Text("identityStatus.failed".localized + ". " + "identityfailed.tryagain".localized)
                                .font(Font.satoshi(size: 16, weight: .medium))
                                .lineSpacing(24)
                                .foregroundColor(Color.Neutral.tint7)
                            Spacer()
                            Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                        }
                        .padding(.horizontal, 24)
                    })
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28, corners: .allCorners)
                    .padding(16)
                } else {
                    Text("new_identity_status_bottom_desription".localized)
                        .multilineTextAlignment(.center)
                        .font(.satoshi(size: 14, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint2)
                        .padding(16)
                }
            }
            
            if let alert = viewModel.stateAlertType {
                alertOverlay(title: alert.title, subtitle: alert.subtitle, image: alert.img) {
                    viewModel.stateAlertType = nil
                }
                .animation(.easeInOut.delay(0.3), value: viewModel.stateAlertType)
            }
        }
        .modifier(AppBackgroundModifier())
    }
    
    @ViewBuilder
    func identityCard() -> some View {
        VStack {
            VStack(alignment: .center, spacing: 16) {
                Image("pending_identity_logo")
                VStack {
                    Text(viewModel.state.titleKey.localized)
                        .font(.plexMono(size: 12, weight: .medium))
                        .foregroundStyle(viewModel.state.color)
                    
                    Text(viewModel.identityName)
                        .font(.satoshi(size: 20, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint1)
                    if viewModel.expiresOn != nil {
                        Text(viewModel.expiresOn ?? "")
                            .font(.satoshi(size: 12, weight: .regular))
                            .foregroundStyle(Color.Neutral.tint2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color.Neutral.tint5)
        .frame(maxWidth: .infinity)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func alertOverlay(title: String, subtitle: String, image: String, _ action: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 16) {
                Image(image)
                    .padding(.top, 56)
                
                VStack(spacing: 16) {
                    Text(title)
                        .font(.satoshi(size: 20, weight: .medium))
                        .foregroundStyle(Color.Neutral.tint7)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                    Text(subtitle)
                        .font(.satoshi(size: 14, weight: .regular))
                        .foregroundStyle(Color.Neutral.tint5)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                    
                    Button(action: action, label: {
                        HStack {
                            Text("got_it_btn_title".localized)
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
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Image("modal_bg").resizable().ignoresSafeArea())
            .cornerRadius(20, corners: .allCorners)
            .clipped()
            .padding(.horizontal, 32)
            .overlay(alignment: .topTrailing) {
                Button(
                    action: {
                        action()
                        Tracker.trackContentInteraction(name: "Verification request approved", interaction: .clicked, piece: "Got it")
                    },
                    label: {
                    Image("ic 24")
                }).offset(x: -48, y: 16)
            }
            .onAppear {
                Tracker.track(view: ["Verification request approved"])
            }
        }
    }
}
