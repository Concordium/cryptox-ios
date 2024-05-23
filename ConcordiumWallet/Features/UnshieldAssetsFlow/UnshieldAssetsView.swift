//
//  UnshieldAssetsView.swift
//  CryptoX
//
//  Created by Max on 21.05.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct UnshieldAssetsView: View {
    @StateObject var viewModel: UnshieldAssetsViewModel
    
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.14, green: 0.14, blue: 0.15), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.03, green: 0.03, blue: 0.04), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .ignoresSafeArea(.all)
            VStack(alignment: .center, spacing: 32) {
                VStack(spacing: 20) {
                    Text("Shielded amount:")
                        .font(.satoshi(size: 11, weight: .medium))
                        .foregroundStyle(Color.blackAditional)
                    Text(TokenFormatter().plainString(from: viewModel.unshieldAmount))
                        .font(.satoshi(size: 40, weight: .medium))
                        .foregroundStyle(Color.white)
                        .overlay(alignment: .topTrailing) {
                            Text("CCD")
                                .lineLimit(1)
                                .font(.satoshi(size: 12, weight: .medium))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.73, green: 0.75, blue: 0.78))
                                .cornerRadius(4)
                                .offset(x: 38)
                        }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 64)
                
                VStack(spacing: 8) {
                    Text("Estimated transaction fee:")
                        .font(.satoshi(size: 11, weight: .medium))
                        .foregroundStyle(Color.blackAditional)
                    if viewModel.isLoadingTxCost {
                        ProgressView()
                    } else {
                        Text(viewModel.fee)
                            .font(.satoshi(size: 14, weight: .medium))
                            .foregroundStyle(Color.white)
                    }
                    if let error = viewModel.error {
                        Text(error)
                            .multilineTextAlignment(.center)
                            .font(.satoshi(size: 14, weight: .medium))
                            .foregroundStyle(Color.red)
                    }
                }
                
                Spacer()
                
                Button {
                    Vibration.vibrate(with: .light)
                    viewModel.unshieldAssets(onSuccess: {
                        dismiss()
                    })
                } label: {
                    Group {
                        if viewModel.isUnshielding {
                            ProgressView()
                        } else {
                            Text("Unshield funds")
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(Color.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
                    .contentShape(.rect)
                }
                .background(.white)
                .cornerRadius(48)
                .padding(.horizontal, 16)
                .padding(.bottom, 56)
                .disabled(viewModel.isUnshielding || viewModel.isUnshieldButtonDisabled)
                .opacity(viewModel.isUnshielding ? 0.7 : 1.0)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .offset(y: 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image("backButtonIcon")
                        .foregroundColor(Color.Neutral.tint1)
                        .frame(width: 35, height: 35)
                        .contentShape(.circle)
                }
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(viewModel.displayName)
                        .font(.satoshi(size: 17, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
        }
    }
}
