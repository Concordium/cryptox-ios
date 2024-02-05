//
//  Image+Ext.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 04.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import UIKit
import SwiftUI

extension Image {
    init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        guard let uiImage = UIImage(data: data) else { return nil }
        self = Image(uiImage: uiImage)
    }
}
