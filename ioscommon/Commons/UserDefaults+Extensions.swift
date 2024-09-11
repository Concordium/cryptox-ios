//
//  UserDefaults+Extensions.swift
//  CryptoX
//
//  Created by Zhanna Komar on 10.09.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import Combine

extension UserDefaults {
    func publisher(for key: String) -> AnyPublisher<Any?, Never> {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .map { _ in
                return self.object(forKey: key)
            }
            .eraseToAnyPublisher()
    }
}
