//
//  VerifiablePresentationRequestParamsView.swift
//  CryptoX
//
//  Created by Maksym Rachytskyy on 22.04.2024.
//  Copyright © 2024 pioneeringtechventures. All rights reserved.
//

import SwiftUI

struct VerifiablePresentationRequestParamsView: View {
    @StateObject var viewModel: VerifiablePresentationRequestModel
    
    var body: some View {
        VStack {
            if let error = viewModel.error {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.white, .red)
                        .imageScale(.large)
                    Text(error.description)
                }
            }
            
            List {
                 ForEach(viewModel.getStatementCellModels().indices, id: \.self) { index in
                     let model = viewModel.getStatementCellModels()[index]

                     Section(model.title) {
                         VStack(alignment: .leading, spacing: 12) {
                             HStack {
                                 Text(model.title)
                                     .fontWeight(.bold)
                                 Spacer()
                                 HStack(spacing: 8) {
                                     Text(model.value)
                                         .foregroundColor(.white)
                                     Image(systemName: model.isValid ? "checkmark" : "xmark")
                                         .foregroundStyle(model.isValid ? .green : .red)
                                 }
                             }

                             Text(model.description)
                                 .foregroundColor(Color.white.opacity(0.7))
                                 .multilineTextAlignment(.leading)
                         }
                         .padding()
                         .background(Color.Neutral.tint5)
                         .cornerRadius(14)
                     }
                     .listRowSeparator(.hidden)
                     .listRowBackground(Color.clear)
                 }
             }
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listStyle(.plain)
            .listRowBackground(Color.clear)
        }
        .cornerRadius(14, corners: .allCorners)
    }
}

