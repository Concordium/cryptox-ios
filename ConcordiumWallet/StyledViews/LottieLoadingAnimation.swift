//
//  LottieLoadingAnimation.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.08.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Foundation
import SwiftUI
import Lottie

struct LottieLoadingAnimation: View {
    private enum AnimationState { case loader, success, failure }

    @Binding var isTransactionExecuting: Bool
    @Binding var error: Error?
    @State private var animationState: AnimationState = .loader
    @State private var currentSegment: ClosedRange<Int>? = 0...120
    @State private var loopMode: LottieLoopMode = .loop
    @State private var playToken: Int = 0
    private let animationFile = "loadingAnimation"

    var body: some View {
        animationView()
            .id(animationState)
            .frame(width: 60, height: 60)
            .onAppear {
                playAnimationBasedOnState()
            }
            .onChange(of: isTransactionExecuting) { _ in
                playAnimationBasedOnState()
            }
    }
    
    @ViewBuilder
    private func animationView() -> some View {
        LottiePlayer(name: animationFile,
                     segment: currentSegment,
                     loopMode: loopMode,
                     playToken: playToken)
    }

    private func playAnimationBasedOnState() {
        switch (isTransactionExecuting, error != nil) {
        case (true, _):
            animationState = .loader
            currentSegment = 0...120
            loopMode = .loop
        case (false, true):
            animationState = .failure
            currentSegment = 300...360
            loopMode = .playOnce
        default:
            animationState = .success
            currentSegment = 121...239
            loopMode = .playOnce
        }
        playToken += 1
    }
}
