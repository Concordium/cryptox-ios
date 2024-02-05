//
//  AccountsTab.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 21.12.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AccountsTab: View {
    let keychain: KeychainWrapperProtocol

    @Binding var isCreateAccountSheetShown: Bool
    
    @State var isAnimateIn = false
    
    @SwiftUI.Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationView {
            VStack {
                circles()
                    .overlay(alignment: .top) {
                        VStack(alignment: .center, spacing: 24) {
                            Image("accounta_tab_logo")
                            
                            VStack(alignment: .center, spacing: 12) {
                                HStack(spacing: 4){
                                    Image("Burst-pucker-2")
                                    Text("activate_account_and_get_v2".localized)
                                        .font(Font.satoshi(size: 14, weight: .regular))
                                        .foregroundColor(Color.Neutral.tint2)
                                }
//                                Text("1.000")
//                                    .font(Font.satoshi(size: 28, weight: .medium))
//                                    .foregroundColor(Color.MineralBlue.tint1)
//                                    .overlay(alignment: .bottomTrailing) {
//                                        Text("CCD")
//                                            .font(Font.satoshi(size: 12, weight: .regular))
//                                            .foregroundColor(Color.MineralBlue.tint1)
//                                            .offset(x: 24, y: -4)
//                                    }
                            }
                            
                            Button(action: { openURL(AppConstants.Media.youtube) }, label: {
                                HStack(spacing: 4) {
                                    Text("watch_video".localized)
                                        .font(Font.satoshi(size: 14, weight: .medium))
                                        .foregroundStyle(Color.Neutral.tint1)
                                    Image(systemName: "arrow.up.right").tint(Color.Neutral.tint1)
                                }
                            })
                        }
                        .offset(y: 80)
                    }
                
                VStack(spacing: 8) {
                    Button(action: { isCreateAccountSheetShown.toggle() }, label: {
                        HStack {
                            Text("activate_account_btn_title".localized)
                                .font(Font.satoshi(size: 16, weight: .medium))
                                .foregroundColor(Color.Neutral.tint7)
                            Spacer()
                            Image(systemName: "arrow.right").tint(Color.Neutral.tint7)
                        }
                        .padding(.horizontal, 24)
                    })
                    .frame(height: 56)
                    .background(Color.EggShell.tint1)
                    .cornerRadius(28, corners: .allCorners)
                    
                    askAiCard()
                        .padding(.bottom, 64)
                        .contentShape(.rect)
                        .onTapGesture {
                            openURL(AppConstants.Media.ai)
                        }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 64)
            }
            .onAppear {
                withAnimation {
                    isAnimateIn = true
                }
            }
            .onDisappear {
                isAnimateIn = false
            }
            .modifier(AppBackgroundModifier())
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(.stack)
    }
    
    @ViewBuilder
    func circles() -> some View {
        GeometryReader(content: { geometry in
            Circle()
                .stroke(Color.EggShell.tint1.opacity(0.1), lineWidth: 1)
                .frame(width: geometry.size.width-48, height: geometry.size.width-48)
                .offset(x: 24, y: 24)
                .animation(.easeInOut(duration: 0.5), value: isAnimateIn).opacity(isAnimateIn ? 1.0 : 0)
            Circle()
                .stroke(Color.EggShell.tint1.opacity(0.1), lineWidth: 1)
                .frame(width: geometry.size.width-48, height: geometry.size.width-48)
                .offset(x: -(geometry.size.width-48-48), y: 24)
                .animation(.easeInOut(duration: 1).delay(1), value: isAnimateIn).opacity(isAnimateIn ? 1.0 : 0)
            Circle()
                .stroke(Color.EggShell.tint1.opacity(0.1), lineWidth: 1)
                .frame(width: geometry.size.width-48, height: geometry.size.width-48)
                .offset(x: geometry.size.width-48, y: 24)
                .animation(.easeInOut(duration: 1).delay(1), value: isAnimateIn).opacity(isAnimateIn ? 1.0 : 0)
        })
    }
    
    @ViewBuilder
    func askAiCard() -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(spacing: 4) {
                    Text("ask_ai_title".localized)
                        .font(Font.satoshi(size: 16, weight: .medium))
                        .foregroundColor(Color.Neutral.tint1)
                    Text("ask_ai_subtitle".localized)
                        .font(Font.satoshi(size: 14, weight: .regular))
                        .foregroundColor(Color.Neutral.tint2)
                }
                Spacer()
                Image("ask_ai")
            }
            .padding(.horizontal ,16)
            .padding(.top, 16)
            
            VStack(spacing: 16) {
                Divider()
                HStack {
                    Text("ask_ai_promt_placeholder".localized)
                        .font(Font.satoshi(size: 14, weight: .regular))
                        .foregroundColor(Color.Neutral.tint4)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
            .background(Color.Neutral.tint5)
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .inset(by: 0.5)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05), lineWidth: 1)
            
        )
    }
}
