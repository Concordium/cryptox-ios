import SwiftUI

struct VerificationSuccessfulView: View {
    let siteName: String
    let type: String
    @SwiftUI.Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            card
                .padding(.bottom, 40)
        }
        .ignoresSafeArea()
    }

    private var card: some View {
        VStack(spacing: 0) {
            Image("circled-check-done")
                .resizable()
                .frame(width: 40, height: 40)
                .padding(.bottom, 24)

            Text("\(type) Successful")
                .font(.satoshi(size: 20, weight: .medium))
                .foregroundStyle(.whiteMain)
                .padding(.bottom, 8)

            if !siteName.isEmpty {
                Text("You can return to \(siteName)")
                    .font(.satoshi(size: 14, weight: .regular))
                    .foregroundStyle(Color.MineralBlue.blueish2)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(AllowButtonStyle(disabled: false))
            .padding(.top, 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(.surfaceTertiary)
        .cornerRadius(34)
        .frame(maxWidth: .infinity)
    }
}
