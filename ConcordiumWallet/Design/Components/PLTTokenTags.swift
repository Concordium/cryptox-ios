//
//  PLTTokenTags.swift
//  CryptoX
//
//  Created by Zhanna Komar on 21.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum PLTTokenState: String {
    case allowList = "Account is on the allow list"
    case notOnAllowList = "Account not on the allow list"
    case denyList = "Account on the deny list"
    case undefined
}

struct PLTTokenTags: View {
    @ObservedObject var viewModel: PLTTokenTagViewModel
    let pltTag = "Protocol Level Token"

    var body: some View {
        HStack(spacing: 8) {
            tagView(isPLTTag: true)
            tagView(isPLTTag: false)
        }
    }
    
    @ViewBuilder
    func tagView(isPLTTag: Bool) -> some View {
        let colors = viewModel.getColors(isPLTTag: isPLTTag)
        HStack(alignment: .center, spacing: 4) {
            Image(viewModel.getImageName(isPLTTag: isPLTTag))
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(colors.foreground)
                .frame(width: 12, height: 12)
            Text(isPLTTag ? pltTag : viewModel.pltState.rawValue)
                .font(.satoshi(size: 11, weight: .medium))
                .foregroundStyle(colors.foreground)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6 )
        .background(colors.background)
        .cornerRadius(9999)
        .overlay(
          RoundedRectangle(cornerRadius: 9999)
            .inset(by: 0.5)
            .stroke(colors.border, lineWidth: 1)
        )
    }
}

final class PLTTokenTagViewModel: ObservableObject {
    let allowList: Bool?
    let denyList: Bool?

    var pltState: PLTTokenState {
        if let denyList, denyList { return .denyList}
        if let allowList, allowList { return .allowList }
        if let allowList, !allowList { return .notOnAllowList }
        return .undefined
    }
    
    init(allowList: Bool?, denyList: Bool?) {
        self.allowList = allowList
        self.denyList = denyList
    }
    
    func getImageName(isPLTTag: Bool) -> String {
        guard !isPLTTag else {
            return "concordium_logo"
        }
        switch pltState {
        case .allowList:
            return "circled-check-done"
        case .notOnAllowList, .denyList:
            return "circled-x-block-deny"
        default:
            return ""
        }
    }
    
    func getColors(isPLTTag: Bool) -> (foreground: Color, background: Color, border: Color) {
        guard !isPLTTag else {
            return (.accentPrimary, .surfaceTertiary, .accentPrimary)
        }
        switch pltState {
        case .allowList:
            return (.successGreen, .successTertiary, .successSecondary)
        case .notOnAllowList:
            return (Color.Status.infoOrange, .warningTertiary, .warningSecondary)
        case .denyList:
            return (.errorPrimary, .errorTertiary, .errorSecondary)
        default:
            return (.clear, .clear, .clear)
        }
    }

}
