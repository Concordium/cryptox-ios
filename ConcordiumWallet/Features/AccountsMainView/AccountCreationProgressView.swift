//
//  AccountCreationProgressView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 24.10.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AccountCreationProgressView: View {
    @State private var progress: Float = 0
    @State var targetProgress: Float
    @State var stepName: String
    private let size: CGFloat = 56.0

    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Image("card_bg")
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 14) {
                    Text("setup_progress_title".localized)
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(Color.greyMain)
                    ProgressView(value: progress)
                        .frame(height: 11)
                        .progressViewStyle(CustomProgressViewStyle(trackColor: .greenDark, progressColor: .greenMain))
                        .cornerRadius(5)
                    Text(stepName)
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(Color.greyMain)
                }
                .padding(16)
                .cornerRadius(15)
            }

            HStack(alignment: .center) {
                Spacer()
                
                Image("ico_plus")
                    .frame(width: 26, height: 26)
                    .foregroundStyle(Color.blackAditional)
                
                Spacer()
                
                    Divider()
                        .background(Color.blackAditional)
                
                Spacer()
                
                Image("ico_share")
                    .renderingMode(.template)
                    .frame(width: 26, height: 26)
                    .foregroundStyle(Color.blackAditional)
                
                Spacer()
                
                    Divider()
                        .background(Color.blackAditional)
                
                Spacer()
                
                Image("ico_qr")
                    .frame(width: 26, height: 26)
                    .foregroundStyle(Color.blackAditional)
                
                Spacer()
            }
            .overlay(
                Rectangle()
                    .frame(height: 1.5)
                    .foregroundColor(Color.blackAditional)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .offset(y: -13)
            )
            .padding(8)
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.5)
                .stroke(Color.blackAditional, lineWidth: 1.5)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                progress = targetProgress
            }
        }
        .frame(height: 132)
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    var trackColor: Color
    var progressColor: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                trackColor
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(5)
                
                progressColor
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: geometry.size.height)
                    .cornerRadius(5)
            }
        }
    }
}


#Preview {
    AccountCreationProgressView(targetProgress: 1 / 3, stepName: "STEP 1")
}
