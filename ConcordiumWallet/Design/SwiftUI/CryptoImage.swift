//
//  CryptoImage.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 30.08.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImageSVGCoder

struct CryptoImage: View {
    enum Size {
        case small
        case medium
        case custom(width: CGFloat, height: CGFloat)
        
        var size: CGSize {
            switch self {
                case .small: return .init(width: 20, height: 20)
                case .medium: return .init(width: 40, height: 40)
                case let .custom(width, height): return .init(width: width, height: height)
            }
        }
    }
    
    let url: URL?
    let size: CryptoImage.Size
    
    
    var body: some View {
        if let url = url, url.absoluteString.contains(".svg") {
            WebImage(
                url: url,
                context: [.imageCoder: CustomSVGDecoder(fallbackDecoder: SDImageSVGCoder.shared)]
            )
            .resizable()
            .indicator(.activity)
            .transition(.fade(duration: 0.5))
            .aspectRatio(contentMode: .fit)
            .frame(width: size.size.width, height: size.size.height)
        } else {
            AsyncImage(url: url, scale: 1.0) { image in
                image
                    .resizable()
                    .clipShape(Circle())
            } placeholder: {
                Color.gray.opacity(0.4).clipShape(Circle())
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: size.size.width, height: size.size.height)
        }
    }
}
