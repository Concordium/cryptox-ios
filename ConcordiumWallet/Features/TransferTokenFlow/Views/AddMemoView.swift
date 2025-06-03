//
//  AddMemoView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 23.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct AddMemoView: View {
    @StateObject var viewModel: AddMemoViewModel

    @State private var memoText: String = ""
    @State private var shouldShake: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var onMemoAdded: ((Memo?) -> Void)
    @State private var isPlaceholderHidden: Bool = false

    var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .leading) {
                if !isPlaceholderHidden {
                    Text(" Add a memo")
                        .font(.satoshi(size: 14, weight: .medium))
                        .foregroundStyle(Color.MineralBlue.blueish3.opacity(0.5))
                        .allowsHitTesting(false) // Prevent interactions with placeholder
                }
                TextEditor(text: $memoText)
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .background(.clear)
                    .scrollContentBackground(.hidden)
                    .tint(.white)
                    .focused($isTextFieldFocused)
                    .onChange(of: memoText) { newValue in
                        isPlaceholderHidden = !newValue.isEmpty
                        newValue.isEmpty ? viewModel.removeMemo() : viewModel.updateMemo(newValue)
                        onMemoAdded(viewModel.memo)
                    }
            }
            Spacer()
            if !memoText.isEmpty {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.MineralBlue.blueish3)
                    .frame(width: 18, height: 18)
                    .onTapGesture {
                        withAnimation {
                            memoText = ""
                            viewModel.removeMemo()
                        }
                    }
            }
        }
        .onAppear {
            memoText = viewModel.memo?.displayValue ?? ""
            isPlaceholderHidden = !memoText.isEmpty
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    viewModel.invalidMemoSizeError ? Color.attentionRed : (isTextFieldFocused ? Color.MineralBlue.blueish3 : Color(red: 0.17, green: 0.19, blue: 0.2)),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
        .modifier(ShakeViewModifier(animating: shouldShake))
        .frame(minHeight: 59)
        .onReceive(viewModel.$shakeTextView) { shouldShake in
            if shouldShake {
                HapticFeedbackHelper.generate(feedback: .light)
                withAnimation {
                    self.shouldShake = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.shouldShake = false
                }
            }
        }
    }
}
