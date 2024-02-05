//
//  SuggestionBox.swift
//  Mock
//
//  Created by Niels Christian Friis Jakobsen on 28/07/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct SuggestionBox: View {
    let suggestions: [String]
    let selectedSuggestion: String?
    let minHeight: CGFloat
    let visibleSuggestions: Int
    let onSuggestionTapped: (String) -> Void
    
    init(
        suggestions: [String],
        selectedSuggestion: String?,
        minHeight: CGFloat = 44,
        visibleSuggestions: Int = 4,
        onSuggestionTapped: @escaping (String) -> Void
    ) {
        self.suggestions = suggestions
        self.selectedSuggestion = selectedSuggestion
        self.minHeight = minHeight
        self.visibleSuggestions = visibleSuggestions
        self.onSuggestionTapped = onSuggestionTapped
    }
    
    private var indexedSuggestions: [Indexed<String>] {
        suggestions.prefix(visibleSuggestions).indexed()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(indexedSuggestions, id: \.id) { suggestion in
                let isSelected = suggestion.value == selectedSuggestion
                Text(suggestion.value)
                    .foregroundColor(isSelected ? Pallette.greySecondary : Pallette.greySecondary.opacity(0.7))
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: minHeight)
                    .overlay(Capsule().stroke(Color(red: 0.66, green: 0.68, blue: 0.73).opacity(0.2), lineWidth: 1))
                    .opacity(suggestion.value.isEmpty ? 0 : 1)
                    .contentShape(Rectangle())
                    .onTapGesture { onSuggestionTapped(suggestion.value) }
            }
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }
}

struct SuggestionBox_Previews: PreviewProvider {
    static var previews: some View {
        SuggestionBox(
            suggestions: ["First", "Second", "Third"],
            selectedSuggestion: nil
        ) { _ in }
        
        SuggestionBox(
            suggestions: ["First", "Second", "Third"],
            selectedSuggestion: "Second"
        ) { _ in }
    }
}
