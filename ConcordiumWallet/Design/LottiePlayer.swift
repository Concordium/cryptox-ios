//
//  LottiePlayer.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import Lottie
import UIKit
import SwiftUI

struct LottiePlayer: UIViewRepresentable {
    let name: String
    var segment: ClosedRange<Int>? = nil
    var loopMode: LottieLoopMode = .playOnce
    var playToken: Int
    var scale: CGFloat = 1.0

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let animationView = LottieAnimationView(name: name, bundle: .main)

        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore

        container.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        animationView.transform = CGAffineTransform(scaleX: scale, y: scale)

        context.coordinator.view = animationView
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = context.coordinator.view else { return }

        animationView.transform = CGAffineTransform(scaleX: scale, y: scale)

        if let segment {
            animationView.play(fromFrame: .init(segment.lowerBound),
                               toFrame:   .init(segment.upperBound),
                               loopMode:  loopMode)
        } else {
            animationView.loopMode = loopMode
            animationView.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var view: LottieAnimationView?
    }
}
