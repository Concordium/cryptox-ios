//
//  ToastGradientView.swift
//  CryptoX
//
//  Created by Zhanna Komar on 10.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ToastGradientView: View {
    @State private var isVisible = false
    var title: String
    var imageName: String

    var body: some View {
        VStack {
            if isVisible {
                VStack(alignment: .center) {
                    HStack(spacing: 16) {
                        Image(imageName)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.stone)
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.satoshi(size: 15, weight: .medium))
                                .foregroundStyle(.grey2)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 43)
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.62, green: 0.95, blue: 0.92),
                                    Color(red: 0.93, green: 0.85, blue: 0.75),
                                    Color(red: 0.64, green: 0.6, blue: 0.89)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 400
                            )
                        )
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: isVisible)
            }
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

struct Toast: ViewModifier {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let toastContent: () -> AnyView
    let position: Alignment
    
    func body(content: Content) -> some View {
        ZStack(alignment: position) {
            content
            if isPresented {
                toastContent()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: isPresented)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

class ToastGradientUIView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    
    init(title: String, imageName: String) {
        super.init(frame: .zero)
        setupView(title: title, imageName: imageName)
        setupGradient()
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(title: String, imageName: String) {
        imageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = title
        titleLabel.textColor = .black
        titleLabel.font = UIFont.satoshi(size: 15, weight: .medium)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel])
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -15)
        ])
        
        layer.cornerRadius = 30
        layer.masksToBounds = true
    }
    
    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.62, green: 0.95, blue: 0.92, alpha: 1).cgColor,
            UIColor(red: 0.93, green: 0.85, blue: 0.75, alpha: 1).cgColor,
            UIColor(red: 0.64, green: 0.6, blue: 0.89, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1.3)
        gradientLayer.cornerRadius = 30
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupAnimation() {
        alpha = 0
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIView.animate(withDuration: 0.5, animations: {
                    self.alpha = 0
                }) { _ in
                    self.removeFromSuperview()
                }
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
