//
//  SeedPhraseInput.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 11.01.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI
import MnemonicSwift

struct SeedPhraseInput: View {
    @Binding var selectedWords: [String]
    @Binding var selectedIndex: Int
    let suggestions: [String]
    let editable: Bool
    let currentInput: Binding<String>
    let action: (String) -> Void
    
    @State private var isScrolling = false
    
    init(
        selectedWords: Binding<[String]>,
        selectedIndex: Binding<Int>,
        suggestions: [String],
        editable: Bool = false,
        currentInput: Binding<String> = .constant(""),
        action: @escaping (String) -> Void
    ) {
        self._selectedWords = selectedWords
        self._selectedIndex = selectedIndex
        self.suggestions = suggestions
        self.editable = editable
        self.currentInput = currentInput
        self.action = action
    }
    
    var body: some View {
        HStack(spacing: 18) {
            SeedPhraseInputList(
                items: $selectedWords,
                selectedIndex: $selectedIndex,
                currentInput: currentInput,
                editable: editable,
                action: action,
                moveToNextIndex: moveToNextIndex
            )
            
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


struct SeedPhraseInputList: View {
    private struct IndexedItem: Identifiable {
        let index: Int
        let value: String
        
        var id: Int { index }
    }
    
    @Binding var items: [String]
    @Binding var selectedIndex: Int
    @Binding var currentInput: String
    @State private var inputArray: [String] = []
    @State private var isPasted: Bool = false
    let editable: Bool
    let action: (String) -> Void
    let moveToNextIndex: () -> Void
    
    fileprivate static let cellHeight: CGFloat = 42
    @GestureState private var dragOffset: CGFloat = 0
    
    private var indexedItems: [IndexedItem] {
        items.enumerated().map { (index, value) in
            IndexedItem(index: index, value: value)
        }
    }
    
    private var topOffset: CGFloat {
        let halfContentOffset = SeedPhraseInputList.cellHeight * CGFloat(indexedItems.count) / 2 + SeedPhraseInputList.cellHeight / 2
        let scrollOffset = (SeedPhraseInputList.cellHeight + CGFloat(selectedIndex) * SeedPhraseInputList.cellHeight)
        
        return halfContentOffset - scrollOffset + dragOffset
    }
    
    private var calculatedIndex: Int {
        let inversedOffset = dragOffset * -1
        let offsetIndex = Int(inversedOffset / SeedPhraseInputList.cellHeight)
        
        return offsetIndex + selectedIndex
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(indexedItems) { item in
                SeedPhraseInputListCell(
                    index: item.index,
                    label: item.value,
                    location: .from(index: item.index, itemCount: items.count),
                    isSelected: calculatedIndex == item.index,
                    showSeparator: showSeparator(forCellAt: item.index),
                    editable: editable,
                    input: $currentInput
                )
                .onTapGesture {
                    selectedIndex = item.index
                }
                .onChange(of: $currentInput.wrappedValue) { newValue in
                    if UIPasteboard.general.string == newValue {
                        isPasted = true
                        do {
                            try handleInputChange(for: selectedIndex, newValue: newValue)
                        } catch(let error) {
                            print("Error handling input change: \(error.localizedDescription)")
                        }
                    } else {
                        isPasted = false
                    }
                }
            }
            .offset(y: topOffset)
            .animation(.easeInOut, value: topOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        var index = value.translation.height * -1 / SeedPhraseInputList.cellHeight
                        index = value.translation.height < 0 ? ceil(index) : floor(index)
                        
                        selectedIndex = max(
                            0,
                            min(
                                items.count - 1,
                                selectedIndex + Int(index)
                            )
                        )
                    }
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(height: SeedPhraseInputList.cellHeight * 5 + 4*4)
        .clipped()
        .contentShape(Rectangle())
    }
    
    private func handleInputChange(for index: Int, newValue: String) throws {
        if isPasted {
            inputArray = newValue.components(separatedBy: " ")
            if inputArray.count == 24 {
                try Mnemonic.validate(mnemonic: newValue)
                items = inputArray
                currentInput = items[selectedIndex]
                action(currentInput)
            }
        } else {
            // Handle manual input
            items[index] = newValue
            action(newValue)
        }
    }
    
    private func showSeparator(forCellAt index: Int) -> Bool {
        return isNotSelectedOrEmpty(at: index) && isNotSelectedOrEmpty(at: index + 1)
    }
    
    private func isNotSelectedOrEmpty(at index: Int) -> Bool {
        let isNotSelected = index != calculatedIndex
        let isNotEmpty = index < items.count && !items[index].isEmpty
        
        return isNotSelected && isNotEmpty
    }
}

private struct SeedPhraseInputListCell: View {
    enum Location {
        case top, middle, bottom
        
        static func from(index: Int, itemCount: Int) -> Location {
            if index == 0 {
                return .top
            } else if index < itemCount - 1 {
                return .middle
            } else {
                return .bottom
            }
        }
    }
    
    let index: Int
    let label: String
    let location: Location
    let isSelected: Bool
    let showSeparator: Bool
    let editable: Bool
    
    @Binding var input: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1).")
                .font(Font.plexMono(size: 12, weight: .regular))
                .foregroundColor(Color.MineralBlue.tint2)
            if isSelected && editable {
                AutoFocusTextField(text: $input)
                    .frame(alignment: .leading)
                    .onAppear { input = label }
            } else {
                Text(label)
                    .font(Font.satoshi(size: 15, weight: .medium))
                    .foregroundColor(.greySecondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: SeedPhraseInputList.cellHeight)
        .background(backgroundColor.overlay(RoundedRectangle(cornerRadius: 8).inset(by: 0.5).stroke(strokeBorderColor, lineWidth: 1)))
        .frame(height: SeedPhraseInputList.cellHeight)
        .cornerRadius(8)
        .zIndex(isSelected ? 1 : 0)
    }
    
    private var backgroundColor: Color {
        if label.isEmpty || (isSelected && editable) {
            return Color.Neutral.tint5
        } else {
            return Color.Neutral.tint5
        }
    }
    
    private var strokeBorderColor: Color {
        if isSelected { return Color(red: 0.48, green: 0.55, blue: 0.55) }
        
        if label.isEmpty {
            return Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05)
        } else {
            return Color(red: 0.92, green: 0.94, blue: 0.94).opacity(0.05)
        }
    }
}
