//
//  PLTTokenTags.swift
//  CryptoX
//
//  Created by Zhanna Komar on 21.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//

import SwiftUI

enum TokenTagsDesc: String {
    case allowList = "Account is on the allow list"
    case notOnAllowList = "Account not on the allow list"
    case denyList = "Account on the deny list"
    case paused = "Token paused"
    case undefined
    case cis2Token = "CIS-2 Token"
}

struct TokenTags: View {
    @ObservedObject var viewModel: TokenTagViewModel
    let cis2Tag: Bool
    let pltTag = "Protocol Level Token"
    var onInfoTapped: (_ title: String, _ desc: String) -> Void

    var body: some View {
        Flow(spacing: 8) {
            if !cis2Tag {
                tagView(isPLTTag: true).fixedSize(horizontal: true, vertical: true)
            }
            tagView(isPLTTag: false).fixedSize(horizontal: true, vertical: true)
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)
            Image("circled-question-mark")
                .resizable()
                .foregroundStyle(colors.foreground)
                .frame(width: 12, height: 13)
                .onTapGesture {
                    if let (title, desc) = viewModel.getPopupDescriptionText(isPLTTag: isPLTTag) {
                        onInfoTapped(title, desc)
                    }
                }
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

final class TokenTagViewModel: ObservableObject {
    let allowList: Bool?
    let denyList: Bool?
    let paused: Bool?
    let cis2Token: Bool?

    var pltState: TokenTagsDesc {
        if let cis2Token, cis2Token { return .cis2Token }
        if let paused, paused { return .paused }
        if let denyList, denyList { return .denyList }
        if let allowList, allowList { return .allowList }
        if let allowList, !allowList { return .notOnAllowList }
        return .undefined
    }
    
    init(allowList: Bool?, denyList: Bool?, paused: Bool?, cis2Token: Bool?) {
        self.allowList = allowList
        self.denyList = denyList
        self.paused = paused
        self.cis2Token = cis2Token
    }
    
    func getImageName(isPLTTag: Bool) -> String {
        guard !isPLTTag else {
            return "shield-square-crypto"
        }
        switch pltState {
        case .allowList:
            return "circled-check-done"
        case .notOnAllowList, .denyList, .paused:
            return "circled-x-block-deny"
        case .cis2Token:
            return "coin-crypto-cis-2"
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
        case .notOnAllowList, .paused:
            return (Color.Status.infoOrange, .warningTertiary, .warningSecondary)
        case .denyList:
            return (.errorPrimary, .errorTertiary, .errorSecondary)
        case .cis2Token:
            return (Color.semanticContentSecondary, .clear, Color.semanticBorderTertiary)
        default:
            return (.clear, .clear, .clear)
        }
    }
    
    func getPopupDescriptionText(isPLTTag: Bool) -> (title: String, desc: String)? {
        guard !isPLTTag else {
            return ("plt.title".localized, "plt.description".localized)
        }
        switch pltState {
        case .allowList, .denyList:
            return ("allow.deny.list.title".localized, "allow.deny.list.description".localized)
        case .paused:
            return ("paused.token.title".localized, "paused.token.description".localized)
        case .cis2Token:
            return ("cis2.title".localized, "cis2.description".localized)
        case .undefined, .notOnAllowList:
           return nil
        }
    }

}

struct TagPopup: Identifiable {
    let id = UUID()
    let title: String
    let desc: String
}

struct TagsDescPopup: View {
    @Binding var isVisible: Bool
    let title: String
    let desc: String
    
    var body: some View {
        PopupContainer(icon: "",
                       title: title,
                       subtitle: desc,
                       content: doneButton()) {
            isVisible = false
        }
    }
    
    private func doneButton() -> some View {
        VStack {
            Button {
                DispatchQueue.main.async {
                    isVisible = false
                }
            } label: {
                Text("done".localized)
                    .font(.satoshi(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .cornerRadius(21)
            }
        }
    }
}

struct Flow: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            rowH = max(rowH, s.height)
            x += s.width + spacing
        }
        return CGSize(width: maxW, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}
