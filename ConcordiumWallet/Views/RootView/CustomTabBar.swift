import SwiftUI

struct CustomTabBar: View {
    
    @EnvironmentObject var router: AppRouter

    var body: some View {

        HStack {

            tabItem(.accounts, "home_icon", "Home")
            tabItem(.transfer, "transfer_icon", "Transfer")
            tabItem(.buy, "buy_icon", "Buy")
            tabItem(.stake, "stake_icon", "Stake")
            tabItem(.activity, "activity_icon", "Activity")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.black)
    }

    private func tabItem(
        _ tab: AppRouter.Tab,
        _ image: String,
        _ title: String
    ) -> some View {

        let isSelected = router.selectedTab == tab

        return Button {
            router.selectedTab = tab
        } label: {

            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(
                                EllipticalGradient(
                                    stops: [
                                        .init(color: Color(red: 0.62, green: 0.95, blue: 0.92), location: 0),
                                        .init(color: Color(red: 0.93, green: 0.85, blue: 0.75), location: 1),
                                        .init(color: Color(red: 0.64, green: 0.6, blue: 0.89), location: 1.5)
                                    ],
                                    center: UnitPoint(x: 0, y: 0)
                                )
                            )
                            .opacity(0.16)
                            .frame(width: 52, height: 36)
                    }

                    Image(image)
                        .renderingMode(.template)
                        .padding(8)
                        .if(isSelected) { view in
                            view
                                .modifier(ToolbarGradientStyleModifier())
                        }
                        .foregroundStyle(
                            isSelected
                            ? .clear
                            : Color.semanticContentSecondary
                        )
                }

                Text(title)
                    .font(.satoshi(size: 12, weight: .regular))
            }
            .if(isSelected) { view in
                view
                    .modifier(ToolbarGradientStyleModifier())
            }
            .foregroundStyle(
                isSelected
                ? .clear
                : Color.semanticContentSecondary
            )
        }
        .frame(maxWidth: .infinity)
    }
}
