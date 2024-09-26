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
    
    var body: some View {
            VStack {
                // Back button and title
                HStack {
                    Button(action: {
                        // Back action
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(.leading)
                    }
                    Spacer()
                    Text(viewModel.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    Spacer()
                }
                .padding(.top, 10)
                
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                    Text(viewModel.topText)
                        .font(.satoshi(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color(.blackSecondary))
                .cornerRadius(20)
//                .padding([.leading, .trailing], 16)
                
                // Delegation information container
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
                // Inactive stake section
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
                
                // Stop delegation and update buttons
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
            .background(Image("bg_main").resizable().scaledToFill().edgesIgnoringSafeArea(.all))
        }
    // Timer Logic
    func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            //            viewModel.updateStatus()
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
