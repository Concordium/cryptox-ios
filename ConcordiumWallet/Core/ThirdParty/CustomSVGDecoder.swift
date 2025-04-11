//
//  CustomSVGDecoder.swift
//  CryptoX
//
//  Created by Max on 05.06.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import Foundation
import SDWebImageSwiftUI
import SDWebImageSVGCoder

/// https://stackoverflow.com/questions/74427783/download-svg-image-in-ios-swift
class CustomSVGDecoder: NSObject, SDImageCoder {
    
    let fallbackDecoder: SDImageCoder?
    
    init(fallbackDecoder: SDImageCoder?) {
        self.fallbackDecoder =  fallbackDecoder
    }
    
    static var regex: NSRegularExpression = {
        let pattern = "<image.*xlink:href=\"data:image\\/(png|jpg);base64,(.*)\"\\/>"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        return regex
    }()
    
    func canDecode(from data: Data?) -> Bool {
        guard let data = data, let string = String(data: data, encoding: .utf8) else { return false }
        guard Self.regex.firstMatch(in: string, range: NSRange(location: 0, length: string.utf16.count)) == nil else {
            return true //It self should decode
        }
        guard let fallbackDecoder = fallbackDecoder else {
            return false
        }
        return fallbackDecoder.canDecode(from: data)
    }
    
    func decodedImage(with data: Data?, options: [SDImageCoderOption : Any]? = nil) -> UIImage? {
        guard let data = data,
              let string = String(data: data, encoding: .utf8) else { return nil }
        guard let match = Self.regex.firstMatch(in: string, range: NSRange(location: 0, length: string.utf16.count)) else {
            return fallbackDecoder?.decodedImage(with: data, options: options)
        }
        guard let rawBase64DataRange = Range(match.range(at: 2), in: string) else {
            return fallbackDecoder?.decodedImage(with: data, options: options)
        }
        let rawBase64Data = String(string[rawBase64DataRange])
        guard let imageData = Data(base64Encoded: Data(rawBase64Data.utf8), options: .ignoreUnknownCharacters) else {
            return fallbackDecoder?.decodedImage(with: data, options: options)
        }
        return UIImage(data: imageData)
    }
    
    func canEncode(to format: SDImageFormat) -> Bool {
        return true
    }
    
    func encodedData(with image: UIImage?, format: SDImageFormat, options: [SDImageCoderOption : Any]? = nil) -> Data? {
        return nil
    }
}
