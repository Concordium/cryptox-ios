//
//  StateStatusView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 26.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct StateStatusView: View {
    @ObservedObject var viewModel: StakeStatusViewModel
    @State private var updateTimer: Timer?
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                    
                    Text(viewModel.topText)
                        .font(.satoshi(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .center)
//                .background(Color(.blackSecondary))
                .cornerRadius(16)
                .padding(.horizontal, 16)
                
                if !viewModel.rows.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.rows) { row in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(row.headerLabel)
                                    .font(.satoshi(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text(row.valueLabel)
                                    .font(.satoshi(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                if row != viewModel.rows.last {
                                    Divider()
                                        .tint(Color.blackAditional)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blackAditional, lineWidth: 1))
                    .padding()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Inactive Stake")
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("You don’t receive rewards from this part of stake now, this amount will be at disposal after cooldown period.")
                        .font(.satoshi(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Text("5.00")
                            .font(.satoshi(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Cooldown time:")
                            .font(.satoshi(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("9")
                            .foregroundColor(.white)
                            .font(.satoshi(size: 14, weight: .bold))
                        Text("days left")
                            .font(.satoshi(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.blackSecondary))
                .cornerRadius(16)
                .padding([.leading, .trailing], 16)
                .padding(.top, 10)
                
                Spacer()
                
                VStack(spacing: 10) {
                    if viewModel.stopButtonShown {
                        Button(action: {
                            viewModel.pressedStopButton()
                        }) {
                            Text(viewModel.stopButtonLabel)
                                .font(.satoshi(size: 17, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 48)
                                    .stroke(Color.white, lineWidth: 1))
                                .foregroundColor(.white)
                        }
                        .disabled(!viewModel.stopButtonEnabled)
                    }
                    Button(action: {
                        viewModel.pressedButton()
                    }) {
                        Text("Update current delegation")
                            .font(.satoshi(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 48)
                                .foregroundColor(.white))
                            .foregroundColor(.black)
                    }
                    .disabled(!viewModel.updateButtonEnabled)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .onAppear {
                startUpdateTimer()
            }
            .onDisappear {
                stopUpdateTimer()
            }
        }
        .modifier(AppBackgroundModifier())
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                    viewModel.closeButtonTapped()
                } label: {
                    Image("backButtonIcon")
                        .foregroundColor(Color.Neutral.tint1)
                        .frame(width: 35, height: 35)
                        .contentShape(.circle)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(viewModel.title)
                        .font(.satoshi(size: 17, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
        }
    }

    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            viewModel.updateStatus()
        }
    }
    
    func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

#Preview {
    StateStatusView(viewModel: StakeStatusViewModel(account: AccountDataTypeFactory.create(), dependencyProvider: ServicesProvider.defaultProvider()))
}
