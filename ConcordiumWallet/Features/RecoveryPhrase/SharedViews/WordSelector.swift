//
//  WordSelector.swift
//  ConcordiumWallet
//
//  Created by Niels Christian Friis Jakobsen on 28/07/2022.
//  Copyright © 2022 concordium. All rights reserved.
//

import SwiftUI

struct WordSelection: View {
    let selectedWords: [String]
    @Binding var selectedIndex: Int
    let suggestions: [String]
    let editable: Bool
    let currentInput: Binding<String>
    let action: (String) -> Void
    
    @State private var isScrolling = false
    
    init(
        selectedWords: [String],
        selectedIndex: Binding<Int>,
        suggestions: [String],
        editable: Bool = false,
        currentInput: Binding<String> = .constant(""),
        action: @escaping (String) -> Void
    ) {
        self.selectedWords = selectedWords
        self._selectedIndex = selectedIndex
        self.suggestions = suggestions
        self.editable = editable
        self.currentInput = currentInput
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 0) {
            PageList(
                items: selectedWords,
                selectedIndex: $selectedIndex,
                editable: editable,
                currentInput: currentInput
            )
            
            if suggestions.count > 0 {
                Image("select_arrow_\(suggestions.count)")
                    .animation(.easeInOut(duration: 0.2), value: suggestions)
                    .frame(width: 42)
            } else {
                Spacer().frame(width: 42)
            }
            
            SuggestionBox(
                suggestions: suggestions,
                selectedSuggestion: selectedWords[selectedIndex]
            ) { suggestion in
                action(suggestion)
                moveToNextIndex()
            }
            .opacity(isScrolling ? 0 : 1)
        }
    }
    
    private func moveToNextIndex() {
        for index in selectedIndex+1..<selectedWords.count {
            if selectedWords[index].isEmpty {
                selectedIndex = index
                return
            }
        }
        for index in 0..<selectedIndex {
            if selectedWords[index].isEmpty {
                selectedIndex = index
                return
            }
        }
        
        if selectedIndex < 23 {
            selectedIndex += 1
        }
        else {
            selectedIndex = 0
        }
    }
}
