//
//  NavigationManager.swift
//  CryptoX
//
//  Created by Zhanna Komar on 29.01.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

class NavigationManager: ObservableObject {
    @Published var path: [NavigationPaths] = []
    
    func navigate(to destination: NavigationPaths) {
        if !path.contains(destination) {
            path.append(destination)
        }
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func reset() {
        path.removeAll()
    }
}
