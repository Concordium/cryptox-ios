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

                Image(image)
                    .renderingMode(.template)

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
