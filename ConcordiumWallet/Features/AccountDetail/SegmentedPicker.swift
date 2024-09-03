//
//  SegmentedPicker.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 30.05.2023.
//  Copyright © 2023 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
struct BackgroundGeometryReader: View {
    var body: some View {
        GeometryReader { geometry in
            return Color
                    .clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
        }
    }
}
struct SizeAwareViewModifier: ViewModifier {

    @Binding private var viewSize: CGSize

    init(viewSize: Binding<CGSize>) {
        self._viewSize = viewSize
    }

    func body(content: Content) -> some View {
        content
            .background(BackgroundGeometryReader())
            .onPreferenceChange(SizePreferenceKey.self, perform: { if self.viewSize != $0 { self.viewSize = $0 }})
    }
}

struct SegmentedPicker<SelectionValue, Content>: View where SelectionValue : Hashable, Content : View {
    @State private var segmentSize: CGSize = .zero
    @Binding private var selection: SelectionValue
   
    private let items: [SelectionValue]
    private let content: (SelectionValue) -> Content
    
    private var activeSegmentView: AnyView {
        let isInitialized: Bool = segmentSize != .zero
        if !isInitialized { return EmptyView().eraseToAnyView() }
        return
            Rectangle()
            .foregroundColor(.white.opacity(0.5))
                .frame(width: self.segmentSize.width, height: 2)
                .offset(x: self.computeActiveSegmentHorizontalOffset(), y: 0)
                .animation(Animation.linear(duration: 0.2))
                .eraseToAnyView()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            VStack {
                Spacer()
                self.activeSegmentView
            }
            HStack {
                ForEach(self.items, id: \.self) { item in
                    Button {
                        self.selection = item
                    } label: {
                        self.content(item)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .modifier(SizeAwareViewModifier(viewSize: self.$segmentSize))
                    .opacity(self.selection == item ? 1.0 : 0.7);
                }
            }
        }
        .background(.clear)
        .frame(height: 54)
    }
    
    init(items: [SelectionValue], selection: Binding<SelectionValue>, _ content: @escaping (SelectionValue) -> Content) {
        self._selection = selection
        self.items = items
        self.content = content
    }

    private func computeActiveSegmentHorizontalOffset() -> CGFloat {
        let idx = items.firstIndex(of: self.selection) ?? 0
        return CGFloat(idx) * (self.segmentSize.width)
    }
}
