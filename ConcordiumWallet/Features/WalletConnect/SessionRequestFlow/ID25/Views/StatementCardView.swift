import SwiftUI

struct VerifiableStatementListCellModel: Hashable {
    let title: String
    let value: String
    let description: String
    let isValid: Bool
}

struct StatementCardView: View {
    let title: String
    let items: [VerifiableStatementListCellModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .foregroundColor(.greyMain)
                .font(.satoshi(size: 14, weight: .medium))

            VStack(spacing: 12) {
                ForEach(items, id: \.self) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            HStack(spacing: 6) {
                                Text(item.value)
                                    .foregroundColor(.white)
                                Image(systemName: item.isValid ? "checkmark" : "xmark")
                                    .foregroundStyle(item.isValid ? .green : .red)
                            }
                        }

                        Text(item.description)
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.Neutral.tint5)
                    .cornerRadius(14)
                }
            }

            if title == "Revealed Attributes" {
                Text("Note that all the information above will be revealed to the connected service.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
    }
}
