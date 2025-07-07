//
//  VerifiableProofView.swift
//  CryptoX
//
//  Created by Max on 07.07.2025.
//  Copyright © 2025 pioneeringtechventures. All rights reserved.
//


import SwiftUI

struct VerifiableProofView: View {
    @ObservedObject var model: VerifiablePresentationRequestModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(model.getGroupedStatements().keys.sorted()), id: \.self) { group in
                    if let items = model.getGroupedStatements()[group] {
                        StatementCardView(title: group, items: items)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(model.title)
    }
}