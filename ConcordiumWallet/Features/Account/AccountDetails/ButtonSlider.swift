//
//  ButtonSlider.swift
//  ConcordiumWallet
//
//  Created by Lars Christensen on 23/12/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

private let size: CGFloat = 60.0

struct ButtonSlider: View {
    var isShielded: Bool
    
    var actionSend: () -> Void
    var actionReceive: () -> Void
    var actionEarn: () -> Void
    var actionShield: () -> Void
    var actionSettings: () -> Void
    
    @State var disabled: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ActionButton(imageName: "button_slider_send", disabled: disabled, action: actionSend)
            VerticalLine()
            ActionButton(imageName: "button_slider_receive", disabled: disabled, action: actionReceive)
            VerticalLine()
            ActionButton(imageName: "button_slider_earn", disabled: disabled, action: actionEarn)
            if isShielded {
                VerticalLine()
                ActionButton(imageName: "button_slider_shield", disabled: disabled, action: actionShield)
//                VerticalLine()
//                ActionButton(imageName: "button_slider_settings", disabled: disabled, action: actionSettings)
            } else {
//                ActionButton(imageName: "button_slider_settings", disabled: disabled, action: actionSettings)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: size)
        .background(Color.blackSecondary)
        .cornerRadius(5)
    }
}

struct ActionButton: View {
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

struct VerticalLine: View {
    var body: some View {
        Divider()
            .frame(maxWidth: 1, maxHeight: size)
            .background(Pallette.whiteText.opacity(0.4))
    }
}

struct ButtonSlider_Previews: PreviewProvider {
    static var previews: some View {
        ButtonSlider(
            isShielded: true,
            actionSend: {
            }, actionReceive: {
            }, actionEarn: {
            }, actionShield: {
            }, actionSettings: {
            })
    }
}
