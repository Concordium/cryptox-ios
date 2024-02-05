//
//  GrayRoundedBackgroundModifier.swift
//  StagingNet
//
//  Created by Maksym Rachytskyy on 04.08.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct GrayRoundedBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(24)
    }
}
