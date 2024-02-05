//
//  XButton.swift
//  ConcordiumWallet
//
//  Created by Maksym Rachytskyy on 03.05.2023.
//  Copyright © 2023 concordium. All rights reserved.
//

import UIKit

public class TapAnimationConfigurator {
    public static func addTapBeganAnimation(_ animator: UIViewPropertyAnimator, target view: UIView) {
        animator.pausesOnCompletion = true
        animator.isReversed = false
        animator.addAnimations {
            view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    public static func addTapEndedAnimation(_ animator: UIViewPropertyAnimator, target view: UIView) {
        if !animator.isRunning {
            animator.isReversed = true
            animator.continueAnimation(withTimingParameters: animator.timingParameters, durationFactor: 1)
        } else {
            animator.pausesOnCompletion = false
            animator.addCompletion { _ in
                UIViewPropertyAnimator.runningPropertyAnimator(
                    withDuration: 0.2,
                    delay: 0,
                    options: .curveEaseOut)
                {
                    view.transform = .identity
                }
            }
        }
    }
}

extension UIFont {
    static var button: UIFont { UIFont.systemFont(ofSize: 17, weight: .semibold) }
}

struct XButtonStyle {
    enum Corner {
        case none, pill, radius(CGFloat)
    }
    
    var titleFont: UIFont = UIFont.button
    var titleColor: UIColor = UIColor.greyAdditional
    
    var backgroundColor: UIColor = UIColor.clear
    
    var corner: XButtonStyle.Corner = .none
    var borderColor: UIColor = .clear
    var borderWidth: CGFloat = 0
}

extension XButtonStyle {
    static var none: XButtonStyle { .init() }
    
    static var whiteStrokePill: XButtonStyle { .init(corner: .pill, borderColor: .white, borderWidth: 2) }
}

extension XButtonStyle.Corner {
    public func radius(for rect: CGRect) -> CGFloat {
        switch self {
            case .none: return 0
            case .pill: return min(rect.width/2, rect.height/2)
            case .radius(let radius): return radius
        }
    }
}

class XButton: UIButton {
    private let tapAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut)
    
    private var style: XButtonStyle = .none {
        didSet {
            updateStyle()
        }
    }
    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: 58) }

    public func applyStyle(_ style: XButtonStyle) { self.style = style }
    public func forceStopAnimation() { tapAnimator.stopAnimation(true) }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = style.corner.radius(for: bounds)
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
            ? style.backgroundColor.withAlphaComponent(0.7)
            : style.backgroundColor
            
            isHighlighted ? animateTapBegun() : animateTapEnded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateStyle()
    }
    
    private func updateStyle() {
        layer.borderColor = style.borderColor.cgColor
        layer.borderWidth = style.borderWidth
        
        setTitleColor(style.titleColor, for: .normal)
        setTitleColor(style.titleColor, for: .selected)
        setTitleColor(style.titleColor.withAlphaComponent(0.7), for: .disabled)
        titleLabel?.font = style.titleFont
        backgroundColor = style.backgroundColor
    }
    
    private func animateTapBegun() {
        TapAnimationConfigurator.addTapBeganAnimation(tapAnimator, target: self)
        tapAnimator.startAnimation()
    }
    
    private func animateTapEnded() {
        TapAnimationConfigurator.addTapEndedAnimation(tapAnimator, target: self)
    }
    
    deinit { forceStopAnimation() }
}
