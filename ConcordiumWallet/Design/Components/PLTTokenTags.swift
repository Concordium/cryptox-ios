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
    case paused = "Token paused"
    case undefined
}

struct PLTTokenTags: View {
    @ObservedObject var viewModel: PLTTokenTagViewModel
    let pltTag = "Protocol Level Token"
    var onInfoTapped: (_ title: String, _ desc: String) -> Void

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

final class PLTTokenTagViewModel: ObservableObject {
    let allowList: Bool?
    let denyList: Bool?
    let paused: Bool?

    var pltState: PLTTokenState {
        if let paused, paused { return .paused }
        if let denyList, denyList { return .denyList}
        if let allowList, allowList { return .allowList }
        if let allowList, !allowList { return .notOnAllowList }
        return .undefined
    }
    
    init(allowList: Bool?, denyList: Bool?, paused: Bool?) {
        self.allowList = allowList
        self.denyList = denyList
        self.paused = paused
    }
    
    func getImageName(isPLTTag: Bool) -> String {
        guard !isPLTTag else {
            return "concordium_logo"
        }
        switch pltState {
        case .allowList:
            return "circled-check-done"
        case .notOnAllowList, .denyList, .paused:
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
        case .notOnAllowList, .paused:
            return (Color.Status.infoOrange, .warningTertiary, .warningSecondary)
        case .denyList:
            return (.errorPrimary, .errorTertiary, .errorSecondary)
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
                Text("Done")
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
