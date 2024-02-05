//
//  AccountActionButtons.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 25.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

private let size: CGFloat = 56

struct AccountActionButtons: View {
    var isShielded: Bool
    
    var actionSend: () -> Void
    var actionReceive: () -> Void
    var actionEarn: () -> Void
    var actionShield: () -> Void
    var actionSettings: () -> Void
    
    @State var disabled: Bool = false
    
    var body: some View {
        VStack {
            Divider()
            HStack(alignment: .center, spacing: 0) {
                AccountActionButton(imageName: "button_slider_send", disabled: disabled, action: actionSend)
                VerticalDivider()
                AccountActionButton(imageName: "button_slider_receive", disabled: disabled, action: actionReceive)
                VerticalDivider()
                AccountActionButton(imageName: "button_slider_earn", disabled: disabled, action: actionEarn)
                if isShielded {
                    VerticalDivider()
                    AccountActionButton(imageName: "button_slider_shield", disabled: disabled, action: actionShield)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: size)
            .background(Color.blackSecondary)
            .cornerRadius(24, corners: [.bottomLeft, .bottomRight])
        }
    }
}

extension View {
    public func botRoundedWithBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S : ShapeStyle {
        let rect = RoundedBottomShape(cornerRadius: cornerRadius)
        return clipShape(rect)
            .overlay(rect.stroke(content, lineWidth: width))
    }
}

struct RoundedBottomShape: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        
        path.move(to: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        path.addQuadCurve(to: CGPoint(x: maxX - cornerRadius, y: maxY), control: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
        path.addQuadCurve(to: CGPoint(x: minX, y: maxY - cornerRadius), control: CGPoint(x: minX, y: maxY))
        
        return path
    }
}

private struct AccountActionButton: View {
    let imageName: String
    var disabled: Bool = false
    var action: () -> Void
    
    var body: some View {
        ZStack {
            Image(imageName).renderingMode(.template).tint(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: size)
        .background(disabled ? Color.blackSecondary.opacity(0.7) : Color.blackSecondary)
        .onTapGesture {
            self.action()
        }.disabled(disabled)
    }
}

struct VerticalDivider: View {
    var body: some View {
        Divider()
            .frame(maxWidth: 1, maxHeight: size)
            .background(Pallette.whiteText.opacity(0.4))
    }
}

struct AccountActionButtons_Previews: PreviewProvider {
    static var previews: some View {
        AccountActionButtons(
            isShielded: true,
            actionSend: {
            }, actionReceive: {
            }, actionEarn: {
            }, actionShield: {
            }, actionSettings: {
            })
    }
}
