import SwiftUI

struct VerifiablePresentationV1RequestParamsView: View {
    @StateObject var viewModel: VerifiablePresentationV1RequestModel

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                ForEach(viewModel.getGroupedStatements().sorted(by: { $0.key < $1.key }), id: \.key) { group, items in
                    StatementCardView(title: group, items: items)
                }
            }
            .frame(maxHeight: 150)
        }
    }
}

