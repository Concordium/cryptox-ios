//
//  CustomToggle.swift
//  CryptoX
//
//  Created by Zhanna Komar on 17.02.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct CustomToggle: View {
    @Binding var isOn: Bool
    
    var selectedColor: Color = .greenSecondary
    var unselectedColor: Color = .grey3
    var thumbTint: Color = .white
    
    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(isOn ? selectedColor : unselectedColor)
                .frame(width: 50, height: 30)
            
            Circle()
                .fill(thumbTint)
                .frame(width: 26, height: 26)
                .padding(2)
                .shadow(radius: 3)
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        }
    }
}

#Preview {
    CustomToggle(isOn: .constant(false))
}
