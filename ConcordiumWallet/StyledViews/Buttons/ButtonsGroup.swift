//
//  ButtonsGroup.swift
//  CryptoX
//
//  Created by Zhanna Komar on 03.03.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct ButtonsGroup: View {
    
    private let actionItems: [ActionItem]
    @State private var selectedActionId: Int?

    init(actionItems: [ActionItem]) {
        self.actionItems = actionItems
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(actionItems.enumerated()), id: \.offset) { (index, item) in
                VStack {
                    Image(item.iconName)
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .padding(11)
                        .background(selectedActionId == index ? .grey4 : .grey3)
                        .foregroundColor(.MineralBlue.blueish3)
                        .cornerRadius(50)
                    Text(item.label)
                        .font(.satoshi(size: 12, weight: .medium))
                        .foregroundColor(.MineralBlue.blueish2)
                        .padding(.top, 2)
                }
                .onTapGesture {
                    selectedActionId = index
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        selectedActionId = nil
                        item.action()
                    }
                }
            }
            Spacer()
        }
    }
}
